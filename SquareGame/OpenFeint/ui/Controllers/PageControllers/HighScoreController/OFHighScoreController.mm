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
#import "OFHighScoreController.h"
#import "OFResourceControllerMap.h"
#import "OFHighScore.h"
#import "OFHighScoreService.h"
#import "OFLeaderboard.h"
#import "OFTableSequenceControllerHelper+Overridables.h"
#import "OFUser.h"
#import "OFProfileController.h"
#import "OFControllerLoader.h"
#import "OpenFeint.h"
#import "OpenFeint+Private.h"
#import "OFTabbedPageHeaderController.h"
#import "OFDefaultLeadingCell.h"
#import "OFTableSectionDescription.h"
#import "OFGameProfilePageInfo.h"
#import "OpenFeint+UserOptions.h"
#import "OFPlainMessageTrailingCell.h"
#import "OFImageLoader.h"
#import "OFHighScoreMapViewController.h"
#import "OFDelegatesContainer.h"
#import "OpenFeint+GameCenter.h"
#import "OFFramedNavigationController.h"
#import "OFSendSocialNotificationController.h"
#import "OpenFeint+Settings.h"
#import "OFSocialNotificationApi.h"

//matches the game center definitions
namespace {
    enum {
        timeScopeToday = 0,
        timeScopeWeek,
        timeScopeAllTime
    };
}

@interface OFHighScoreController() 

//delegates for sub loads
-(void)onLoadFailed;
-(void)onFriendsLoadSuccess:(OFPaginatedSeries*)resources;
-(void)onGlobalLoadSuccess:(OFPaginatedSeries*)resources;
-(void)checkLoadFinished;

@property (nonatomic, retain) NSString* noDataFoundMessage;
@property (nonatomic, retain) OFPaginatedSeries* friendResources;  
@property (nonatomic, retain) OFPaginatedSeries* globalResources; 
@property (nonatomic) NSUInteger timeScope;
@property (nonatomic) BOOL loadingInProcess;
@property (nonatomic) BOOL gameCenterLoadFinished;
@end

@implementation OFHighScoreController

@synthesize leaderboard;
@synthesize noDataFoundMessage;
@synthesize gameProfileInfo;
@synthesize friendResources;
@synthesize globalResources;
@synthesize timeScope;
@synthesize loadingInProcess;
@synthesize gameCenterLoadFinished;

-(void)clickedMap 
{
	OFHighScoreMapViewController* mapViewController = (OFHighScoreMapViewController*)OFControllerLoader::load(@"Mapping");
	[mapViewController setLeaderboard:leaderboard.resourceId];
	[mapViewController getScores];
	[self.navigationController pushViewController:mapViewController animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.timeScope = timeScopeAllTime;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameCenterScoresLoaded:) name:OFNSNotificationGameCenterScoresLoaded object:nil];

}
-(void) viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.title = leaderboard.name;
    [OpenFeint loadGameCenterScores:leaderboard.resourceId];
    
	OFUserDistanceUnitType unit = [OpenFeint userDistanceUnit];	
	if ([OpenFeint isOnline] && unit != kDistanceUnitNotAllowed && [OpenFeint getUserLocation])
	{
		UIBarButtonItem* button = [[UIBarButtonItem alloc] initWithImage:[OFImageLoader loadImage:@"OFMapButton.png"] style:UIBarButtonItemStylePlain target:self action:@selector(clickedMap)];
		self.navigationItem.rightBarButtonItem = button;
	}
	
	if (![OpenFeint isOnline])
	{
		self.noDataFoundMessage = [NSString stringWithFormat:OFLOCALSTRING(@"All of your high scores for %@ will show up here. You have not posted any yet."), leaderboard.name];
	}
}


- (void)populateResourceMap:(OFResourceControllerMap*)resourceMap
{
	resourceMap->addResource([OFHighScore class], @"HighScore");
}

- (OFService*)getService
{
	return [OFHighScoreService sharedInstance];
}

-(void)setTimeScopingAll 
{
	self.noDataFoundMessage = [NSString stringWithFormat:OFLOCALSTRING(@"No one has posted high scores for %@ yet."), leaderboard.name];
	[self showLoadingScreen];    
    self.timeScope = timeScopeAllTime;
    [self doIndexActionOnSuccess:[self getOnSuccessDelegate] onFailure:[self getOnFailureDelegate]];
}

-(void)setTimeScopingDay
{
	self.noDataFoundMessage = [NSString stringWithFormat:OFLOCALSTRING(@"No one has posted high scores for %@ yet."), leaderboard.name];
	[self showLoadingScreen];    
    self.timeScope = timeScopeToday;
    [self doIndexActionOnSuccess:[self getOnSuccessDelegate] onFailure:[self getOnFailureDelegate]];
}

-(void)setTimeScopingWeek
{
	self.noDataFoundMessage = [NSString stringWithFormat:OFLOCALSTRING(@"No one has posted high scores for %@ yet."), leaderboard.name];
	[self showLoadingScreen];    
    self.timeScope = timeScopeWeek;
    [self doIndexActionOnSuccess:[self getOnSuccessDelegate] onFailure:[self getOnFailureDelegate]];
}

-(void)nullyMethod
{
}

- (void)doIndexActionOnSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{
	if ([OpenFeint isOnline])
	{
        if(self.loadingInProcess) return;
        self.friendResources = nil;
        self.globalResources = nil;
        
        const static NSUInteger timeScopeConversion[3] = { 1, 7, 0 };   //Today, Week, AllTime
        
        [OFHighScoreService getPage:1 
                     forLeaderboard:leaderboard.resourceId 
                   comparedToUserId:[self getPageComparisonUser].resourceId
                        friendsOnly:YES 
                           silently:NO
                          timeScope:timeScopeConversion[self.timeScope]
                          onSuccess:OFDelegate(self, @selector(onFriendsLoadSuccess:))
                          onFailure:OFDelegate(self, @selector(onLoadFailed))];
        
        [OFHighScoreService getPage:1 
                     forLeaderboard:leaderboard.resourceId 
                   comparedToUserId:[self getPageComparisonUser].resourceId
                        friendsOnly:NO 
                           silently:NO
                          timeScope:timeScopeConversion[self.timeScope]
                          onSuccess:OFDelegate(self, @selector(onGlobalLoadSuccess:))
                          onFailure:OFDelegate(self, @selector(onLoadFailed))];
        
        self.loadingInProcess = YES;
	} else {
		[OFHighScoreService getLocalHighScores:leaderboard.resourceId onSuccess:success onFailure:failure];
	}
}


-(void)checkLoadFinished 
{
    //check all the possible pieces
    if(self.globalResources != nil && self.friendResources != nil && 
       [OpenFeint isGameCenterScoreLoadedForLeaderboardId:self.leaderboard.resourceId timeScope:self.timeScope])
    {
        [self hideLoadingScreen];
        self.loadingInProcess = NO;
        [super _onDataLoadedWrapper:[OpenFeint combinedGameCenterForLeaderboardId:leaderboard.resourceId timeScope:self.timeScope globals:self.globalResources friends:self.friendResources] 
                      isIncremental:NO];    
    }

    
}

-(void)onLoadFailed 
{
    [self hideLoadingScreen];
    self.loadingInProcess = NO;
    self.friendResources = nil;
    self.globalResources = nil;
    //hide loading bar
}

//delegates for sub loads
#pragma mark SubLoad checks
-(void) gameCenterScoresLoaded:(NSDictionary*) data 
{
    [self checkLoadFinished];
}

-(void)onFriendsLoadSuccess:(OFPaginatedSeries*)resources 
{
    self.friendResources = resources;
    [self checkLoadFinished];
}

-(void)onGlobalLoadSuccess:(OFPaginatedSeries*)resources 
{
    self.globalResources = resources;
    [self checkLoadFinished];
}

#pragma mark --
- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{
	OFTabbedPageHeaderController* header = (OFTabbedPageHeaderController*)tableHeader;
	header.callbackTarget = self;
	if ([OpenFeint isOnline])
	{
		if (![OpenFeint isInLandscapeMode])
		{
			header.tabBar.textAlignment = UITextAlignmentLeft;
			header.tabBar.labelPadding = CGRectMake(28, 0, 0, 0);
		}

		[header addTab:OFLOCALSTRING(@"All Time") andSelectedCallback:@selector(setTimeScopingAll)];
		[header addTab:OFLOCALSTRING(@"Today") andSelectedCallback:@selector(setTimeScopingDay)];
		[header addTab:OFLOCALSTRING(@"This week") andSelectedCallback:@selector(setTimeScopingWeek)];
	} else {
	    [header addTab:OFLOCALSTRING(@"My Scores") andSelectedCallback:@selector(nullyMethod)];
	}
}

-(bool)allowPagination 
{
    return NO;
}

- (bool)usePlainTableSectionHeaders
{
	return true;
}

- (NSString*)getTableHeaderControllerName
{
	return @"TabbedPageHeader";
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFHighScore class]] && [OpenFeint isOnline])
	{
		OFHighScore* highScoreResource = (OFHighScore*)cellResource;
        if(highScoreResource.user)
		{
            [OFProfileController showProfileForUser:highScoreResource.user];
		}
		else 
		{
			[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
		}

	}
}

- (NSString*)getNoDataFoundMessage
{
	return noDataFoundMessage;      
}

- (void)dealloc
{
    self.globalResources = nil;
    self.friendResources = nil;
    
	self.noDataFoundMessage = nil;
	self.leaderboard = nil;
	self.gameProfileInfo = nil;
	[super dealloc];
}

- (void)downloadBlobForHighScore:(OFHighScore*)highScore
{
	if ([highScore hasBlob])
	{
		[self showLoadingScreen];
		OFDelegate success(self, @selector(onBlobDownloadedForHighScore:));
		OFDelegate failure(self, @selector(onBlobFailedDownloading));
		[OFHighScoreService downloadBlobForHighScore:highScore onSuccess:success onFailure:failure];
	}
}

- (void)onBlobDownloadedForHighScore:(OFHighScore*)highScore
{
	[self hideLoadingScreen];
	id ofDelegate = [OpenFeint getDelegate];
	OF_OPTIONALLY_INVOKE_DELEGATE_WITH_TWO_PARAMETERS(ofDelegate, userDownloadedBlob:forHighScore:, (highScore.blob), highScore);
}

- (void)onBlobFailedDownloading
{
	[self hideLoadingScreen];
	[[[[UIAlertView alloc] 
	   initWithTitle:OFLOCALSTRING(@"Error!") 
	   message:OFLOCALSTRING(@"There was a problem downloading the data for this high score. Please try again later.") 
	   delegate:nil 
	   cancelButtonTitle:OFLOCALSTRING(@"OK") 
	   otherButtonTitles:nil] autorelease] show];
}

- (NSString*)getTrailingCellControllerNameForSection:(OFTableSectionDescription*)section
{
	if([section.title isEqualToString:@"My Score"])
	{
		OFHighScore* myScore = [section.page.objects objectAtIndex:0];
		if(myScore.rank != -1)
		{
			return @"ShareHighScore";
		}
	}
	
	return nil;
}

- (void)onTrailingCellWasClickedForSection:(OFTableSectionDescription*)section
{
	if([section.title isEqual:@"My Score"])
	{
		OFHighScore* score = [section.page.objects objectAtIndex:0];
		OFSendSocialNotificationController* controller = (OFSendSocialNotificationController*)OFControllerLoader::load(@"SendSocialNotification");
		
		NSString* prepopulatedText = nil;
		NSString* originalMessage = nil;
		id submitTextDelegate =  [OpenFeint getBragDelegate];
		if(submitTextDelegate && [submitTextDelegate respondsToSelector:@selector(bragAboutHighScore:onLeaderboard:overridePrepopulatedText:overrideOriginalMessage:)])
		{
			[submitTextDelegate bragAboutHighScore:score onLeaderboard:leaderboard overridePrepopulatedText:prepopulatedText overrideOriginalMessage:originalMessage];
		}
		
		if(!prepopulatedText)
		{
			NSString* scoreText = score.displayText ? score.displayText : [NSString stringWithFormat:@"%d", score.score]; 
			prepopulatedText = [NSString stringWithFormat:@"I scored %@ on the %@ leaderboard in %@.", scoreText, leaderboard.name, [OpenFeint applicationDisplayName]]; 
		}

		[controller setPrepopulatedText:prepopulatedText andOriginalMessage:originalMessage];
		[controller setImageType:@"achievement_definitions" imageId:@"game_icon" linkedUrl:nil];  //This is the only way to get the game icon in a social notification.  See technical debt task #814
		[controller setImageUrl:[OpenFeint localGameProfileInfo].iconUrl defaultImage:nil];
		[self.navigationController pushViewController:controller animated:YES];
	}
}

@end
