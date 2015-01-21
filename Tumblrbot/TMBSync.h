//
//  TMBSync.h
//  
//
//  Created by Ian Fox on 10/16/14.
//
//

#import <Foundation/Foundation.h>

@interface TMBSync : NSObject

@property (atomic, readonly) BOOL syncInProgress;

+(TMBSync *) sharedInstance;
-(void) addNewClassToSync: (Class) classOfModel;
-(void) beginSync;
- (BOOL) didCompleteInitialSync;
-(void) syncWithOffset:(NSNumber *)offset;
-(void) refreshSync;
@end
