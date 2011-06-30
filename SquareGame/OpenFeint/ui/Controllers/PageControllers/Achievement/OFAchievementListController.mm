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
#import "OFAchievementListController.h"
#import "OFResourceControllerMap.h"
#import "OFControllerLoader.h"
#import "OFProfileController.h"
#import "OFAchievementService.h"
#import "OFAchievement.h"
#import "OFPlayedGame.h"
#import "OFUserGameStat.h"
#import "OpenFeint+Settings.h"
#import "OpenFeint+UserOptions.h"
#import "OFDefaultLeadingCell.h"
#import "OFUser.h"
#import "OFApplicationDescriptionController.h"
#import "OFTableSequenceControllerHelper+Overridables.h"
#import "OFTableSectionDescription.h"

@implementation OFAchievementListController

@synthesize applicationName, applicationId, applicationIconUrl, doesUserHaveApplication, achievementProgressionListLeading;

- (BOOL)isComparingToOtherUser
{
	return ([self getPageComparisonUser].resourceId &&
			![[self getPageComparisonUser].resourceId isEqualToString:@""] &&
			![[self getPageComparisonUser].resourceId isEqualToString:[OpenFeint lastLoggedInUserId]]);
}

- (void)dealloc
{
	self.applicationName = nil;
	self.applicationId = nil;
	self.applicationIconUrl = nil;
	self.achievementProgressionListLeading = nil;
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)populateResourceMap:(OFResourceControllerMap*)resourceMap
{
  //can't do it here,checkout out postPushAchievementListController.  We need information about the nav controller to do this properly.
}

- (OFService*)getService
{
	return [OFAchievementService sharedInstance];
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	if(self.achievementProgressionListLeading == cell)
	{
		//Currently the only cell resource that is nil is the static cell to share achievements
		[self.navigationController pushViewController:OFControllerLoader::load(@"SelectAchievementToShare") animated:YES];
	}
}

- (NSString*)getNoDataFoundMessage
{
	return [NSString stringWithFormat:OFLOCALSTRING(@"There are no achievements for %@"), applicationName];
}

- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{
	if([self isComparingToOtherUser])
	{
		//get compared to user info
		[OFAchievementService getAchievementsForApplication:applicationId 
											 comparedToUser:[self getPageComparisonUser].resourceId
													   page:oneBasedPageNumber
												  onSuccess:success 
												  onFailure:failure];
	}
	else if (![applicationId isEqualToString:[[OpenFeint localGameProfileInfo] resourceId]])
	{
		[OFAchievementService getAchievementsForApplication:applicationId 
											 comparedToUser:nil
													   page:oneBasedPageNumber
												  onSuccess:success 
												  onFailure:failure];
	}
	else
	{
		//Don't make a server call, if its the local game fwe have the achievement information locally.
		success.invoke([OFPaginatedSeries paginatedSeriesFromArray:[OFAchievement achievements]]);
	}

}

- (void)doIndexActionOnSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{	
	[self doIndexActionWithPage:1 onSuccess:success onFailure:failure];
}

- (void)_onDataLoaded:(OFPaginatedSeries*)resources isIncremental:(BOOL)isIncremental
{	
	if([self isComparingToOtherUser])
	{
		[super _onDataLoaded:resources isIncremental:isIncremental];
	}
	else
	{
		NSArray* achievements = resources.objects;
		uint totalAchievementCount = [achievements count];
		uint unlockedAchievementCount = 0;
		for(uint i = 0; i < [achievements count]; i++)
		{
			OFAchievement* achievement = [achievements objectAtIndex:i];
			if(achievement.percentComplete == 100.0)
			{
				unlockedAchievementCount++;
			}
		}
		
		OFTableSectionDescription* mainAchievementTableSection = [OFTableSectionDescription sectionWithTitle:[NSString stringWithFormat:@"%d/%d Achievements Unlocked", unlockedAchievementCount, totalAchievementCount] andPage:resources];
		
		OFPaginatedSeries* series = nil;

		if(unlockedAchievementCount > 0 && [OpenFeint isOnline])
		{
			//Add a leading section for the "share" button if you have any unlocked achievements and you are online
			NSMutableArray* tableDescriptions = [[[NSMutableArray alloc] init] autorelease];
			OFTableSectionDescription* leadingTableSection = nil;
			
			self.achievementProgressionListLeading = (OFTableCellHelper*)OFControllerLoader::loadCell(@"AchievementProgressionListLeading");
			leadingTableSection = [OFTableSectionDescription sectionWithTitle:@"" andStaticCells:[NSMutableArray arrayWithObject:achievementProgressionListLeading]];
			
			[tableDescriptions addObject:leadingTableSection];
			[tableDescriptions addObject:mainAchievementTableSection];
			
			series = [OFPaginatedSeries paginatedSeriesFromArray:tableDescriptions];
		}
		else
		{
			//Just stick the achievements in there.
			series = [OFPaginatedSeries paginatedSeriesWithObject:mainAchievementTableSection];
		}
		
		[super _onDataLoaded:series isIncremental:isIncremental];
	}
}

- (bool)usePlainTableSectionHeaders
{
	if([self isComparingToOtherUser])
	{
		return [super usePlainTableSectionHeaders];
	}
	else
	{
		return true;
	}
}

- (void)populateContextualDataFromPlayedGame:(OFPlayedGame*)playedGame
{
	self.applicationName = playedGame.name;
	self.applicationId = playedGame.clientApplicationId;
	self.applicationIconUrl = playedGame.iconUrl;
	for (OFUserGameStat* gameStat in playedGame.userGameStats)
	{
		if ([gameStat.userId isEqualToString:[OpenFeint lastLoggedInUserId]])
		{
			self.doesUserHaveApplication = gameStat.userHasGame;
		}
	}
}

- (void)postPushAchievementListController
{	
	if([self isComparingToOtherUser])
	{
		//We are comparing to another user, use the comparision cells
		mResourceMap.get()->addResource([OFAchievement class], @"AchievementCompareList");
	}
	else
	{
		//We are not comparing.
		mResourceMap.get()->addResource([OFAchievement class], @"AchievementProgressionList");
	}
}

- (BOOL)supportsComparison;
{
	return YES;
}

- (void)profileUsersChanged:(OFUser*)contextUser comparedToUser:(OFUser*)comparedToUser
{
	[self reloadDataFromServer];
}

- (void)onLeadingCellWasLoaded:(OFTableCellHelper*)leadingCell forSection:(OFTableSectionDescription*)section
{
	if([self isComparingToOtherUser])
	{
		OFDefaultLeadingCell* defaultCell = (OFDefaultLeadingCell*)leadingCell;
		[defaultCell enableLeftIconViewWithImageUrl:applicationIconUrl andDefaultImage:@"OFDefaultApplicationIcon.png"];
		defaultCell.headerLabel.text = applicationName;
		[defaultCell populateRightIconsAsComparison:[self getPageComparisonUser]];
	}
}

- (NSString*)getLeadingCellControllerNameForSection:(OFTableSectionDescription*)section
{
	if([self isComparingToOtherUser])
	{
		return @"DefaultLeading";
	}
	else
	{
		return nil;
	}
}

- (NSString*)getTableHeaderControllerName
{
	return nil;
}

@end
