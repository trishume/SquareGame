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

#import "OFTableControllerHelper.h"
#import "OFSocialNotificationService.h"
#import "OFSocialNotification.h"
#import "OFDelegate.h"

@class OFSendSocialNotificationCell;
@class OFSendSocialNotificationSubmitTextCell;
@class OFSocialNotification;
@protocol OFSendSocialNotificationControllerDelegate;
@protocol OFExtendedCredentialController;

@interface OFSendSocialNotificationController : OFTableControllerHelper 
{
	OFSendSocialNotificationCell* sendSocialNotificationCell[ESocialNetworkCellType_COUNT];
	BOOL initChecked[ESocialNetworkCellType_COUNT];
	OFSendSocialNotificationSubmitTextCell* submitTextCell;
	OFSocialNotification* notification;
    ESocialNetworkCellType onlyCheckNetwork;
	BOOL needCredentialsForNetwork[ESocialNetworkCellType_COUNT];
	int currentGettingCredentialForNetwork;
	UIViewController<OFExtendedCredentialController>* currentExtendedCredentialsController;
}

@property(nonatomic, retain) OFSendSocialNotificationSubmitTextCell* submitTextCell;
@property(nonatomic, retain) OFSocialNotification* notification;
@property(nonatomic, retain) UIViewController<OFExtendedCredentialController>* currentExtendedCredentialsController;

-(void)setPrepopulatedText:(NSString*)prepopulatedText andOriginalMessage:(NSString*)message;
-(void)setImageUrl:(NSString*)iconUrl defaultImage:(NSString*)defaultImage;

-(void)setImageName:(NSString*)imageName linkedUrl:(NSString*)url;
-(void)setImageType:(NSString*)imagetType imageId:(NSString*)imageId linkedUrl:(NSString*)url;
-(void)setDismissDashboardWhenSent:(BOOL)_dismissDashboard;
-(void)setUseNetwork:(ESocialNetworkCellType)type;
-(void)send;

-(void)activateSendButton;

-(void)dismiss;

@end
