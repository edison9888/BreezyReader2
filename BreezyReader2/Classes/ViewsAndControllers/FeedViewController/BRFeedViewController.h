//
//  BRFeedViewController.h
//  BreezyReader2
//
//  Created by 金 津 on 12-3-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRSubscription.h"
#import "GRItem.h"
#import "BRFeedDataSource.h"
#import "BRBaseController.h"
#import "BRFeedDragDownController.h"
#import "BRFeedLoadMoreController.h"
#import "JJImageView.h"
#import "JJLabel.h"
#import "BRBottomToolBar.h"
#import "CustomSwitch.h"

@interface BRFeedViewController : BRBaseController <UITableViewDelegate, BRBaseDataSourceDelegate, CustomSwitchDelegate>

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet BRFeedDragDownController* dragController;
@property (nonatomic, retain) IBOutlet BRFeedLoadMoreController* loadMoreController;

@property (nonatomic, retain) IBOutlet UIView* loadingView;
@property (nonatomic, retain) IBOutlet JJLabel* loadingLabel;

@property (nonatomic, retain) IBOutlet UIView* titleView;
@property (nonatomic, retain) IBOutlet JJLabel* titleLabel;
@property (nonatomic, retain) IBOutlet BRBottomToolBar* bottomToolBar;

@property (nonatomic, retain) CustomSwitch* readSwitch;

@property (nonatomic, retain) GRSubscription* subscription;
@property (nonatomic, retain) BRFeedDataSource* dataSource;

-(IBAction)backButtonClicked:(id)sender;
-(IBAction)scrollToTop:(id)sender;
-(IBAction)showSearch:(id)sender;
-(IBAction)markAllAsReadButtonClicked:(id)sender;

@end


