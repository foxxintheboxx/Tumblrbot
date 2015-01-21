//
//  TMBCoreDataController.h
//  Tumblrbot
//
//  Created by Ian Fox on 10/16/14.
//  Copyright (c) 2014 Matthew Bischoff. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMBCoreDataController : NSObject
+(TMBCoreDataController *) sharedController;

-(NSManagedObjectContext *) mainManagedObjectContext;
-(NSManagedObjectContext *) parentManagedObjectContext;
-(NSManagedObjectContext *) backgroundManagedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (void)saveParentContext;
- (void)saveBackgroundContext;

- (NSURL *)applicationDocumentsDirectory;
@end
