//
//  TMBSync.m
//  
//
//  Created by Ian Fox on 10/16/14.
//
//

#import "TMBSync.h"
#import "TMBCoreDataController.h"
#import <TMTumblrSDK/TMAPIClient.h>


typedef void(^completed) (BOOL);

@interface TMBSync() {
    BOOL *shouldSave;
}
@property (nonatomic, strong) NSMutableArray *classesToSync;
@end
@implementation TMBSync
@synthesize classesToSync = _classesToSync;
@synthesize syncInProgress = _syncInProgress;

-(NSMutableArray *) classesToSync
{
    
    if (!_classesToSync) {
        _classesToSync = [[NSMutableArray alloc] init];
    }
    
    return _classesToSync;
}
-(void) setClassesToSync:(NSMutableArray *) classesToSync
{
    
    _classesToSync = classesToSync;
}

+(TMBSync *) sharedInstance
{
    static TMBSync *_sync = nil;
    static dispatch_once_t initToken;
    dispatch_once(&initToken, ^(void) {
        _sync = [[TMBSync alloc] init];
    });
    return _sync;
}

/** creates or updates managed objects for any classes that we intend to sync to CoreData. This is done in a background thread.
 */
-(void) generateCoreDataFromJSONDiskData
{

    for (NSString *className in _classesToSync)
    {
        if (![self didCompleteInitialSync])
        {
           // case : no coreData. We need to add all JSON first because we havent yet
            NSDictionary *dictionary = [self JSONDictionaryForClassWithName:className];
            NSArray *posts = [dictionary objectForKey:kJSONResultKey];
            for (NSDictionary *post in posts) {
                [self newManagedObjectWithClassName: className withData:post];
            }

            
        } else {
            
            NSArray *diskData = [self JSONDataForClassWithName:className sortedByKey:kObjectID];
            if ([diskData count] > 25) {
                shouldSave = FALSE;
            } else {
                shouldSave = TRUE;
            }
            if ([diskData firstObject])
            {
                NSArray *keys = [diskData valueForKey:kObjectID];
                
                NSMutableArray *coreData = [[NSMutableArray alloc] initWithArray:[self managedObjectsForClass:@"Post" sortByKey:kObjectID inArray:YES objectArray:keys]];
                
                    [diskData enumerateObjectsUsingBlock:^(NSDictionary* data, NSUInteger idx, BOOL *stop) {
                        if (idx >= [coreData count])
                        {
                            
                            [coreData insertObject:[self newManagedObjectWithClassName:className withData:data] atIndex:idx];
                        } else
                        {
                            NSManagedObject *model = [coreData objectAtIndex:idx];
                            NSArray *coreKeys = [coreData valueForKey:kObjectID];
                            
                            if ([[model valueForKey:kObjectID] isEqualToNumber:[data objectForKey:kObjectID]])
                            {
                               
                                [self updateManagedObject:[coreData objectAtIndex:idx] withData:data updateHTML:YES];
                                
                                
                            } else if (![coreKeys containsObject:[data objectForKey:kObjectID]]){
                                [coreData insertObject:[self newManagedObjectWithClassName:className withData:data] atIndex:idx]
                                ;
                            }
                        }
                    }];
            }
        }
        NSManagedObjectContext *managedObjectContext = [[TMBCoreDataController sharedController] backgroundManagedObjectContext];
        [managedObjectContext performBlockAndWait:^(void)
        {
          NSError *error = nil;
          if (![managedObjectContext save:&error])
          {
              NSLog(@"error: %@", error);
          }
        }];

        [self deleteJSONDataForClassWithName:className];
    }

    [self executeSyncCompletedOperations];

    


}
/** query tumblr api. If not @param requestMostRecent , we get all posts */
-(void) downloadDataForClassesToSync: (BOOL) requestMostRecent withOffSet:(int) offset andLimit:(int) limit onCompletion:(void (^)(void))completionBlock
{
    
    for (NSString *className in _classesToSync)
    {
        int64_t mostRecent = 0;
        if (requestMostRecent) {
            
            mostRecent = [self mostRecentSyncForEntityWithName:className];
        }
        NSLog(@"%lldl", mostRecent);
        //@{ @"since_id" : [NSNumber numberWithLongLong:0] }
        [[TMAPIClient sharedInstance] dashboard:@{ @"limit" : [NSNumber numberWithInt:limit],
                                                   @"offset" : [NSNumber numberWithInt:offset]
                                                   } callback:^(id result, NSError *error) {
                                                       
                                                       if (!error) {
                                                           if ([result isKindOfClass:[NSDictionary class]]) {
                                                               
                                                               //write JSON to disk
                                                               BOOL success = [self writeJSONResponse:result toDiskForClassWithName:className];
                                                               if (success) {
                                                                   completionBlock();
                                                               }
                                                               
                                                           }
                                                       } else {
                                                           NSLog(@"Failed dashboard request to tumblr, with error : %@", error);
                                                       }
                                                       
                                                   }];
        
        
    }
    
    
}
/** initial Sync */
- (void)beginSync {
    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self downloadDataForClassesToSync:YES withOffSet:0 andLimit:10 onCompletion:^(void) {
                [self generateCoreDataFromJSONDiskData];
            }];
        });
    }
}
/** get new posts from Tumblr */
-(void) refreshSync
{
    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self downloadDataForClassesToSync:YES withOffSet:0 andLimit:10 onCompletion:^(void) {
                [self generateCoreDataFromJSONDiskData];
            }];
        });
    }
}
/** get posts from earlier on */
-(void) syncWithOffset:(NSNumber *)offset
{

    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      
            [self downloadDataForClassesToSync:YES withOffSet:offset.intValue andLimit:10 onCompletion:^(void) {
                [self generateCoreDataFromJSONDiskData];
            }];
        });
        
    }
}
/** this method indicates if we have initially synce and thus have any ManagedObjects in CoreData. */
- (BOOL) didCompleteInitialSync
{
    
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kInitialSyncCompleted] boolValue];
}
-(void) setInitialSyncAsCompleted
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kInitialSyncCompleted];
}
/* Pretty important. We need to notify the UI that a sync has been completed. To do so we access the main thread and post a notification. We also change syncInProgress to false */ 
- (void)executeSyncCompletedOperations {
    [[TMBCoreDataController sharedController] performSelectorInBackground:@selector(saveBackgroundContext) withObject:nil];
    [[TMBCoreDataController sharedController] performSelectorInBackground:@selector(saveParentContext) withObject:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setInitialSyncAsCompleted];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kSyncCompletedNotificationID
         object:nil];
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = NO;
        [self didChangeValueForKey:@"syncInProgress"];
    });

}

/** adds all the classes we need to sync. In this case we are only syncing Posts and dynamically allocating tags objects. I initially thought I would differeniate posts and needed more classes to sync */
-(void) addNewClassToSync: (Class) classOfModel
{
   
    if ([classOfModel isSubclassOfClass:[NSManagedObject class]])
    {
        if (![_classesToSync containsObject:NSStringFromClass(classOfModel)]) {
            [[self classesToSync] addObject:NSStringFromClass(classOfModel)];
        }
    }
}


-(long long) mostRecentSyncForEntityWithName: (NSString *) entityName {
    //latest Sync needs to editable within block
    __block long long latestSync = 0;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
//    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:
//                                      [NSSortDescriptor sortDescriptorWithKey:@"lastSync" ascending:NO]]];
    //we are only looking for one item
    [fetchRequest setFetchLimit:1];
    TMBCoreDataController *dataController = [TMBCoreDataController sharedController];
    [[dataController backgroundManagedObjectContext] performBlockAndWait:^(void) {
        NSError *error = nil;
        NSArray *result = [[dataController backgroundManagedObjectContext] executeFetchRequest:fetchRequest error:&error];
        if ([result lastObject])
        {
            
            latestSync = [[[result lastObject] valueForKey:kObjectID] longValue];
        }
    }];
    return latestSync;
}
/** value is any attribute a post may have. this method handles setting the value to the managed Object */
-(void)setValue:(id)value forKey:(NSString *)key
                            forManagedObject:(NSManagedObject *) managedObject
                                updateHTML:(BOOL) updateHTML
                                downloadPhotos: (BOOL) initial
{
    
    if([value isKindOfClass:[NSArray class]])
    {
        if ([key isEqualToString:@"photos"] && [value lastObject] && initial)
        {
            //hacky JSON access because of depth of URL in question. Let's just pick one picture although theyre could be more
            NSArray *urls = [[value lastObject] objectForKey:@"alt_sizes"];
            NSString *urlString = [[urls firstObject] objectForKey: @"url"];
//            [managedObject setValue:urlString forKey:@"imageURL"];
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *dataResponse = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            [managedObject setValue:dataResponse forKey:key];
            
        } else if ([key isEqualToString:@"tags"] && [value lastObject] && initial)
        {
             NSArray *tags = (NSArray *) value;
            NSMutableSet *set = [managedObject mutableSetValueForKey:@"myTags"];
            for (NSString *tag in tags)
            {
                NSManagedObject *model = [self newManagedObjectWithClassName: @"Tag"];
               
                [model setValue:tag forKey:@"tag"];
                [set addObject:model];
            }
        }
        
    } else {
        if ([key isEqualToString:@"id"])
        {
            [managedObject setValue:value forKey:key];
            
        } else if ([key isEqualToString:@"type"])
        {
            [managedObject setValue:value forKey:key];
        } else if ([key isEqualToString:@"likes"])
        {
            [managedObject setValue:value forKey:key];
        } else if ([key isEqualToString:@"note_count"])
        {
            [managedObject setValue:value forKey:key];
        } else if ([key isEqualToString:@"caption"] ||
                   [key isEqualToString:@"text"] ||
                   [key isEqualToString:@"body"] ||
                   [key isEqualToString:@"url"])
        {
            if ([key isEqualToString:@"url"])
            {
                value = [NSString stringWithFormat:@"<a href=%@/> %@ </a>",value, value];
            }
            if ([value length])
            {
                NSDictionary *options = @{NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType};
                NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithData:[value dataUsingEncoding:NSUnicodeStringEncoding] options:options documentAttributes:nil error:nil];
                [attrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:NSMakeRange(0, [attrString length])];
                [managedObject setValue: attrString forKey:@"caption"];
                
            } else {
                [managedObject setValue: nil forKey:key];
            }
  

        } else if ([key isEqualToString:@"blog_name"])
        {
            [managedObject setValue:value forKey:key];
        }
    }
}

/** fetches JSON from disk by Class */
-(NSDictionary *) JSONDictionaryForClassWithName:(NSString *) class
{
    NSURL *url = [NSURL URLWithString:class relativeToURL:[self JSONDataRecordsDirectory]];
    return [NSDictionary dictionaryWithContentsOfURL:url];
}

-(NSArray *) JSONDataForClassWithName:(NSString *) class sortedByKey: (NSString *) key
{
    NSDictionary *dictionary = [self JSONDictionaryForClassWithName:class];
    NSArray *data = [dictionary objectForKey:kJSONResultKey];
    return [data sortedArrayUsingDescriptors:[NSArray arrayWithObject:
                                              [NSSortDescriptor sortDescriptorWithKey:key ascending:YES]]];
}

/** clean up the disk after JSON is saved to file : @param class */
- (void)deleteJSONDataForClassWithName:(NSString *)class {
    NSURL *url = [NSURL URLWithString:class relativeToURL:[self JSONDataRecordsDirectory]];
    NSError *error = nil;
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    if (!deleted) {
        NSLog(@"Unable to delete JSON Records at %@, reason: %@", url, error);
    }
}


/** returns a query the disk by a set of since_id's. Use @param lookIn to specifiy if you want objects in or not @param array
 */
-(NSArray *) managedObjectsForClass:(NSString *) class sortByKey:(NSString *) key inArray:(BOOL) lookIn objectArray:(NSArray *) array
{
    NSManagedObjectContext *backgroundContext = [[TMBCoreDataController sharedController] backgroundManagedObjectContext];
    //Use NSPredicate to specify query
    NSPredicate *predicate;
    if (lookIn) {
        //we want to only retrieve models with since_id in the array
        predicate = [NSPredicate predicateWithFormat:@"id IN %@", array];

    } else {
        //the converse
        predicate = [NSPredicate predicateWithFormat:@"NOT (id IN %@)", array];
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:class];
    [request setPredicate:predicate];
    [request setSortDescriptors:[NSArray arrayWithObject:
                                      [NSSortDescriptor sortDescriptorWithKey:kObjectID ascending:YES]]];
    __block NSArray *managedObjects;
    [backgroundContext performBlockAndWait:^(void) {
        NSError *err = nil;
        managedObjects = [backgroundContext executeFetchRequest:request error: &err];
    }];
    
    return managedObjects;
}

/* create new ManagedObject of @param className with data - @param record */
-(NSManagedObject *)newManagedObjectWithClassName:(NSString *)className withData:(NSDictionary *)data {
    
    NSManagedObject *newManagedObject = [self newManagedObjectWithClassName:className];
    
    [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        [self setValue:obj forKey:key forManagedObject:newManagedObject updateHTML:YES downloadPhotos:YES];
    }];
    return newManagedObject;
}

-(NSManagedObject *)newManagedObjectWithClassName:(NSString *)className
{
    
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:[[TMBCoreDataController sharedController] backgroundManagedObjectContext]];
    return newManagedObject;
}

- (void)updateManagedObject:(NSManagedObject *)managedObject withData:(NSDictionary *) data updateHTML:(BOOL) update {
    [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key forManagedObject:managedObject updateHTML:update downloadPhotos:NO];
    }];
}




#pragma mark - File Management

- (NSURL *)applicationCacheDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}
/** get URL for where we save JSON from Tumblr .*/
- (NSURL *)JSONDataRecordsDirectory{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL URLWithString:@"JSONRecords/" relativeToURL:[self applicationCacheDirectory]];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:[url path]]) {
        [fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return url;
}
/** Tumblr api returns NSNulls. First we remove all these. then write to the file under the models class name.
 */
-(BOOL)writeJSONResponse:(id)response toDiskForClassWithName:(NSString *)className {
    
    NSURL *fileURL = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]];
    NSArray *records = [response objectForKey:kJSONResultKey];
    NSMutableArray *nonNullRecords = [NSMutableArray array];
    //remove anything null that the tumblr api is returning?
    for (NSDictionary *record in records) {
        NSMutableDictionary *nullFreeRecord = [NSMutableDictionary dictionaryWithDictionary:record];
        [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[NSNull class]]) {
                [nullFreeRecord setValue:nil forKey:key];
            }
        }];
        [nonNullRecords addObject:nullFreeRecord];
    }

    NSDictionary *nullFreeDictionary = [NSDictionary dictionaryWithObject:nonNullRecords forKey:kJSONResultKey];
    if (![nullFreeDictionary writeToFile:[fileURL path] atomically:YES]) {
        NSLog(@"Failed all attempts to save response to disk: %@", response);
        return NO;
    }
    return YES;
}
@end
