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

#import "OFNotificationStatus.h"
@class MPOAuthAPIRequestLoader;
@class OFAchievement;
@class OFChallengeToUser;
@class OFNotificationData;
@class OFServerNotification;

@interface OFNotification : NSObject
{
	OFNotificationData* defaultBackgroundNotice;
	OFNotificationStatus* defaultStatus;
}

@property (nonatomic, retain) OFNotificationData* defaultBackgroundNotice;
@property (nonatomic, retain) OFNotificationStatus* defaultStatus;

+ (OFNotification*)sharedInstance;

- (void)showBackgroundNoticeForLoader:(MPOAuthAPIRequestLoader*)request withNotice:(OFNotificationData*)noticeData;
- (void)showBackgroundNotice:(OFNotificationData*)noticeData andStatus:(OFNotificationStatus*)status;
- (void)showAchievementNotice:(OFAchievement*)unlockedAchievement andPercentComplete:(double)percentComplete;
- (void)showChallengeNotice:(OFChallengeToUser*)challengeToUser;
- (void)showServerNotification:(OFServerNotification*)serverNotification;

- (void)setDefaultBackgroundNotice:(OFNotificationData*)noticeData andStatus:(OFNotificationStatus*)status;
- (void)showDefaultNotice;
- (void)clearDefaultNotice;


@end
