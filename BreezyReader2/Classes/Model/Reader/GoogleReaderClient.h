//
//  GoogleReaderClient.h
//  BreezyReader2
//
//  Created by 金 津 on 12-3-28.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

@interface GoogleReaderClient : NSObject<ASIHTTPRequestDelegate>

@property (nonatomic, readonly) NSError* error;
@property (nonatomic, readonly) NSString* responseString;
@property (nonatomic, readonly) NSData* responseData;
@property (nonatomic, readonly) id responseJSONValue;
@property (nonatomic, readonly) id responseFeedSearchingJSONValue;

+(id)clientWithDelegate:(id)delegate action:(SEL)action;

-(id)initWithDelegate:(id)delegate action:(SEL)action;

-(void)clearAndCancel;

-(void)requestFeedWithIdentifier:(NSString*)identifer
                           count:(NSNumber*)count 
                       startFrom:(NSDate*)date 
                         exclude:(NSString*)excludeString 
                    continuation:(NSString*)continuationStr
                    forceRefresh:(BOOL)refresh;

-(void)getStreamDetails:(NSString*)streamID;
-(void)queryContentsWithIDs:(NSArray*)IDArray;
-(void)searchArticlesWithKeywords:(NSString*)keywords;
-(void)searchFeedsWithKeywords:(NSString*)keywords;

-(BOOL)isLoading;

@end
