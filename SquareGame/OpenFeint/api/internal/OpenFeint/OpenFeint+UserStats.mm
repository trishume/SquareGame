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

#import "OpenFeint+UserStats.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"

static NSString* OpenFeintUserStatNumberOfGameSessions = @"OpenFeintUserStatNumberOfGameSessions";
static NSString* OpenFeintUserStatTotalGameSessionsDuration = @"OpenFeintUserStatTotalGameSessionsDuration";
static NSString* OpenFeintUserStatNumberOfDashboardLaunches = @"OpenFeintUserStatNumberOfDashboardLaunches";
static NSString* OpenFeintUserStatTotalDashboardDuration = @"OpenFeintUserStatTotalDashboardDuration";
static NSString* OpenFeintUserStatNumberOfOnlineGameSessions = @"OpenFeintUserStatNumberOfOnlineGameSessions";

static NSTimeInterval sessionActiveAt = 0;
static NSTimeInterval dashboardLaunchedAt = 0;
static NSTimeInterval sessionNotActiveAt = 0;
static BOOL suspendedDashboard = NO;

//static NSTimer* sessionTimer;
//static NSTimeInterval sessionTimeInterval = 1.0;

@implementation OpenFeint (UserStats)

+ (void)intiailizeUserStats
{
	//OFSafeRelease(sessionTimer);
	//sessionTimer = [[NSTimer scheduledTimerWithTimeInterval:sessionTimeInterval target:self selector:@selector(_incrementSessionTime) userInfo:nil repeats:YES] retain];

	[self sessionActive];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionActive) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionNotActive) name:UIApplicationWillResignActiveNotification object:nil];
	
}

+ (void)shutdownUserStats
{
	//[sessionTimer invalidate];
	//OFSafeRelease(sessionTimer);
}

/*
- (void) _incrementSessionTime
{
	[OpenFeint incrementTotalGameSessionsDurationBy:sessionTimeInterval];
}
*/
+ (void)setNumberOfGameSessions:(NSInteger)value
{
	[OpenFeint setUserStatValue:OpenFeintUserStatNumberOfGameSessions value:value];
}

+ (void)incrementNumberOfGameSessions
{
	[OpenFeint setNumberOfGameSessions:[OpenFeint numberOfGameSessions] + 1];
}

+ (NSInteger)numberOfGameSessions
{
	return [OpenFeint getUserStatValue:OpenFeintUserStatNumberOfGameSessions];
}

+ (void)setNumberOfOnlineGameSessions:(NSInteger)value
{
	[OpenFeint setUserStatValue:OpenFeintUserStatNumberOfOnlineGameSessions value:value];
}

+ (void)incrementNumberOfOnlineGameSessions
{
	[OpenFeint setNumberOfOnlineGameSessions:[OpenFeint numberOfOnlineGameSessions] + 1];
}

+ (NSInteger)numberOfOnlineGameSessions
{
	return [OpenFeint getUserStatValue:OpenFeintUserStatNumberOfOnlineGameSessions];
}

+ (void)setTotalGameSessionsDuration:(NSInteger)value
{
	[OpenFeint setUserStatValue:OpenFeintUserStatTotalGameSessionsDuration value:value];
}

+ (void)incrementTotalGameSessionsDurationBy:(NSInteger)value
{
	[OpenFeint setTotalGameSessionsDuration:[OpenFeint totalGameSessionsDuration] + value];
}

+ (NSInteger)totalGameSessionsDuration
{
	return [OpenFeint getUserStatValue:OpenFeintUserStatTotalGameSessionsDuration];
}

+ (void)setNumberOfDashboardLaunches:(NSInteger)value
{
	[OpenFeint setUserStatValue:OpenFeintUserStatNumberOfDashboardLaunches value:value];
}

+ (void)incrementNumberOfDashboardLaunches
{
	[OpenFeint setNumberOfDashboardLaunches:[OpenFeint numberOfDashboardLaunches] + 1];
}

+ (NSInteger)numberOfDashboardLaunches
{
	return [OpenFeint getUserStatValue:OpenFeintUserStatNumberOfDashboardLaunches];
}

+ (void)setTotalDashboardDuration:(NSInteger)value
{
	[OpenFeint setUserStatValue:OpenFeintUserStatTotalDashboardDuration value:value];
}

+ (void)incrementTotalDashboardDurationBy:(NSInteger)value
{
	[OpenFeint setTotalDashboardDuration:[OpenFeint totalDashboardDuration] + value];
}

+ (NSInteger)totalDashboardDuration
{
	return [OpenFeint getUserStatValue:OpenFeintUserStatTotalDashboardDuration];
}

+ (void)dashboardLaunched
{
	if ([OpenFeint hasUserApprovedFeint] && dashboardLaunchedAt == 0)
	{
		dashboardLaunchedAt = [[NSDate date] timeIntervalSince1970];
		[OpenFeint incrementNumberOfDashboardLaunches];
	}
}

+ (void)dashboardClosed
{
	if (dashboardLaunchedAt != 0)
	{
		[OpenFeint incrementTotalDashboardDurationBy:[[NSDate date] timeIntervalSince1970] - dashboardLaunchedAt];
		dashboardLaunchedAt = 0;
	}
}

+ (void)sessionNotActive
{
	sessionNotActiveAt = [[NSDate date] timeIntervalSince1970];
	[OpenFeint saveSessionDuration];
	suspendedDashboard = (dashboardLaunchedAt != 0);
	[OpenFeint dashboardClosed];
}

+ (void)sessionActive
{
	if (sessionActiveAt == 0) 
	{
		sessionActiveAt = [[NSDate date] timeIntervalSince1970];
		if ((sessionActiveAt - sessionNotActiveAt) >= 120) 
		{
			[OpenFeint incrementNumberOfGameSessions];
			if ([OpenFeint isOnline]) 
			{
				[OpenFeint incrementNumberOfOnlineGameSessions];
			}
		}
	}
	sessionNotActiveAt = 0;
	if (suspendedDashboard)
	{
		dashboardLaunchedAt = sessionActiveAt;
		suspendedDashboard = NO;
	}
}

+ (void)saveSessionDuration
{
	if (sessionActiveAt != 0) 
	{
		[OpenFeint incrementTotalGameSessionsDurationBy:sessionNotActiveAt - sessionActiveAt];
		sessionActiveAt = 0;
	}
}

+ (void)resetUserStats
{
	[OpenFeint setNumberOfGameSessions:0];
	[OpenFeint setNumberOfOnlineGameSessions:0];
	[OpenFeint setTotalGameSessionsDuration:0];
	[OpenFeint setTotalDashboardDuration:0];
	[OpenFeint setNumberOfDashboardLaunches:0];
}

+ (void) getUserStatsParams:(OFHttpNestedQueryStringWriter*)params
{
	params->io("[user_stats]total_dashboard_duration", [NSString stringWithFormat:@"%d", [OpenFeint totalDashboardDuration]]);
	params->io("[user_stats]total_dashboard_launches", [NSString stringWithFormat:@"%d", [OpenFeint numberOfDashboardLaunches]]);
	params->io("[user_stats]total_game_session_duration", [NSString stringWithFormat:@"%d", [OpenFeint totalGameSessionsDuration]]);
	params->io("[user_stats]total_game_sessions", [NSString stringWithFormat:@"%d", [OpenFeint numberOfGameSessions]]);
	params->io("[user_stats]total_online_game_sessions", [NSString stringWithFormat:@"%d", [OpenFeint numberOfOnlineGameSessions]]);
	params->io("[user_stats]version", @"2");
}

+ (NSString*)statUserKeyName:(NSString*)key
{
	return [NSString stringWithFormat:@"%@.%@", key, [OpenFeint lastLoggedInUserId]];
}

+ (void) setUserStatValue:(NSString*)key value:(NSInteger)value
{
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:[OpenFeint statUserKeyName:key]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSInteger) getUserStatValue:(NSString*)key
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:[OpenFeint statUserKeyName:key]];
}

@end
