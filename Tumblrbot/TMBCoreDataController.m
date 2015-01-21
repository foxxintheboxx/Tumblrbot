//
//  TMBCoreDataController.m
//  Tumblrbot
//
//  Created by Ian Fox on 10/16/14.
//  Copyright (c) 2014 Matthew Bischoff. All rights reserved.
//

#import "TMBCoreDataController.h"
#import <TMTumblrSDK/TMAPIClient.h>
#import "TMBSync.h"
#import "Tag.h"
#import "Post.h"
@interface TMBCoreDataController()
@property (strong, nonatomic) NSManagedObjectContext *backgroundManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext *parentManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
@implementation TMBCoreDataController

@synthesize parentManagedObjectContext = _parentManagedObjectContext;
@synthesize backgroundManagedObjectContext = _backgroundManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+(TMBCoreDataController *) sharedController
{
    static TMBCoreDataController *controller;
    static dispatch_once_t initToken;
    dispatch_once(&initToken, ^(void) {
        controller = [[TMBCoreDataController alloc] init];
    });
    return controller;
}
#pragma mark - Core Data stack

/** The parent Context saves to the Persistent store. It's children are the background context and the main context. I designed it this way because I thought it may help prevent the UI from blocking queries since most of the saving will be done on a none UI thread. It didn't work that well :( */
-(NSManagedObjectContext *) parentManagedObjectContext
{
    if (_parentManagedObjectContext)
    {
        return _parentManagedObjectContext;
    }
    NSPersistentStoreCoordinator *storeCoordinator = [self persistentStoreCoordinator];
    if (storeCoordinator) {
        _parentManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        //wait till block finishes assigning persistent store before return context. -> thread safe;
        [_parentManagedObjectContext performBlockAndWait:^{
            [_parentManagedObjectContext setPersistentStoreCoordinator:storeCoordinator];
        }];
    }
    return _parentManagedObjectContext;
}

-(void) saveParentContext {
    [self.parentManagedObjectContext performBlockAndWait:^(void) {
        NSError *error = nil;
        BOOL saved = [self.parentManagedObjectContext save:&error];
        if (!saved) {
            NSLog(@"failed save background context due to %@", error);
        }
    }];
}
/** the managed Context responsible for the heavy lifting. */
-(NSManagedObjectContext *) backgroundManagedObjectContext
{
    if (_backgroundManagedObjectContext) {
        return _backgroundManagedObjectContext;
    }
    NSManagedObjectContext *parentContext = [self parentManagedObjectContext];
    if (parentContext) {
        _backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_backgroundManagedObjectContext performBlockAndWait:^(void) {
            [_backgroundManagedObjectContext setParentContext:parentContext];
        }];
    }
    return parentContext;
}

- (void)saveBackgroundContext {
    [self.backgroundManagedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        //save will propagate to parent to write to disk
        BOOL saved = [self.backgroundManagedObjectContext save:&error];
        if (!saved) {
            //error
            NSLog(@"failed save background context due to %@", error);
        }
    }];
}
/** the managed Context responsible for the UI. This is a child of the parent Context. NO saving is done with this context. */
-(NSManagedObjectContext *) mainManagedObjectContext
{
    NSManagedObjectContext *mainContext;
    NSManagedObjectContext *parentContext = [self parentManagedObjectContext];
    if (parentContext) {
        mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [mainContext performBlockAndWait:^(void) {
            [mainContext setParentContext:parentContext];
        }];
    }
    return mainContext;
}
// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Tumblrbot" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}


// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Tumblrbot.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
@end
