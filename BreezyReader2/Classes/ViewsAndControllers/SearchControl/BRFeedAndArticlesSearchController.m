//
//  BRFeedAndArticlesSearchController.m
//  BreezyReader2
//
//  Created by 金 津 on 12-3-19.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "BRFeedAndArticlesSearchController.h"
#import "ArticleSearchDataSource.h"
#import "FeedSearchDataSource.h"
#import "BRArticleScrollViewController.h"
#import "BRFeedViewController.h"
#import "UIViewController+BRAddition.h"
#import "GRItem.h"
#import "NSString+Addition.h"

static CGFloat kFeedSearchResultCellHeight = 84.0f;
static CGFloat kArticleSearchResultCellHeight = 70.0f;

@interface BRFeedAndArticlesSearchController ()

@property (nonatomic, retain) ArticleSearchDataSource* articleSearchDataSource;
@property (nonatomic, retain) FeedSearchDataSource* feedSearchDataSource;

@property (nonatomic, retain) NSTimer* searchTimer;

@end

@implementation BRFeedAndArticlesSearchController

@synthesize articleSearchDataSource = _articleSearchDataSource, feedSearchDataSource = _feedSearchDataSource;
@synthesize searchTimer = _searchTimer;
@synthesize loadMoreView = _loadMoreView;
@synthesize loadMoreButton = _loadMoreButton;

-(void)dealloc{
    self.articleSearchDataSource = nil;
    self.feedSearchDataSource = nil;
    [self.searchTimer invalidate];
    self.searchTimer = nil;
    self.loadMoreView = nil;
    self.loadMoreButton = nil;
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UISearchBar* searchBar = self.searchDisplayController.searchBar;
    searchBar.placeholder = NSLocalizedString(@"title_searchfeedsorarticles", nil);
    searchBar.scopeButtonTitles = [NSArray arrayWithObjects:NSLocalizedString(@"title_searcharticles", nil), NSLocalizedString(@"title_searchfeeds", nil), nil];
//    searchBar.backgroundImage = nil;
    searchBar.showsScopeBar = YES;
    searchBar.translucent = YES;
//    searchBar.hidden = YES;
    
    UITableView* tableView = self.searchDisplayController.searchResultsTableView;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.feedSearchDataSource = [[[FeedSearchDataSource alloc] init] autorelease];
    self.feedSearchDataSource.delegate = self;
    self.articleSearchDataSource = [[[ArticleSearchDataSource alloc] init] autorelease];
    self.articleSearchDataSource.delegate = self;
    self.searchDisplayController.searchResultsDataSource = self.articleSearchDataSource;
    tableView.rowHeight = kFeedSearchResultCellHeight;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.view = nil;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    UITableView* tableView = self.searchDisplayController.searchResultsTableView;
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)getReadyForSearch{
    self.view.alpha = 1.0f;
    [self.searchDisplayController.searchBar becomeFirstResponder];
    self.searchDisplayController.searchBar.alpha = 0;
    self.searchDisplayController.searchBar.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.searchDisplayController.searchBar.alpha = 1;
    }];
}

#pragma mark - search bar delegate
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self performSelector:@selector(dismissSearchView) withObject:nil afterDelay:0.2];
}

-(IBAction)loadMoreButtonClicked:(id)sender{
    BRSearchDataSource* datasource = (BRSearchDataSource*)self.searchDisplayController.searchResultsDataSource;
    [datasource loadMoreSearchResult];
}

-(void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope{
    NSString* currentKeywords = [self.searchDisplayController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    switch (selectedScope) {
        case 0:
            //search articles
            self.searchDisplayController.searchResultsDataSource = self.articleSearchDataSource;
            [self.searchDisplayController.searchResultsTableView reloadData];
            if ([currentKeywords isEqualToString:self.articleSearchDataSource.keywords] == NO){
                [self.articleSearchDataSource startSearchWithKeywords:currentKeywords];
            }
            break;
        case 1:
            //search feeds
            self.searchDisplayController.searchResultsDataSource = self.feedSearchDataSource;
            [self.searchDisplayController.searchResultsTableView reloadData];
            if ([currentKeywords isEqualToString:self.feedSearchDataSource.keywords] == NO){
                [self.feedSearchDataSource startSearchWithKeywords:currentKeywords];
            }
            break;
        default:
            break;
    }
    [self updateFooterView];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self.searchTimer invalidate];
    self.searchTimer = [NSTimer timerWithTimeInterval:0.7 target:self selector:@selector(startSearch:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.searchTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - search display delegate
-(void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller{
    [self searchBarCancelButtonClicked:nil];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    BRSearchDataSource* searchDataBase = (BRSearchDataSource*)self.searchDisplayController.searchResultsDataSource;
    id item = [searchDataBase objectAtIndexPath:indexPath];

    if ([searchDataBase isKindOfClass:[ArticleSearchDataSource class]]){
        BRArticleScrollViewController* article = [[[BRArticleScrollViewController alloc] initWithTheNibOfSameName] autorelease];
        article.feed = ((ArticleSearchDataSource*)searchDataBase).feed;
        article.index = indexPath.row;
        [[self topContainer] slideInViewController:article];
    }
    if ([searchDataBase isKindOfClass:[FeedSearchDataSource class]]){
        BRFeedViewController* feed = [[[BRFeedViewController alloc] initWithTheNibOfSameName] autorelease];
        GRSubscription* sub = [[GRSubscription alloc] init];
        sub.title = [[item objectForKey:@"title"] stringByReplacingHTMLTagAndTrim];
        sub.ID = [@"feed/" stringByAppendingString:[item objectForKey:@"url"]];
        feed.subscription = sub;
        [sub release];
        
        [[self topContainer] boomOutViewController:feed fromView:[tableView cellForRowAtIndexPath:indexPath]];
    }
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.searchDisplayController.searchResultsDataSource == self.articleSearchDataSource){
        return kArticleSearchResultCellHeight;
    }else{
        return kFeedSearchResultCellHeight;
    }
}

#pragma mark - timer selector
-(void)startSearch:(NSTimer*)timer{
    NSString* keywords = self.searchDisplayController.searchBar.text;
    BRSearchDataSource* searchDataBase = (BRSearchDataSource*)self.searchDisplayController.searchResultsDataSource;
    if (keywords.length == 0 || [searchDataBase.keywords isEqualToString:[keywords stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]]]){
        return;
    }
    DebugLog(@"start searching");
    [searchDataBase startSearchWithKeywords:keywords];
}

#pragma mark - dimiss searchView
-(void)dismissSearchView{
    [self.view removeFromSuperview];
    self.view = nil;
    self.searchDisplayController.searchResultsDataSource = nil;
    self.searchDisplayController.searchResultsDelegate = nil;
    self.articleSearchDataSource = nil;
    self.feedSearchDataSource = nil;
}

#pragma mark - search delegate
-(void)dataSourceDidStartSearching:(BRSearchDataSource*)dataSource{
    //show searching text
    if (dataSource == self.searchDisplayController.searchResultsDataSource){
        //reload data
        [self.searchDisplayController.searchResultsTableView reloadData];
        [self updateFooterView];
    }
}

-(void)dataSourceDidFinishSearching:(BRSearchDataSource*)dataSource{
    //reload table view
    if (dataSource == self.searchDisplayController.searchResultsDataSource){
        [self.searchDisplayController.searchResultsTableView reloadData];
        [self updateFooterView];
    }
}

-(void)dataSourceDidLoadMore:(BRSearchDataSource*)dataSource{
    if (dataSource == self.searchDisplayController.searchResultsDataSource){
        [self.searchDisplayController.searchResultsTableView reloadData];
        [self updateFooterView];
    }
}

-(void)dataSourceDidStartLoadMore:(BRSearchDataSource *)dataSource{
    [self updateFooterView];
}

-(void)updateFooterView{
    BRSearchDataSource* dataSource = (BRSearchDataSource*)self.searchDisplayController.searchResultsDataSource;
    UITableView* tableView = self.searchDisplayController.searchResultsTableView;
    if ([dataSource hasMore]){
        tableView.tableFooterView = self.loadMoreView;
    }else{
        tableView.tableFooterView = nil;
    }
    
    NSString* title = nil;
    if ([dataSource isLoading]){
        title = NSLocalizedString(@"title_loadingmore", nil);
        self.loadMoreButton.userInteractionEnabled = NO;
    }else{
        title = NSLocalizedString(@"title_loadmore", nil);
        self.loadMoreButton.userInteractionEnabled = YES;
    }
    [self.loadMoreButton setTitle:title forState:UIControlStateNormal];
}

@end
