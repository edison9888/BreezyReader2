//
//  BRArticleScrollViewController.m
//  BreezyReader2
//
//  Created by 金 津 on 12-4-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "BRArticleScrollViewController.h"
#import "BRArticleDetailViewController.h"
#import "UIViewController+BRAddition.h"
#import "GoogleReaderClient.h"
#import "JJSingleWebController.h"
#import "JJSocialShareManager.h"
#import "JJADManager.h"
#import "GoogleReaderClientHelper.h"
#import <QuartzCore/QuartzCore.h>

@interface BRArticleScrollViewController (){
    BOOL _showMenu;
}

@property (nonatomic, strong) NSArray* articleDetailControllers;
@property (nonatomic, strong) NSMutableSet* clients;

@property (nonatomic, strong) UIView* adView;

@end

@implementation BRArticleScrollViewController

@synthesize scrollView = _scrollView;
@synthesize index = _index;
@synthesize feed = _feed;
@synthesize backButton = _backButton;
@synthesize bottomToolBar = _bottomToolBar;
@synthesize articleDetailControllers = _articleDetailControllers;
@synthesize clients = _clients;
@synthesize adView = _adView;
@synthesize starButton = _starButton, unstarButton = _unstarButton;
@synthesize starButtonContainer = _starButtonContainer;
@synthesize actionMenuController = _actionMenuController;
@synthesize leftScrollButton = _leftScrollButton, rightScrollButton = _rightScrollButton;

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.clients makeObjectsPerformSelector:@selector(clearAndCancel)];
    self.articleDetailControllers = nil;
    self.scrollView = nil;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        self.clients = [NSMutableSet set];
        [self registerNotifications];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadControllers];
    self.scrollView.datasource = self;
    self.scrollView.delegate = self;
    self.scrollView.pageIndex = self.index;
//    self.scrollView.dimTheInvisibleContentView = YES;
    [self.scrollView reloadData];
    
    self.adView = [[JJADManager sharedManager] adView];
    if (self.adView){
        CGRect frame = self.adView.frame;
        frame.origin.x = 0;
//        frame.origin.y = self.view.bounds.size.height-self.bottomToolBar.frame.size.height-frame.size.height;
        frame.origin.y = 0;
        self.adView.frame = frame;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adDidLoad:) name:NOTIFICATION_ADLOADED object:self.adView];
        [self.view addSubview:self.adView];
        [self.view bringSubviewToFront:self.bottomToolBar];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.scrollView = nil;
    self.bottomToolBar = nil;
    self.articleDetailControllers = nil;
    self.adView = nil;
    self.actionMenuController = nil;
}

-(void)viewDidLayoutSubviews{
    CGRect frame = self.bottomToolBar.frame;
    frame.origin.y = self.view.frame.size.height - frame.size.height;
    self.bottomToolBar.frame = frame;
    
    frame = self.scrollView.frame;
    frame.size.height = self.view.frame.size.height - self.bottomToolBar.frame.size.height;
    if (self.adView.hidden == NO){
        frame.size.height -= self.adView.frame.size.height;
        frame.origin.y = self.adView.frame.size.height;
    }
    self.scrollView.frame = frame;
    
    frame = self.actionMenuController.view.frame;
    frame.size.width = 300.0f;
    frame.size.height = 80.0f;
    self.actionMenuController.view.frame = frame;
    
    [self.view bringSubviewToFront:self.bottomToolBar];
    
    [self.scrollView reloadData];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.adView performSelector:@selector(stopAdRequest)];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [UIApplication sharedApplication].statusBarHidden = YES;
//    [[UIApplication sharedApplication] setStatusBarStyle:UIBarStyleBlack animated:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.adView performSelector:@selector(resumeAdRequest)];
    
    [UIView animateWithDuration:3.0f animations:^{
        self.leftScrollButton.alpha = 0.05f;
        self.rightScrollButton.alpha = 0.05f;
    }];
}

-(void)loadControllers{
    NSMutableArray* controllers = [NSMutableArray array];
    for (GRItem* item in self.feed.items){
        BRArticleDetailViewController* articleDetail = [[BRArticleDetailViewController alloc] initWithItem:item];
        articleDetail.delegate = self;
        [controllers addObject:articleDetail];
        [self addChildViewController:articleDetail];
    }
    
    self.articleDetailControllers = controllers;
}

#pragma mark - ad action
-(void)adDidLoad:(NSNotification*)notification{
    if (self.adView == notification.object){
        [self viewDidLayoutSubviews];
    }
}

#pragma mark - UIScrollView delegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self hideActionMenu];
}

#pragma mark - action
-(IBAction)showHideActionMenuButtonClicked:(id)sender{
    [self showHideActionMenu];
}

-(void)hideActionMenu{
    [self.actionMenuController dismiss];    
    
    _showMenu = NO;
}

-(void)showActionMenu{
    CGFloat x = self.mainContainer.frame.size.width - 10;
    CGFloat y = self.bottomToolBar.frame.origin.y - 3;
    [self.actionMenuController showMenuInPosition:CGPointMake(x, y) anchorPoint:CGPointMake(1, 1)];
    
    _showMenu = YES;
}

-(void)showHideActionMenu{
    if (_showMenu){
        [self hideActionMenu];
    }else{
        [self showActionMenu];
    }
}

-(IBAction)showHideFontsizeMenu:(id)sender{
    
}

-(IBAction)favoriteActionButtonClicked:(id)sender{
    DebugLog(@"share to read it later");
    GRItem* item = [self.feed.items objectAtIndex:self.index];
//    NSString* content = (item.content)?item.content:item.summary;
    NSString* urlString = item.alternateLink;
    [[JJSocialShareManager sharedManager] sendToReadItLaterWithTitle:item.title message:@"" urlString:urlString];
}

-(IBAction)back:(id)sender{
    [[self topContainer] slideOutViewController];
}

-(IBAction)viewInSafari:(id)sender{
    NSInteger index = [self.scrollView currentIndex];
    GRItem* item = [self.feed.items objectAtIndex:index];
    JJSingleWebController* webController = [[JJSingleWebController alloc] initWithTheNibOfSameName];
    webController.URL = [NSURL URLWithString:item.alternateLink];
    
    [UIApplication sharedApplication].statusBarHidden = NO;
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:webController];
    [self presentViewController:nav animated:YES completion:NULL];
}

-(IBAction)scrollCurrentPageToTop:(id)sender{
    NSInteger index = [self.scrollView currentIndex];
    [[self.articleDetailControllers objectAtIndex:index] performSelector:@selector(scrollToTop)];
}

-(IBAction)starItem:(id)sender{
    GoogleReaderClient* client = [GoogleReaderClientHelper client];
    GRItem* item = [self.feed.items objectAtIndex:self.index];
    [client starArticle:item.ID];
    if (self.starButton.superview == self.starButtonContainer){
        [UIView transitionFromView:self.starButton toView:self.unstarButton duration:0.2 options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL finished){
            [self.starButton removeFromSuperview]; 
        }];
    }

}

-(IBAction)unstarItem:(id)sender{
    GoogleReaderClient* client = [GoogleReaderClientHelper client];
    GRItem* item = [self.feed.items objectAtIndex:self.index];
    [client unstartArticle:item.ID];
    if (self.unstarButton.superview == self.starButtonContainer){
        [UIView transitionFromView:self.unstarButton toView:self.starButton duration:0.2 options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL finished){
            [self.unstarButton removeFromSuperview]; 
        }];
    }
}

-(IBAction)scrollToNextPage:(id)sender{
    NSInteger index = [self.scrollView currentIndex];
    if (index + 1 < [self numberOfPagesInScrollView:self.scrollView]){
        [self.scrollView scrollToPageAtIndex:index + 1 animated:YES];
    }
}

-(IBAction)scrollToPreviousPage:(id)sender{
    NSInteger index = [self.scrollView currentIndex];
    if (index - 1 >= 0){
        [self.scrollView scrollToPageAtIndex:index - 1 animated:YES];
    }

}

#pragma mark - JJPageScrollView data source

-(NSUInteger)numberOfPagesInScrollView:(JJPageScrollView*)scrollView{
    return [self.feed.items count];
}

-(UIView*)scrollView:(JJPageScrollView*)scrollView pageAtIndex:(NSInteger)index{
    UIViewController* controller = [self.articleDetailControllers objectAtIndex:index];
    return controller.view;
}

-(CGSize)scrollView:(JJPageScrollView*)scrollView sizeOfPageAtIndex:(NSInteger)index{
    return self.scrollView.bounds.size;
}

#pragma mark - JJPageScrollView delegate

-(void)scrollView:(JJPageScrollView*)scrollView didScrollToPageAtIndex:(NSInteger)index{
    self.index = index;
    [self updateBottomToolBar];
    GRItem* item = [self.feed.items objectAtIndex:index];
    if (item.isReaded == NO){
        GoogleReaderClient* client = [GoogleReaderClientHelper client];
        [client markArticleAsRead:item.ID];
    }
}

-(void)scrollViewWillStartDragging:(JJPageScrollView *)scrollView{
    [self hideActionMenu];
}

-(void)scrollViewDidRemovePageAtIndex:(NSInteger)index{
    UIViewController* controller = [self.articleDetailControllers objectAtIndex:index];
    [controller viewWillUnload];
    controller.view = nil;
    [controller viewDidUnload];
}

#pragma mark - update bottom tool bar
-(void)updateBottomToolBar{
    GRItem* item = [self.feed.items objectAtIndex:self.index];
    [self.starButtonContainer.layer removeAllAnimations];
    if (item.isStarred){
        [self.starButton removeFromSuperview];
        [self.starButtonContainer addSubview:self.unstarButton];
    }else{
        [self.unstarButton removeFromSuperview];
        [self.starButtonContainer addSubview:self.starButton];
    }
}

#pragma mark - register notification
-(void)registerNotifications{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(shareToMail:) name:NOTIFICATION_SHARE_MAIL object:nil];
    [nc addObserver:self selector:@selector(shareToWeibo:) name:NOTIFICATION_SHARE_WEIBO object:nil];
    [nc addObserver:self selector:@selector(shareToTwitter:) name:NOTIFICATION_SHARE_TWITTER object:nil];
    [nc addObserver:self selector:@selector(shareToInstapaper:) name:NOTIFICATION_SHARE_INSTAPAPER object:nil];
    [nc addObserver:self selector:@selector(shareToReadItLater:) name:NOTIFICATION_SHARE_READITLATER object:nil];
    [nc addObserver:self selector:@selector(shareToEvernote:) name:NOTIFICATION_SHARE_EVERNOTE object:nil];
    [nc addObserver:self selector:@selector(shareToFacebook:) name:NOTIFICATION_SHARE_FACEBOOK object:nil];
}

#pragma mark - notification call back
-(void)shareToWeibo:(NSNotification*)notification{
    DebugLog(@"share to weibo");
    GRItem* item = [self.feed.items objectAtIndex:self.index];
    NSString* urlString = item.alternateLink;
    [[JJSocialShareManager sharedManager] sendToWeiboWithMessage:item.title urlString:urlString image:nil];
    [self hideActionMenu];
}

-(void)shareToEvernote:(NSNotification*)notification{
    DebugLog(@"share to evernote");    
    GRItem* item = [self.feed.items objectAtIndex:self.index];
    NSString* title = item.title;
    NSString* content = (item.content)?item.content:item.summary;
    NSString* urlString = item.alternateLink;
    [[JJSocialShareManager sharedManager] sendToEvernoteWithTitle:title message:content urlString:urlString];
    [self hideActionMenu];
}

-(void)shareToTwitter:(NSNotification*)notification{
    DebugLog(@"share to twitter");
    GRItem* item = [self.feed.items objectAtIndex:self.index];
    NSString* urlString = item.alternateLink;
    [[JJSocialShareManager sharedManager] sendToTwitterWithText:item.title urlString:urlString image:nil];
    [self hideActionMenu];
}

-(void)shareToInstapaper:(NSNotification*)notification{
    DebugLog(@"share to instapaper");
    GRItem* item = [self.feed.items objectAtIndex:self.index];
    NSString* content = (item.content)?item.content:item.summary;
    NSString* urlString = item.alternateLink;
    [[JJSocialShareManager sharedManager] sendToInstapaperWithTitle:item.title message:content urlString:urlString];
    [self hideActionMenu];
}

-(void)shareToReadItLater:(NSNotification*)notification{
    DebugLog(@"share to read it later");
    GRItem* item = [self.feed.items objectAtIndex:self.index];
//    NSString* content = (item.content)?item.content:item.summary;
    NSString* urlString = item.alternateLink;
    [[JJSocialShareManager sharedManager] sendToReadItLaterWithTitle:item.title message:@"" urlString:urlString];
    [self hideActionMenu];
}

-(void)shareToMail:(NSNotification*)notification{
    DebugLog(@"share to mail");
    GRItem* item = [self.feed.items objectAtIndex:self.index];
    NSString* content = (item.content)?item.content:item.summary;
    NSString* urlString = item.alternateLink;
    [[JJSocialShareManager sharedManager] sendToMailWithTitle:item.title message:content urlString:urlString];
    [self hideActionMenu];
}

-(void)shareToFacebook:(NSNotification*)notification{
    DebugLog(@"share to facebook");
    GRItem* item = [self.feed.items objectAtIndex:self.index];
    NSString* content = (item.content)?item.content:item.summary;
//    NSString* urlString = item.alternateLink;
    [[JJSocialShareManager sharedManager] sendToFacebookWithTitle:item.title message:content];
    [self hideActionMenu];
}

@end
