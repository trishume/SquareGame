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

#import "OFDependencies.h"
#import "OFAchievement.h"
#import "OFAchievementService.h"
#import "OFService+Private.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OpenFeint+Private.h"
#import "OFReachability.h"
#import "OpenFeint+UserOptions.h"
#import "OFAchievementService+Private.h"
#import "OFNotification.h"
#import "OFUnlockedAchievement.h"
#import "OFAchievement.h"
#import "OpenFeint+Settings.h"
#import "OFSocialNotificationService+Private.h"
#import "OFAchievementListController.h"
#import "OFControllerLoader.h"
#import "OFDelegateChained.h"
#import "OpenFeint+Dashboard.h"
#import "OpenFeint+GameCenter.h"
#import "OFGameCenterAchievement.h"

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFAchievementService)



@implementation OFAchievementService

@synthesize mCustomUrlWithSocialNotification, onlySubmitToGameCenterDeferedAchievementIds, onlySubmitToGameCenterDeferedAchievementPercentCompletes;

OPENFEINT_DEFINE_SERVICE(OFAchievementService);

- (void) dealloc
{
	OFSafeRelease(mCustomUrlWithSocialNotification);
	OFSafeRelease(onlySubmitToGameCenterDeferedAchievementIds);
	OFSafeRelease(onlySubmitToGameCenterDeferedAchievementPercentCompletes);

	[super dealloc];
}

- (void) populateKnownResources:(OFResourceNameMap*)namedResources
{
	namedResources->addResource([OFAchievement getResourceName], [OFAchievement class]);
	namedResources->addResource([OFUnlockedAchievement getResourceName], [OFUnlockedAchievement class]);
}

+ (void) getAchievementsForApplication:(NSString*)applicationId 
						comparedToUser:(NSString*)comparedToUserId 
								  page:(NSUInteger)pageIndex
							 onSuccess:(OFDelegate const&)onSuccess 
							 onFailure:(OFDelegate const&)onFailure
{
	[OFAchievementService getAchievementsForApplication:applicationId comparedToUser:comparedToUserId page:pageIndex silently:NO onSuccess:onSuccess onFailure:onFailure];
}
							 
+ (void) getAchievementsForApplication:(NSString*)applicationId 
						comparedToUser:(NSString*)comparedToUserId 
								  page:(NSUInteger)pageIndex
							  silently:(BOOL)silently
							 onSuccess:(OFDelegate const&)onSuccess 
							 onFailure:(OFDelegate const&)onFailure
{
	if ([OpenFeint isOnline])
	{
		OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
		if ([applicationId length] > 0 && ![applicationId isEqualToString:@"@me"])
		{
			params->io("by_app", applicationId);
		}
		
		if (comparedToUserId)
		{
			params->io("compared_to_user_id", comparedToUserId);
		}
		
		params->io("page", pageIndex);
		int per_page = 25;
		params->io("per_page", per_page);
		
		bool kGetUnlockedInfo = true;
		params->io("get_unlocked_info", kGetUnlockedInfo);
		
		[[self sharedInstance] 
		 getAction:@"client_applications/@me/achievement_definitions.xml"
		 withParameters:params
		 withSuccess:onSuccess
		 withFailure:onFailure
		 withRequestType:(silently ? OFActionRequestSilent : OFActionRequestForeground)
		 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded Achievement Information")]];
	} else {
		[OFAchievementService getAchievementsLocal:onSuccess onFailure:onFailure];
	}
}

- (void) onAchievementUpdated:(OFPaginatedSeries*)page nextCall:(OFDelegateChained*)nextCall duringSync:(BOOL)duringSync fromBatch:(BOOL) fromBatch
{
    [OFAchievementService syncOfflineAchievements:page];
    [OFAchievementService finishAchievementsPage:page duringSync:duringSync fromBatch:fromBatch];
}

+ (OFRequestHandle*) updateAchievement:(NSString*)achievementId andPercentComplete:(double)percentComplete andShowNotification:(BOOL)showUpdateNotification
{
	return [OFAchievementService updateAchievement:achievementId andPercentComplete:percentComplete andShowNotification:showUpdateNotification onSuccess:OFDelegate() onFailure:OFDelegate()];
}

+ (OFRequestHandle*) updateAchievement:(NSString*)achievementId andPercentComplete:(double)percentComplete andShowNotification:(BOOL)showUpdateNotification onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OFRequestHandle* handle = nil;
	
	percentComplete = MIN(percentComplete, 100.0);
	percentComplete = MAX(percentComplete, 0.0);
	
	BOOL stillNeedsToSubmitToGameCenter = NO;
    
    OFDelegate onGameCenterSuccess;
    OFDelegate onGameCenterFailure;
	
	if([OpenFeint hasUserApprovedFeint])
	{
		double currentPercentComplete = [self getPercentComplete:achievementId forUser:[OpenFeint lastLoggedInUserId]];
		//Don't allow percent complete to go down.
		if(currentPercentComplete >= percentComplete)
		{
			//invalid update.
			onFailure.invoke();
			return nil;
		}
		
		NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
		if ([lastLoggedInUser longLongValue] > 0)
		{
			[OFAchievementService localUpdateAchievement:achievementId forUser:lastLoggedInUser andPercentComplete:percentComplete];
			
			if(percentComplete == 100.0)
			{
				//"Batch" all non complete achievements to be submitted on next bootstrap for server performance.
				OFGameCenterAchievement* gcAchievement = [[OFGameCenterAchievement new] autorelease];
				gcAchievement.achievementIds = [NSArray arrayWithObject:achievementId];
				gcAchievement.percentsComplete = [NSArray arrayWithObject:[NSNumber numberWithFloat:percentComplete]];
				gcAchievement.batch = NO;
				gcAchievement.sync = NO;
				handle = [gcAchievement submitOnSuccess:OFDelegate() onFailure:OFDelegate()];
			}
			else 
			{
				//..but we still need to hit the gameCenter server and update it.
				stillNeedsToSubmitToGameCenter = YES;
			}

			if(showUpdateNotification)
			{
				OFAchievement* achievement = [OFAchievementService getAchievementLocalWithUnlockInfo:achievementId];
				[[OFNotification sharedInstance] showAchievementNotice:achievement andPercentComplete:percentComplete];
			}
            
            onSuccess.invoke();
		}
	}
	else if([OpenFeint isLoggedIntoGameCenter])
	{
		//Even if we are not logged into OpenFeint we need to update the game
		stillNeedsToSubmitToGameCenter = YES;
        onGameCenterSuccess = onSuccess;
        onGameCenterFailure = onFailure;
	}
	
	if(stillNeedsToSubmitToGameCenter)
	{
		NSArray* submitAchievementIds = [[[NSArray alloc] initWithObjects:achievementId, nil] autorelease];
		NSArray* submitPercents = [[[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:percentComplete], nil] autorelease];
		OFSubmitAchievementToGameCenterOnly* submitObject = [[[OFSubmitAchievementToGameCenterOnly alloc] init] autorelease];																
		[submitObject submitToGameCenterOnlyWithIds:submitAchievementIds andPercentCompletes:submitPercents onSuccess:onGameCenterSuccess onFailure:onGameCenterFailure];
	}
        
	return handle;
}

+ (void) queueUpdateAchievement:(NSString*)achievementId andPercentComplete:(double)percentComplete andShowNotification:(BOOL)showUpdateNotification
{
	percentComplete = MIN(percentComplete, 100.0);
	percentComplete = MAX(percentComplete, 0.0);
	
	double currentPercentComplete = [self getPercentComplete:achievementId forUser:[OpenFeint lastLoggedInUserId]];
	if([OpenFeint hasUserApprovedFeint])
	{
		//will try to send to gamecenter and OpenFeint later
		if(currentPercentComplete >= percentComplete)
		{
			//invalid update.
			return;
		}
		
		NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
		if ([lastLoggedInUser longLongValue] > 0)
		{
			[OFAchievementService localUpdateAchievement:achievementId forUser:lastLoggedInUser andPercentComplete:percentComplete];

			if(showUpdateNotification)
			{
				OFAchievement* achievement = [OFAchievementService getAchievement:achievementId];
				[[OFNotification sharedInstance] showAchievementNotice:achievement andPercentComplete:percentComplete];
			}
		}
	}
	else if([OpenFeint isLoggedIntoGameCenter])
	{
		//Logged into gameCenter, but has denied OpenFeint
		//Store off these in a special array to submit later.
		if(![OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementIds)
		{
			[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementIds = [[[NSMutableArray alloc] init] autorelease];
		}
		
		if(![OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementPercentCompletes)
		{
			[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementPercentCompletes = [[[NSMutableArray alloc] init] autorelease];
		}
		
		[[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementIds addObject:achievementId];
		[[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementPercentCompletes addObject:[NSNumber numberWithDouble:percentComplete]];
	}

}

+ (OFRequestHandle*) submitQueuedUpdateAchievements:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OFRequestHandle* handle = nil;
	
	if([OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementIds.count != 0 && [OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementPercentCompletes.count != 0 && [OpenFeint hasUserApprovedFeint])
	{
		//The user approved OpenFeint before the dev calls this (submit) and after we queued up some achievements to submit, so lets set these up as if OpenFeint was approved and let it happen.
		if ([[OpenFeint lastLoggedInUserId] longLongValue] > 0)
		{
			for(uint i = 0; i < [OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementIds.count && i < [OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementPercentCompletes.count; i++)
			{
				NSString* achievementId = [[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementIds objectAtIndex:i];
				double percentComplete = [(NSNumber*)[[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementPercentCompletes objectAtIndex:i] doubleValue];
				
				[OFAchievementService localUpdateAchievement:achievementId forUser:[OpenFeint lastLoggedInUserId] andPercentComplete:percentComplete];
			}
		}
	}
	
	if([OpenFeint hasUserApprovedFeint])
	{
		//Do the normal thing, try to send pending achievements to gamecenter and OpenFeint
		NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
		handle = [OFAchievementService sendPendingAchievements:lastLoggedInUser syncOnly:NO onSuccess:onSuccess onFailure:onFailure];
	}
	else if([OpenFeint isLoggedIntoGameCenter])
	{
		OFSubmitAchievementToGameCenterOnly* submitObject = [[[OFSubmitAchievementToGameCenterOnly alloc] init] autorelease];																
		[submitObject submitToGameCenterOnlyWithIds:[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementIds
								andPercentCompletes:[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementPercentCompletes
										  onSuccess:onSuccess 
										  onFailure:onFailure];
	}
	
	//Always should be done with these at this point, until the next queueing of defered achievements begins.
	[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementIds = nil;
	[OFAchievementService sharedInstance].onlySubmitToGameCenterDeferedAchievementPercentCompletes = nil;
	
	return handle;
}

@end
