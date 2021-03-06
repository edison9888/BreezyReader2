//
//  MainScreenDataSource.m
//  BreezyReader2
//
//  Created by 金 津 on 12-2-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MainScreenDataSource.h"
#import "BRSubGridViewController.h"
#import "BRSubFavoritePageController.h"
#import "BRRecommendationPageViewController.h"
#import "BRReadingStatistics.h"
#import "GoogleReaderClient.h"
#import "BRUserPreferenceDefine.h"
#import "BRExplorePageViewController.h"

@interface MainScreenDataSource ()

@property (nonatomic, strong) NSMutableSet* tagIDSet;
@property (nonatomic, strong) NSMutableDictionary* tagControllers;

@property (nonatomic, strong) BRRecommendationPageViewController* recommendationPage;
@property (nonatomic, strong) BRSubFavoritePageController* favoritePage;
@property (nonatomic, strong) BRExplorPageViewController* explorePage;

@end

@implementation MainScreenDataSource

@synthesize controllers = _controllers;
@synthesize tagIDSet = _tagIDSet, tagControllers = _tagControllers;
@synthesize recommendationPage = _recommendationPage, favoritePage = _favoritePage;
@synthesize explorePage = _explorePage;

-(id)init{
    self = [super init];
    if (self){
        self.controllers = [NSMutableArray arrayWithCapacity:0];
        self.tagIDSet = [NSMutableSet set];
        self.tagControllers = [NSMutableDictionary dictionary];
    }
    
    return self;
}


-(void)didReceiveMemoryWarning{
    [self.controllers makeObjectsPerformSelector:@selector(didReceiveMemoryWarning)];
}

-(void)superViewDidUnload{
    [self.controllers makeObjectsPerformSelector:@selector(viewDidUnload)];
}

-(void)reloadController{

    NSMutableArray* allLabels = [NSMutableArray arrayWithArray:[GoogleReaderClient tagListWithType:BRTagTypeLabel]];
    GRTag* emptyLabel = [GRTag tagWithNoLabel];
    [allLabels addObject:emptyLabel];
    
    NSSet* showedLabels = [NSSet setWithSet:self.tagIDSet];
    
    [showedLabels enumerateObjectsUsingBlock:^(NSString* tagID, BOOL* stop){
        if ([[GoogleReaderClient subscriptionsWithTagID:tagID] count] == 0 || [allLabels containsObject:tagID] == NO){
            [self.tagIDSet removeObject:tagID];
            [self.tagControllers removeObjectForKey:tagID];
        }
    }];
    
    [allLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
        GRTag* tag = obj;
        if ([[GoogleReaderClient subscriptionsWithTagID:tag.ID] count] > 0 && [self.tagIDSet containsObject:tag.ID] == NO){
            [self.tagIDSet addObject:tag.ID];
            BRSubGridViewController* controller = [[BRSubGridViewController alloc] init];
            controller.tag = tag;
            [self.tagControllers setObject:controller forKey:tag.ID];
        }
    }];
    
    //load explor page
    if (self.explorePage == nil){
        self.explorePage = [[BRExplorPageViewController alloc] init];
    }
    
    //load favorite page
    if (self.favoritePage == nil){
        if ([[BRReadingStatistics statistics] countOfRecordedReadingFrequency] >= 6){
            self.favoritePage = [[BRSubFavoritePageController alloc] init];
        }else{
            self.favoritePage = nil;
        }
    }
    //load recommendation page
    if (self.recommendationPage == nil){
        self.recommendationPage = [[BRRecommendationPageViewController alloc] init];
    }
    
    [self composeControllerList];
}

-(void)composeControllerList{
    [self.controllers removeAllObjects];
    
    if (self.favoritePage){
        [self.controllers addObject:self.favoritePage];
    }
    
//    if (self.explorePage){
//        [self.controllers addObject:self.explorePage];
//    }
    
    NSArray* sortedKeys = [[self.tagControllers allKeys] sortedArrayUsingComparator:^(id obj1, id obj2){
        NSString* sortID1 = [GoogleReaderClient tagWithID:obj1].sortID;
        sortID1 = (sortID1.length==0)?@"ZZZZZZZ":sortID1;
        NSString* sortID2 = [GoogleReaderClient tagWithID:obj2].sortID;
        sortID2 = (sortID2.length==0)?@"ZZZZZZZ":sortID2;
        return [sortID1 compare:sortID2];
    }];
    
    [sortedKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
        [self.controllers addObject:[self.tagControllers objectForKey:obj]];
    }];

    if (self.recommendationPage && [BRUserPreferenceDefine shouldShowRecommendations]){
        [self.controllers addObject:self.recommendationPage];
    }
}

-(NSInteger)numberOfContentViewsInScrollView:(InfinityScrollView *)scrollView{
    return [self.controllers count];
}

-(UIView*)scrollView:(InfinityScrollView *)scrollView contentViewAtIndex:(NSInteger)index{
    UIViewController* controller = [self.controllers objectAtIndex:index];
    return controller.view;
}

-(void)reload{
    [self.tagIDSet removeAllObjects];
    [self.tagControllers removeAllObjects];
    [self reloadController];
}

-(BRSubGridViewController*)controllerForTag:(NSString*)tagID{
    for (BRSubGridViewController* controller in self.controllers){
        if ([controller respondsToSelector:@selector(tag)]){
            if ([controller.tag.ID isEqualToString:tagID]){
                return controller;
            }
        }
    }
    
    return nil;
}

@end
