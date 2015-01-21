//
//  TMBBasicCell.h
//  Tumblrbot
//
//  Created by Ian Fox on 10/18/14.
//  Copyright (c) 2014 Matthew Bischoff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMBTextPostCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *bloggerProfileImageView;
@property (strong, nonatomic) IBOutlet UILabel *blogNameLabel;
@property (strong, nonatomic) IBOutlet UITextView *captionTextView;
@property (strong, nonatomic) IBOutlet UIScrollView *tagsContainerScrollView;
@property (strong, nonatomic) IBOutlet UILabel *noteCountLabel;

@end
