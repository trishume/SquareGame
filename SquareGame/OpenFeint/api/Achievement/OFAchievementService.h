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

#import "OFService.h"
#import "OFNotificationView.h"
#import "OFPaginatedSeries.h"
#import "OFDelegateChained.h"

@interface OFAchievementService : OFService
{
    NSString* mCustomUrlWithSocialNotification;
	NSMutableArray* onlySubmitToGameCenterDeferedAchievementIds; //only used if the open feint has not been approved, but gameCenter is logged in
	NSMutableArray* onlySubmitToGameCenterDeferedAchievementPercentCompletes;
}

OPENFEINT_DECLARE_AS_SERVICE(OFAchievementService);

+ (void) getAchievementsForApplication:(NSString*)applicationId 
						comparedToUser:(NSString*)comparedToUserId 
								  page:(NSUInteger)pageIndex
							 onSuccess:(OFDelegate const&)onSuccess 
							 onFailure:(OFDelegate const&)onFailure;

+ (void) getAchievementsForApplication:(NSString*)applicationId 
						comparedToUser:(NSString*)comparedToUserId 
								  page:(NSUInteger)pageIndex
							  silently:(BOOL)silently
							 onSuccess:(OFDelegate const&)onSuccess 
							 onFailure:(OFDelegate const&)onFailure;

+ (OFRequestHandle*) updateAchievement:(NSString*)achievementId andPercentComplete:(double)percentComplete andShowNotification:(BOOL)showUpdateNotification;
+ (OFRequestHandle*) updateAchievement:(NSString*)achievementId andPercentComplete:(double)percentComplete andShowNotification:(BOOL)showUpdateNotification onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;

+ (void) queueUpdateAchievement:(NSString*)achievementId andPercentComplete:(double)percentComplete andShowNotification:(BOOL)showUpdateNotification;
+ (OFRequestHandle*) submitQueuedUpdateAchievements:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;

- (void) onAchievementUpdated:(OFPaginatedSeries*)page nextCall:(OFDelegateChained*)nextCall duringSync:(BOOL)duringSync fromBatch:(BOOL) fromBatch;


@property (nonatomic, retain) NSString* mCustomUrlWithSocialNotification;
@property (nonatomic, retain) NSMutableArray* onlySubmitToGameCenterDeferedAchievementIds;
@property (nonatomic, retain) NSMutableArray* onlySubmitToGameCenterDeferedAchievementPercentCompletes;

@end
