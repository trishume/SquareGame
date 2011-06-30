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
#import "OpenFeint.h"

@interface OpenFeint (Dashboard)
+ (void)launchDashboardWithListLeaderboardsPage;
+ (void)launchDashboardWithHighscorePage:(NSString*)leaderboardId;
+ (void)launchDashboardWithAchievementsPage;
+ (void)launchDashboardWithChallengesPage;
+ (void)launchDashboardWithFindFriendsPage;
+ (void)launchDashboardWithWhosPlayingPage;
+ (void)launchDashboardWithListGlobalChatRoomsPage;
+ (void)launchDashboardWithiPurchasePage:(NSString*)clientApplicationId;
+ (void)launchDashboardWithSwitchUserPage;
+ (void)launchDashboardWithForumsPage;
+ (void)launchDashboardWithInvitePage;
+ (void)launchDashboardWithSpecificInvite:(NSString*)inviteIdentifier;
+ (void)launchDashboardWithIMToUser:(OFUser*)user initialText:(NSString*)initialText;
+ (void)launchDashboardWithSocialNotificationWithPrepopulatedText:(NSString*)prepopulatedText originialMessage:(NSString*)originalMessage imageName:(NSString*)imageName linkedUrl:(NSString*)url;
@end

////////////////////////////////////////////////////////////
///
/// @type		NSString 
/// @behavior	Used make the intial dashboard tab the Current Game tab
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintDashBoardTabNowPlaying;

////////////////////////////////////////////////////////////
///
/// @type		NSString 
/// @behavior	Used make the intial dashboard tab the My Feint tab
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintDashBoardTabMyFeint;

////////////////////////////////////////////////////////////
///
/// @type		NSString 
/// @behavior	Used make the intial dashboard tab the Games tab
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintDashBoardTabGames;

////////////////////////////////////////////////////////////
///
/// @type		NSString 
/// @behavior	Achievements List controller
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintControllerAchievementsList;

////////////////////////////////////////////////////////////
///
/// @type		NSString 
/// @behavior	Leaderboard List controller
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintControllerLeaderboardsList;

////////////////////////////////////////////////////////////
///
/// @type		NSString 
/// @behavior	Challenges List controller
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintControllerChallengesList;

////////////////////////////////////////////////////////////
///
/// @type		NSString 
/// @behavior	Find Friends controller
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintControllerFindFriends;

////////////////////////////////////////////////////////////
///
/// @type		NSString 
/// @behavior	High Scores controller
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintControllerHighScores;


////////////////////////////////////////////////////////////
///
/// @type		NSString 
/// @behavior	Who's Playing controller
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintControllerWhosPlaying;
