//
//  DashBoardTableViewController.m
//  
//
//  Created by Ian Fox on 10/16/14.
//
//

#import "TMBDashBoardTableViewController.h"
#import "TMBCoreDataController.h"
#import "TMBSync.h"
#import "Post.h"
#import "TMBPostImageCell.h"
#import "TMBTextPostCell.h"
#import "TMBLoadMore.h"

@interface TMBDashBoardTableViewController ()
{
    CALayer *marker;
    CAReplicatorLayer *spinnerReplicator;
    UIRefreshControl *refreshControl;
    CGFloat previousScrollViewYOffset;
    NSString *entityName;
}
@property NSManagedObjectContext *managedObjectContext;
@property NSArray *posts;
@end

@implementation TMBDashBoardTableViewController
/* set managed ObjectContext to context with UIMainThread */
- (void)viewDidLoad {
    [super viewDidLoad];
    entityName = @"Post";
    self.posts = [[NSArray alloc]init];
    self.managedObjectContext = [[TMBCoreDataController sharedController] mainManagedObjectContext];
    [self loadDataFromCoreData:entityName sortBy:kObjectID isAscending:NO];
    [self setUp];
}

-(void) viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserverForName:kSyncCompletedNotificationID object:nil queue:nil usingBlock:^(NSNotification *note) {
        
        [self loadDataFromCoreData:entityName sortBy:kObjectID isAscending:NO];
        [self.tableView reloadData];
    }];

}
-(void) viewDidDisappear:(BOOL)animated
{
     [[NSNotificationCenter defaultCenter] removeObserver:self name:kSyncCompletedNotificationID object:nil];
}
/** setup for UI and notification center */
-(void) setUp
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [TMBUtils UIColorFromRGB:0x35465c];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Tumblr.png"]];
    refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl setTintColor:[UIColor whiteColor]];
    [self.tableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarTouch) name:@"touchStatusBarClick" object:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark = Table view delegate

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self.posts count])
    {
        return 70;
    }
    return [self calculateHeightForPost:indexPath];
}
-(CGFloat) calculateHeightForPost:(NSIndexPath *) indexPath
{
    CGFloat height;
    Post *post = [self.posts objectAtIndex:indexPath.row];
    if (post.photos != nil)
    {
        height = 500;
    } else {
        height = 300;
    }
    if ([post.html length] == 0)
    {
        height -= 100;
    }
    return height;
}

#pragma mark - Table view data source
-(void) refreshTable
{
    [refreshControl endRefreshing];
    [[TMBSync sharedInstance] refreshSync];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    
    if (![self.posts count])
    {   // NO data so do something?
        [self createSpinner];
        return 0;
        
    }
    return [self.posts count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.posts count])
    {
        return [self loadMoreButton];
    }
    return [self postCellForRowAtIndexPath:indexPath];
}

-(UITableViewCell *) loadMoreButton
{

    TMBLoadMore *button = [self.tableView dequeueReusableCellWithIdentifier:kLoadMoreID];
    button.delegate = self;
    button.selectionStyle = UITableViewCellSelectionStyleNone;
    return button;
}

-(UITableViewCell *) postCellForRowAtIndexPath:(NSIndexPath *) indexPath
{
    long index = [indexPath row];
    Post *post = [self.posts objectAtIndex:index];
    TMBTextPostCell *cell;
    if ([post valueForKey:@"photos"] != nil)
    {
        TMBPostImageCell *imageCell = [self.tableView dequeueReusableCellWithIdentifier:kPicturePostID];
        cell = imageCell;
    } else {
           cell = [self.tableView dequeueReusableCellWithIdentifier:kTextPostID];
    }
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

/** configures all Cell that are Posts. Assigns UIFields to model attributes. */
-(void) configureCell:(UITableViewCell *) unkownCell atIndexPath:(NSIndexPath *) indexPath
{
    long index = [indexPath row];
    Post *post = [self.posts objectAtIndex:index];
    TMBTextPostCell *cell = (TMBTextPostCell *) unkownCell;
    cell.blogNameLabel.text = [post valueForKey:@"blog_name"];
    cell.noteCountLabel.text = [NSString stringWithFormat:@" %@ notes", [post valueForKey:@"note_count"]];
    if ([post valueForKey:@"photos"] != nil)
    {
        UIImage *image = [UIImage imageWithData: post.photos];
        cell.bloggerProfileImageView.image = image;
        //Bug in the dynamic nslayout constraint
//        if ([post.html length] == 0)
//        {
//            
//            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(==1)]"
//                                                                         options:0
//                                                                         metrics:nil
//                                                                           views:NSDictionaryOfVariableBindings(view)]];
//            cell.captionTextView.attributedText = [post valueForKey:@"caption"];
//        } else {
//            view.attributedText = [post valueForKey:@"caption"];
//            [view sizeToFit];
//            NSDictionary *dictionary = @{@"view": view};
//            
//            NSDictionary *metric = @{@"height" : [NSNumber numberWithFloat:view.contentSize.height]};
//            [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(==height)]"
//                                                                         options:0
//                                                                         metrics:metric
//                                                                           views:dictionary]];
//            
//            
//        }

    }
    UITextView *view = cell.captionTextView;
    view.attributedText = [post valueForKey:@"caption"];
    [view scrollRectToVisible:CGRectMake(0, 0, 0, 0) animated:NO];
    
    NSMutableSet *tags = [post mutableSetValueForKey:@"myTags"];
    if ([tags count])
    {
        
        NSString *result = @" ";
        for (NSManagedObject *tagModel in tags)
        {
            NSString *text = [tagModel valueForKey:@"tag"];
            result = [NSString stringWithFormat:@"%@ #%@", result, text];
        }
        CGFloat width = 999;
        CGFloat height =  cell.tagsContainerScrollView.frame.size.height;
        UITextView *textView = [[UITextView alloc] initWithFrame: CGRectMake(0, 0, width, height/2)];
        textView.editable = NO;
        textView.backgroundColor = cell.captionTextView.backgroundColor;
        textView.textColor = [UIColor lightGrayColor];
        textView.text = result;
        [textView sizeToFit];
        [cell.tagsContainerScrollView setContentSize:CGSizeMake(textView.textContainer.size.width, height)];
        
        [cell.tagsContainerScrollView addSubview:textView];
        
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}




#pragma mark - CoreDataMethods
/** queries Core Data and returns Posts in isAscending order .*/
-(void) loadDataFromCoreData:(NSString*) className sortBy:(NSString *) key isAscending:(BOOL) isAscending
{

    [self.managedObjectContext performBlockAndWait:^(void) {
        [self.managedObjectContext reset];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:className];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:isAscending]]];
        NSError *error = nil;
        self.posts = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
    }];
    
    
}

#pragma mark - ScrollViewDelegate
/** instagram style navigation bar disapearing on scroll .*/
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect frame = self.navigationController.navigationBar.frame;
    CGFloat size = frame.size.height - 21;
    CGFloat framePercentageHidden = ((20 - frame.origin.y) / (frame.size.height - 1));
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGFloat scrollDiff = scrollOffset - previousScrollViewYOffset;
    CGFloat scrollHeight = scrollView.frame.size.height;
    CGFloat scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom;
    
    if (scrollOffset <= -scrollView.contentInset.top) {
        frame.origin.y = 20;
    } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
        frame.origin.y = -size;
    } else {
        frame.origin.y = MIN(20, MAX(-size, frame.origin.y - scrollDiff));
    }
    
    [self.navigationController.navigationBar setFrame:frame];
    [self updateTitleView:(1 - framePercentageHidden)];
    previousScrollViewYOffset = scrollOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self stoppedScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self stoppedScrolling];
    }
}
- (void)stoppedScrolling
{
    CGRect frame = self.navigationController.navigationBar.frame;
    if (frame.origin.y < 20) {
        [self animateNavBarTo:-(frame.size.height - 21)];
    }
}

- (void)updateTitleView:(CGFloat)alpha
{
    self.navigationItem.titleView.alpha = alpha;
    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}

- (void)animateNavBarTo:(CGFloat)y
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.navigationController.navigationBar.frame;
        CGFloat alpha = (frame.origin.y >= y ? 0 : 1);
        frame.origin.y = y;
        [self.navigationController.navigationBar setFrame:frame];
        [self updateTitleView:alpha];
    }];
}

/** ui scroll to top on status touch*/
-(void) statusBarTouch
{
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition: UITableViewScrollPositionTop animated:YES];
}
#pragma mark RetrieveMoreDelegate
-(void) retriveMoreData
{
    [self createSpinner];
    [[TMBSync sharedInstance] performSelectorInBackground:@selector(syncWithOffset:) withObject:[NSNumber numberWithLong:[self.posts count]]];
   
   
    
    
}
#pragma mark -Misc
/* hacky spinner. doesnt work to well because CAReplicators will continually generate layers or not generate enough. */
-(void) createSpinner
{
    marker = [CALayer layer];
    [marker setBounds:CGRectMake(0, 0, kDefaultThickness, kDefaultLength)];
    [marker setCornerRadius:kDefaultThickness*0.5];
    [marker setBackgroundColor:[[TMBUtils UIColorFromRGB:0xFFFFFF] CGColor]];
    [marker setPosition:CGPointMake(kDefaultHUDSide*0.5, kDefaultHUDSide*0.5+kDefaultSpread)];
    spinnerReplicator = [CAReplicatorLayer layer];
    [spinnerReplicator setBounds:CGRectMake(0, 0, kDefaultHUDSide, kDefaultHUDSide)];
    [spinnerReplicator setCornerRadius:10.0];
    [spinnerReplicator setBackgroundColor:[[UIColor clearColor] CGColor]];
    [spinnerReplicator setPosition:CGPointMake(CGRectGetMidX([self.tableView frame]),
                                               CGRectGetMidY([self.tableView  frame]))];
    CGFloat angle = (2*M_PI)/(kDefaultNumberOfSpinnerMarkers);
    CATransform3D instanceRotation = CATransform3DMakeRotation(angle, 0.0, 0.0, 1.0);
    [spinnerReplicator setInstanceCount:kDefaultNumberOfSpinnerMarkers];
    [spinnerReplicator setInstanceTransform:instanceRotation];
    [spinnerReplicator addSublayer:marker];
    [self.tableView.layer addSublayer:spinnerReplicator];
    
    [marker setOpacity:0.0];
    CABasicAnimation * fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [fade setFromValue:[NSNumber numberWithFloat:1.0]];
    [fade setToValue:[NSNumber numberWithFloat:0.0]];
    [fade setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [fade setRepeatCount:3];
    [fade setDuration:kDefaultSpeed];
    CGFloat markerAnimationDuration = kDefaultSpeed/kDefaultNumberOfSpinnerMarkers;
    [spinnerReplicator setInstanceDelay:markerAnimationDuration];
    [marker addAnimation:fade forKey: @"MarkerAnimationKey"];
}
@end
