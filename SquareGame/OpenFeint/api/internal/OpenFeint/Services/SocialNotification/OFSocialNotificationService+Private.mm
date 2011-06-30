//  Copyright 2009-2010 Aurora Feint, Inc.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  	http://www.apache.org/licenses/LICENSE-2.0
//  	
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "OFSocialNotificationService.h"
#import "OFSocialNotificationService+Private.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFService+Private.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Settings.h"
#import "OFUsersCredentialService.h"
#import "OFUsersCredential.h"
#import "OFPaginatedSeries.h"
#import "OFTableSectionDescription.h"
#import "OFUnlockedAchievement.h"
#import "OFAchievement.h"
#import "OFSocialNotificationApi.h"
#import "OFDelegateChained.h"
#import "OFSendSocialNotificationController.h"

//static OFSendSocialNotificationDelegate* sharedDelegate;

@implementation OFSocialNotificationService (Private)

+ (BOOL)canReceiveCallbacksNow
{
	return true;
}

+ (void)sendSocialNotification:(OFSocialNotification*)socialNotification onSuccess:(OFDelegate const&)onSuccess onFailure:(OFDelegate const&)onFailure
{	
	OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
	OFRetainedPtr<NSString> msg = socialNotification.text;
	OFRetainedPtr<NSString> image_type = socialNotification.imageType;
	OFRetainedPtr<NSString> image_name_or_id = socialNotification.imageIdentifier;
	OFRetainedPtr<NSString> url = socialNotification.url;
	params->io("msg", msg);
	params->io("image_type", image_type);
	
	for(uint i = 0; i < [socialNotification.sendToNetworks count]; i++)
	{
		NSNumber* typeNumber = [socialNotification.sendToNetworks objectAtIndex:i];
		switch([typeNumber intValue])
		{
			case ESocialNetworkCellType_FACEBOOK:
			{
				params->io("networks[]", @"Fbconnect");			
			}
			break;
				
			case ESocialNetworkCellType_TWITTER:
			{
				params->io("networks[]", @"Twitter");
			}
			break;
		};
	}
	
	if([socialNotification.imageType isEqualToString:@"notification_images"])
	{
		params->io("image_name", image_name_or_id);
	}
	else
	{
		params->io("image_id", image_name_or_id);
	}
	params->io("url", url);
	
	OFNotificationData* noticeData = [OFNotificationData 
		dataWithText:[NSString stringWithFormat:@"Published Game Event: %@", socialNotification.text] 
		andCategory:kNotificationCategorySocialNotification
		andType:kNotificationTypeSubmitting];
	noticeData.notificationUserData = socialNotification;
	
	[[self sharedInstance]
	 postAction:@"notifications.xml"
	 withParameters:params
	 withSuccess:onSuccess
	 withFailure:onFailure
	 withRequestType:OFActionRequestBackground
	 withNotice:noticeData];
}

@end
