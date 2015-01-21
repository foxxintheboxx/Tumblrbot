//
//  TMBAppDelegate.m
//  Tumblrbot
//
//  Created by Matthew Bischoff on 12/6/13.
//  Copyright (c) 2013 Matthew Bischoff. All rights reserved.
//

#import "TMBAppDelegate.h"
#import <TMTumblrSDK/TMAPIClient.h>
#import "TMBSync.h"
#import "Post.h"
#import "TMBCoreDataController.h"


@implementation TMBAppDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    [TMAPIClient sharedInstance].OAuthConsumerKey = @"Omq1FerYKMWeZnlvrIH9Qy3r6YIbyVDPdkQSfU5obu8eJBnt5n";
    [TMAPIClient sharedInstance].OAuthConsumerSecret = @"GHqE8rxq6r0IXCbBkj9NPR4ed0EIBqb8xP9k6PdulMuwsxJfyo";
    [TMAPIClient sharedInstance].OAuthToken = @"5AX3lj6EjPUVTbMOKvuMHBPb8M4NWZN5kerNXo4v7RYmzPKXCC";
    [TMAPIClient sharedInstance].OAuthTokenSecret = @"KsvGQwzzuKM1fv7jMNdEhDqH1NwpJL7JB6AUoxxBEfweLKh6np";
//    [TMAPIClient sharedInstance].OAuthToken = @"70n8XuV0A0ZJn33LyDcxjbO1pA2FFwdi0TwjdK4z0AhsuDlor3";
//    [TMAPIClient sharedInstance].OAuthTokenSecret = @"rOfEvPNNacO6zxW0bAxTxpRy6NkO2q0by2gimRAJfDCwDNNmdr";
    
    //dynamically allocate Tags to posts
    //[[TMBSync sharedInstance] addNewClassToSync:[Tag class]];
    [[TMBSync sharedInstance] addNewClassToSync:[Post class]];
    
    return YES;
}
-(void)applicationDidBecomeActive:(UIApplication *)application
{
    //initialize CoreData with API Sync
    if (![[TMBSync sharedInstance] didCompleteInitialSync])
    {
        [[TMBSync sharedInstance] beginSync];
    }
}
- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [[TMBCoreDataController sharedController] saveParentContext];
}
/** fast scrolling to top for statusbar tap. This method detects location of touch */
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    CGPoint location = [[[event allTouches] anyObject] locationInView:[self window]];
    if(location.y > 0 && location.y < 20) {
        [self touchStatusBar];
    }
}
/** all needing controllres who need fast scrolling will be notified. */
- (void) touchStatusBar {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"touchStatusBarClick" object:nil];
}

@end
