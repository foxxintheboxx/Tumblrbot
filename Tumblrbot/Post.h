//
//  Post.h
//  Tumblrbot
//
//  Created by Ian Fox on 10/16/14.
//  Copyright (c) 2014 Matthew Bischoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Post : NSManagedObject

@property (nonatomic, retain) NSData * photos;
@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * blog_name;
@property (nonatomic, retain) NSString * post_url;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * likes;
@property (nonatomic, retain) NSNumber * note_count;
@property (nonatomic, retain) NSNumber * since_id;
@property (nonatomic, retain) NSSet *myTags;
@end

@interface Post (CoreDataGeneratedAccessors)

- (void)addMyTagsObject:(NSManagedObject *)value;
- (void)removeMyTagsObject:(NSManagedObject *)value;
- (void)addMyTags:(NSSet *)values;
- (void)removeMyTags:(NSSet *)values;

@end
