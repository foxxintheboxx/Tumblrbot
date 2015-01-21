//
//  TMBBasicCell.m
//  Tumblrbot
//
//  Created by Ian Fox on 10/18/14.
//  Copyright (c) 2014 Matthew Bischoff. All rights reserved.
//

#import "TMBTextPostCell.h"

@implementation TMBTextPostCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self setUp];
    return self;
}
-(void)awakeFromNib
{
    [super awakeFromNib];
    [self setUp];
}
-(void) setUp
{
    self.contentView.backgroundColor = [TMBUtils UIColorFromRGB:0x35465c];
}
@end
