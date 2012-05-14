//
//  BRMainScreenController.m
//  BreezyReader2
//
//  Created by 金 津 on 11-12-26.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "BRMainScreenController.h"
#import "MainScreenDataSource.h"
#import "GoogleAuthManager.h"
#import "NSObject+Notifications.h"
#import "GoogleAppConstants.h"
#import "BRViewControllerNotification.h"
#import "BRFeedAndArticlesSearchController.h"
#import "BRFeedViewController.h"
#import "GoogleReaderClient.h"
#import "BRTagAndSubListViewController.h"
#import "BRSettingViewController.h"
#import "BaseActivityLabel.h"
#import <QuartzCore/QuartzCore.h>

@interface BRMainScreenController (){
    BOOL _initialLoading;
    NSInteger _scrollIndex;
}

@property (nonatomic, retain) MainScreenDataSource* dataSource;
@property (nonatomic, retain) GoogleReaderClient* client;
@property (nonatomic, retain) BaseActivityLabel* activityLabel;

-(void)reload;

@end

@implementation BRMainScreenController

@synthesize infinityScroll = _infinityScroll;
@synthesize allSubListController = _allSubListController;
@synthesize dataSource = _dataSource;

@synthesize sideMenuController = _sideMenuController;

@synthesize searchController = _searchController;
@synthesize subOverrviewController = _subOverrviewController;

@synthesize activityLabel = _activityLabel;

@synthesize client = _client;

#pragma mark - init and dealloc

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.wantsFullScreenLayout = YES;
        self.client = [GoogleReaderClient clientWithDelegate:self action:@selector(clientFinished:)];
        _scrollIndex = 0.0f;
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.client clearAndCancel];
    self.client = nil;
    self.infinityScroll = nil;
    self.sideMenuController = nil;
    self.dataSource = nil;
    self.searchController = nil;
    self.subOverrviewController = nil;
    self.allSubListController = nil;
    self.activityLabel = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    [self.dataSource didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.backgroundView = [[[UIImageView alloc] initWithFrame:self.view.bounds] autorelease];
    
    self.infinityScroll = [[[InfinityScrollView alloc] initWithFrame:self.mainContainer.bounds] autorelease];
    self.dataSource = [[[MainScreenDataSource alloc] init] autorelease];
    self.infinityScroll.dataSource = self.dataSource;
    [self.infinityScroll setIndex:_scrollIndex];
    self.infinityScroll.infinityDelegate = self;
    self.infinityScroll.backgroundColor = [UIColor clearColor];

    CGRect menuRect = self.sideMenuController.view.frame;
    menuRect.size.height = self.mainContainer.bounds.size.height;
    menuRect.size.width = 60;
    menuRect.origin.x = self.mainContainer.bounds.size.width - menuRect.size.width;
    menuRect.origin.y = 0;
    [self.sideMenuController.view setFrame:menuRect];
    
    [self switchContentViewsToViews:[NSArray arrayWithObjects:self.infinityScroll, self.sideMenuController.view, nil] animated:YES];
    
    if ([GoogleReaderClient isReaderLoaded] == NO){
        [self.client refreshReaderStructure];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.infinityScroll = nil;
    self.sideMenuController = nil;
    self.searchController = nil;
    self.subOverrviewController = nil;
    self.allSubListController = nil;
    self.activityLabel = nil;
//    self.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.infinityScroll.frame = self.mainContainer.bounds;
    DebugLog(@"%@", self.infinityScroll);
}

-(void)viewWillAppear:(BOOL)animated{
    UIImageView* imageView = (UIImageView*)self.backgroundView;
    imageView.image = [UserPreferenceDefine backgroundImage];
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [UIApplication sharedApplication].statusBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
    
    if ([GoogleReaderClient needRefreshReaderStructure]){
        [self.client refreshReaderStructure];
    }else if ([GoogleReaderClient needRefreshUnreadCount]){
        [self.client refreshUnreadCount];
    }
    
    [self performSelectorOnMainThread:@selector(reload) withObject:nil waitUntilDone:NO];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    [self performSelectorOnMainThread:@selector(reload) withObject:nil waitUntilDone:NO];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

#pragma mark - notifications register and handler
-(void)registerNotifications{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(syncBegan:) name:NOTIFICATION_BEGIN_UPDATEREADERSTRUCTURE object:nil];
    [nc addObserver:self selector:@selector(syncEnd:) name:NOTIFICAITON_END_UPDATEREADERSTRUCTURE object:nil];
    [nc addObserver:self selector:@selector(syncFailed:) name:NOTIFICAITON_FAILED_UPDATEREADERSTRUCTURE object:nil];
    [nc addObserver:self selector:@selector(tagOrSubChanged:) name:TAGORSUBCHANGED object:nil];
    [nc addObserver:self selector:@selector(loginStatusChanged:) name:NOTIFICATION_LOGINSTATUSCHANGED object:nil];
    [nc addObserver:self selector:@selector(startFlipTile:) name:NOTIFICATION_STARTFLIPSUBTILEVIEW object:nil];
    [nc addObserver:self selector:@selector(showSearchUI:) name:NOTIFICATION_SERACHBUTTONCLICKED object:nil];
    [nc addObserver:self selector:@selector(switchDownloadMode:) name:NOTIFICATION_DOWNLOADBUTTONCLICKED object:nil];
    [nc addObserver:self selector:@selector(refreshClientData:) name:NOTIFICATION_RELOADBUTTONCLICKED object:nil];
    [nc addObserver:self selector:@selector(showLogoutDialog:) name:NOTIFICATION_LOGOUTBUTTONCLICKED object:nil];
    [nc addObserver:self selector:@selector(showConfigUI:) name:NOTIFICATION_CONFIGBUTTONCLICKED object:nil];
    [nc addObserver:self selector:@selector(showStarItems:) name:NOTIFICATION_STARBUTTONCLICKED object:nil];
    [nc addObserver:self selector:@selector(showSubscriptionList:) name:NOTIFICATION_SHOWAUBLISTBUTTONCLICKED object:nil];
    [nc addObserver:self selector:@selector(finishedFlipTile:) name:NOTIFICATION_FINISHEDFLIPSUBTILEVIEW object:nil];
}

-(void)syncBegan:(NSNotification*)notification{
    DebugLog(@"start to sync reader data", nil);
    [self.activityLabel show];
}

-(void)syncEnd:(NSNotification*)notification{
    DebugLog(@"end of syncing reader data", nil);
    self.activityLabel.message = NSLocalizedString(@"message_reloadfinished", nil);
    [self.activityLabel dismissAfterDelay:1];
    self.activityLabel = nil;
    [self reload];    
}

-(void)syncFailed:(NSNotification*)notification{
    DebugLog(@"end of syncing reader data", nil);
    self.activityLabel.message = NSLocalizedString(@"message_reloadfailed", nil);
    [self.activityLabel dismissAfterDelay:1];
    self.activityLabel = nil;
}

-(void)tagOrSubChanged:(NSNotification*)notification{
    DebugLog(@"tag or sub changed", nil);
}

-(void)loginStatusChanged:(NSNotification*)notification{
    DebugLog(@"Login status changed", nil);
    NSString* status = [notification.userInfo objectForKey:@"status"];
    DebugLog(@"current login status is %@", status);
//    if ([status isEqualToString:LOGIN_NOTIN]){
//        [self switchContentViewsToViews:[NSArray arrayWithObject:self.signInButton] animated:YES];
//    }else if ([status isEqualToString:LOGIN_SUCCESSFUL]){
//        [self switchContentViewsToViews:[NSArray arrayWithObject:self.signoutButton] animated:YES];
//    }
}

-(void)startFlipTile:(NSNotification*)notification{
    DebugLog(@"start flip tile view");
    
    if (self.subOverrviewController == nil){
        self.subOverrviewController = [[[SubOverviewController alloc] initWithTheNibOfSameName] autorelease];
    }
    [self.subOverrviewController showOverviewForSub:[notification.userInfo objectForKey:@"subscription"] inView:self.mainContainer flipFrom:notification.object];
}

-(void)finishedFlipTile:(NSNotification*)notification{
    self.subOverrviewController = nil;
}

-(void)reload{
    [self.childViewControllers makeObjectsPerformSelector:@selector(willMoveToParentViewController:) withObject:nil];
    [self.childViewControllers makeObjectsPerformSelector:@selector(removeFromParentViewController)];
    [self.childViewControllers makeObjectsPerformSelector:@selector(didMoveToParentViewController:) withObject:nil];
    
    [self.dataSource reload];
    [self.infinityScroll reloadData];
    
    [self.dataSource.controllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
        [self addChildViewController:obj];
    }];
    [self addChildViewController:self.searchController];
    [self addChildViewController:self.allSubListController];
}
#pragma mark - delegate methods for infinity scroll view
-(void)scrollView:(InfinityScrollView *)scrollView didStopAtChildViewOfIndex:(NSInteger)index{
    //add more code here
    _scrollIndex = index;
}

-(void)scrollView:(InfinityScrollView *)scrollView userDraggingOffset:(CGPoint)offset{
    //do nothing
}

-(void)scrollViewDidScroll:(InfinityScrollView*)scrollView{

}

#pragma mark - NOTIFICATOIN call back
-(void)showSearchUI:(NSNotification*)notification{
    [self.mainContainer addSubview:self.searchController.view];
    [self.searchController getReadyForSearch];
//    [[self topContainer] addToTop:self.searchController animated:YES];
}

-(void)showStarItems:(NSNotification*)notification{
    BRFeedViewController* starFeed = [[[BRFeedViewController alloc] initWithTheNibOfSameName] autorelease];
    starFeed.subscription = [GRSubscription subscriptionForLabel:[GoogleReaderClient starTag]];
    starFeed.subscription.title = NSLocalizedString(@"title_starred", nil);
    [[self topContainer] boomOutViewController:starFeed fromView:notification.object];
}

-(void)showSubscriptionList:(NSNotification*)notification{
    self.secondaryView = self.allSubListController.view;
    [self slideShowSecondaryViewWithCompletionBlock:NULL];
}

-(void)switchDownloadMode:(NSNotification*)notification{
    DebugLog(@"switch download mode");
}

-(void)showLogoutDialog:(NSNotification*)notification{
    DebugLog(@"show logout dialog");
}

-(void)showConfigUI:(NSNotification*)notification{
    DebugLog(@"show config UI");
    BRSettingViewController* setting = [[[BRSettingViewController alloc] initWithTheNibOfSameName] autorelease];
    UINavigationController* nav = [[[UINavigationController alloc] initWithRootViewController:setting] autorelease];
    
    [self presentViewController:nav animated:YES completion:NULL];
}

-(void)refreshClientData:(NSNotification*)notification{
    DebugLog(@"refresh client data");
    UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"title_reloadalldata", nil) message:NSLocalizedString(@"message_reloadalldata", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"title_cancel", nil) otherButtonTitles:NSLocalizedString(@"title_ok", nil), nil] autorelease];
    [alertView show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1){
        //ok button
        //start refresh data
        self.activityLabel = [BaseActivityLabel loadFromBundle];
        self.activityLabel.message = NSLocalizedString(@"message_startloading", nil);
        [self.client clearAndCancel];
        self.client = [GoogleReaderClient clientWithDelegate:self action:@selector(clientFinished:)];
        [self.client refreshReaderStructure];
    }
}

#pragma mark - reader client call back
-(void)clientFinished:(GoogleReaderClient*)client{
    if (client.error){
        //handle error
        DebugLog(@"error happened %@", [client.error localizedDescription]);
    }
}

@end
