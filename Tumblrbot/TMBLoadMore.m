//
//  TMBLoadMore.m
//  Tumblrbot
//
//  Created by Ian Fox on 10/19/14.
//  Copyright (c) 2014 Matthew Bischoff. All rights reserved.
//

#import "TMBLoadMore.h"

@implementation TMBLoadMore
-(void) awakeFromNib
{
    [self setUp];
}
- (IBAction)didTapLoadMoreButton:(id)sender {
    [self.delegate retriveMoreData];
}
-(void) setUp
{
    self.contentView.backgroundColor = [TMBUtils UIColorFromRGB:0x35465c];
    self.loadMoreButton.backgroundColor =[UIColor clearColor];
    self.loadMoreButton.layer.cornerRadius = 5;
    self.loadMoreButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.loadMoreButton.layer.borderWidth = 0.8;
    
}
@end
