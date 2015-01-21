//
//  TMBUtils.m
//  Tumblrbot
//
//  Created by Ian Fox on 10/18/14.
//  Copyright (c) 2014 Matthew Bischoff. All rights reserved.
//

#import "TMBUtils.h"

@implementation TMBUtils
+(UIColor *) UIColorFromRGB:(int)rgbValue
{
    return [UIColor colorWithRed:(float)(((rgbValue & 0xFF0000) >> 16)/255.0) green:(float)(((rgbValue & 0x00FF00) >> 8)/255.0) blue:(float)((rgbValue & 0xFF)/255.0) alpha:1.0];
}
@end
