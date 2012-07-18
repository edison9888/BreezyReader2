//
//  DirectMessage.m
//  WeiboPad
//
//  Created by junmin liu on 10-10-6.
//  Copyright 2010 Openlab. All rights reserved.
//

#import "DirectMessage.h"


@implementation DirectMessage
@synthesize directMessageId, text, senderId, recipientId, createdAt, senderScreenName, recipientScreenName;
@synthesize sender, recipient;

- (DirectMessage*)initWithJsonDictionary:(NSDictionary*)dic {

	if (self = [super init]) {
		directMessageId = [dic getLongLongValueValueForKey:@"id" defaultValue:-1];
		text = [dic getStringValueForKey:@"text" defaultValue:@""];
		senderId = [dic getIntValueForKey:@"sender_id" defaultValue:-1];
		recipientId = [dic getIntValueForKey:@"recipient_id" defaultValue:-1];
		senderScreenName = [dic getStringValueForKey:@"sender_screen_name" defaultValue:@""];
		recipientScreenName = [dic getStringValueForKey:@"recipient_screen_name" defaultValue:@""];
		
		NSDictionary* senderDic = [dic objectForKey:@"sender"];
		if (senderDic) {
			sender = [User userWithJsonDictionary:senderDic];
		}
		
		NSDictionary* recipientDic = [dic objectForKey:@"recipient"];
		if (recipientDic) {
			recipient = [User userWithJsonDictionary:recipientDic];
		}
		
	}
	return self;

}

+ (DirectMessage*)directMessageWithJsonDictionary:(NSDictionary*)dic {
	return [[DirectMessage alloc] initWithJsonDictionary:dic];
}

@end
