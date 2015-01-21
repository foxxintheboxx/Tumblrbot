//
//  Tag.h
//  Tumblrbot
//
//  Created by Ian Fox on 10/16/14.
//  Copyright (c) 2014 Matthew Bischoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Post;

@interface Tag : NSManagedObject

@property (nonatomic, retain) NSString * tag;
@property (nonatomic, retain) Post *myPost;

@end
