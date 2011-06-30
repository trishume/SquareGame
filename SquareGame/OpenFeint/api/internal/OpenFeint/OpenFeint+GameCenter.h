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

#import "OpenFeint.h"
extern NSString* OFNSNotificationGameCenterFriendsLoaded;
extern NSString* OFNSNotificationGameCenterScoresLoaded;

@class OFPaginatedSeries;

@interface OpenFeint (GameCenter)
+(BOOL) isUsingGameCenter;
+(BOOL) isLoggedIntoGameCenter;
+(void) initializeGameCenter;
+(void) releaseGameCenter;


+(NSArray*) getGameCenterFriends;
+(void) loadGameCenterScores:(NSString*) category;
+(NSArray*) getGameCenterScores:(NSInteger) timeScope; //assumes loadGameCenterScores called first
+(NSString*) getGameCenterAchievementId:(NSString*)openFeintAchievementId;
+(NSString*) getGameCenterLeaderboardCategory:(NSString*)openFeintLeaderboardId;
+(OFPaginatedSeries*) combinedGameCenterForLeaderboardId:(NSString*)leaderboardId timeScope:(NSUInteger) scope globals:(OFPaginatedSeries*) openFeintGlobal friends:(OFPaginatedSeries*) openFeintFriends;
+(BOOL) isGameCenterScoreLoadedForLeaderboardId:(NSString*)leaderboardId timeScope:(NSUInteger) scope;

//block based interface
#ifdef __IPHONE_4_1
+(void) loadGameCenterPlayerName:(NSString*)gameCenterId withHandler:(void(^)(NSString* player, NSError* error))handler;
+(void) submitAchievementToGameCenter:(NSString*)gameCenterAchievementId withPercentComplete:(double)percentComplete withHandler:(void(^)(NSError*))error;
+(NSDate*) submitScoreToGameCenter:(long long) score category:(NSString*) category withHandler:(void(^)(NSError*))handler;
#endif
@end
