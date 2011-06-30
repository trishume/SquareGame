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

#import "OFSelectAchievementToShareController.h"
#import "OFResourceControllerMap.h"
#import "OFControllerLoader.h"
#import "OFAchievement.h"
#import "OFTableSequenceControllerHelper+Overridables.h"
#import "OFSendSocialNotificationController.h"
#import "OpenFeint+Settings.h"
#import "OFAchievementService.h"
#import "OFSocialNotificationApi.h"
#import "OpenFeint+UserOptions.h"
#import "OFGameProfilePageInfo.h"
#import "OpenFeint+Private.h"

@implementation OFSelectAchievementToShareController


- (void)dealloc
{
	[super dealloc];
}

- (void)populateResourceMap:(OFResourceControllerMap*)resourceMap
{
	mResourceMap.get()->addResource([OFAchievement class], @"AchievementProgressionList");
}

- (OFService*)getService
{
	return nil;
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	//Push send social notification controller
	OFAchievement* achievement = (OFAchievement*)cellResource;
	OFSendSocialNotificationController* controller = (OFSendSocialNotificationController*)OFControllerLoader::load(@"SendSocialNotification");
	
	//try to get overridden text from dev
	NSString* prepopulatedText = nil;
	NSString* originalMessage = nil;
	id submitTextDelegate =  [OpenFeint getBragDelegate];
	if(submitTextDelegate && [submitTextDelegate respondsToSelector:@selector(bragAboutAchievement:overridePrepopulatedText:overrideOriginalMessage:)])
	{
		[submitTextDelegate bragAboutAchievement:achievement overridePrepopulatedText:prepopulatedText overrideOriginalMessage:originalMessage];
	}
	
	if(!prepopulatedText)
	{
		prepopulatedText = [NSString stringWithFormat:@"I unlocked the achievement %@ in %@.", achievement.title, [OpenFeint applicationDisplayName]];
	}
	
	[controller setPrepopulatedText:prepopulatedText andOriginalMessage:originalMessage];
	[controller setImageType:@"achievement_definitions" imageId:achievement.resourceId linkedUrl:[OFAchievementService sharedInstance].mCustomUrlWithSocialNotification];
	[controller setImageUrl:achievement.iconUrl defaultImage:@"OFUnlockedAchievementIcon.png"];
	[self.navigationController pushViewController:controller animated:YES];
}

- (void)onLeadingCellWasClickedForSection:(OFTableSectionDescription*)section
{
	//Push send social notification controller
	OFSendSocialNotificationController* controller = (OFSendSocialNotificationController*)OFControllerLoader::load(@"SendSocialNotification");
	
	//try to get overridden text from dev
	NSString* prepopulatedText = nil;
	NSString* originalMessage = nil;
	id submitTextDelegate = [OpenFeint getBragDelegate];
	if(submitTextDelegate && [submitTextDelegate respondsToSelector:@selector(bragAboutAllAchievementsWithTotal:unlockedAmount:overridePrepopulatedText:overrideOriginalMessage:)])
	{
		[submitTextDelegate bragAboutAllAchievementsWithTotal:totalAchievementCount unlockedAmount:unlockedAchievementCount overridePrepopulatedText:prepopulatedText overrideOriginalMessage:originalMessage];
	}
	
	if(!prepopulatedText)
	{
		prepopulatedText = [NSString stringWithFormat:@"I unlocked %d out of %d achievements in %@.", unlockedAchievementCount, totalAchievementCount, [OpenFeint applicationDisplayName]];
	}
	
	[controller setPrepopulatedText:prepopulatedText andOriginalMessage:originalMessage];
	[controller setImageType:@"achievement_definitions" imageId:@"game_icon" linkedUrl:nil];
	[controller setImageUrl:[OpenFeint localGameProfileInfo].iconUrl defaultImage:@"OFUnlockedAchievementIcon.png"];
	[self.navigationController pushViewController:controller animated:YES];
}

- (NSString*)getNoDataFoundMessage
{
	return [NSString stringWithFormat:OFLOCALSTRING(@"You should not have arrived here with no achievements unlocked.")];
}

- (void)doIndexActionOnSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{
	//Populate the cells with only unlocked achievements
	NSMutableArray* unlockedAchievements = [[[NSMutableArray alloc] init] autorelease];
	
	NSArray* achievements = [OFAchievement achievements];
	totalAchievementCount = [achievements count];
	unlockedAchievementCount = 0;
	for(uint i = 0; i < [achievements count]; i++)
	{
		OFAchievement* achievement = [achievements objectAtIndex:i];
		if(achievement.percentComplete == 100.0)
		{
			[unlockedAchievements addObject:achievement];
			unlockedAchievementCount++;
		}
	}
	
	success.invoke([OFPaginatedSeries paginatedSeriesFromArray:unlockedAchievements]);
}

- (void)onLeadingCellWasLoaded:(OFTableCellHelper*)leadingCell forSection:(OFTableSectionDescription*)section
{
}

- (NSString*)getLeadingCellControllerNameForSection:(OFTableSectionDescription*)section
{
	return @"SelectAchievementToShareLeading";
}

- (NSString*)getTableHeaderControllerName
{
	return nil;
}
- (void)configureCell:(OFTableCellHelper*)_cell asLeading:(BOOL)_isLeading asTrailing:(BOOL)_isTrailing asOdd:(BOOL)_isOdd
{
	[super configureCell:_cell asLeading:_isLeading asTrailing:_isTrailing asOdd:_isOdd];
	 
	[_cell setUserInteractionEnabled:YES];
}

@end
