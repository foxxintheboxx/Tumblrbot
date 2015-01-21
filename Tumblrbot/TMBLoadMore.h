//
//  TMBLoadMore.h
//  Tumblrbot
//
//  Created by Ian Fox on 10/19/14.
//  Copyright (c) 2014 Matthew Bischoff. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol RetrieveMoreDataDelegate
-(void) retriveMoreData;
@end
@interface TMBLoadMore : UITableViewCell

- (IBAction)didTapLoadMoreButton:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *loadMoreButton;
@property (strong, nonatomic) id<RetrieveMoreDataDelegate> delegate;
@end
