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


#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+NSNotification.h"
#import "OFLinkSocialNetworksController.h"
#import "OFGameProfilePageInfo.h"
#import "OFUser.h"
#import "OFProvider.h"
#import "OFSettings.h"
#import "sha1.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFIntroNavigationController.h"
#import "OFAnnouncementService.h"
#import "OFDevice.h"
#import "OFParentalControls.h"

static NSString* OpenFeintUserOptionShouldAutomaticallyPromptLogin = @"OpenFeintSettingShouldAutomaticallyPromptLogin";
static NSString* OpenFeintUserOptionLastLoggedInUserHasSetName = @"OpenFeintSettingLastLoggedInUserHasSetName";
static NSString* OpenFeintUserOptionLastLoggedInUserHadSetNameOnBootup = @"OpenFeintSettingLastLoggedInUserHadSetNameOnBootup";
static NSString* OpenFeintUserOptionLastLoggedInUserNonDeviceCredential = @"OpenFeintSettingLastLoggedInUserHasNonDeviceCredential";

static NSString* OpenFeintUserOptionLastLoggedInUserHttpBasicCredential = @"OpenFeintSettingLastLoggedInUserHasHttpBasicCredential";

static NSString* OpenFeintUserOptionLastLoggedInUserFbconnectCredential = @"OpenFeintSettingLastLoggedInUserHasFbconnectCredential";

static NSString* OpenFeintUserOptionLastLoggedInUserTwitterCredential = @"OpenFeintSettingLastLoggedInUserHasTwitterCredential";

static NSString* OpenFeintUserOptionLastLoggedInUserIsNewUser = @"OpenFeintSettingsLastLoggedInUserIsNewUser";
static NSString* OpenFeintUserOptionUserFeintApproval = @"OpenFeintUserOptionUserFeintApproval";
static NSString* OpenFeintUserOptionSentDisapprovalToServer = @"OpenFeintUserOptionSentDisapprovalToServer";
static NSString* OpenFeintUserOptionClientApplicationId = @"OpenFeintSettingClientApplicationId";
static NSString* OpenFeintUserOptionInitialDashboardScreen = @"OpenFeintUserOptionInitialDashboardScreen";
static NSString* OpenFeintUserOptionInitialDashboardModalContentURL = @"OpenFeintUserOptionInitialDashboardModalContentURL";
static NSString* OpenFeintUserOptionClientApplicationIconUrl = @"OpenFeintSettingClientApplicationIconUrl";
static NSString* OpenFeintUserOptionUnviewedChallengesCount = @"OpenFeintSettingUnviewedChallengesCount";
static NSString* OpenFeintUserOptionUserHasRememberedChoiceForNotifications = @"OpenFeintUserOptionUserHasRememberedChoiceForNotifications";
static NSString* OpenFeintUserOptionUserAllowsNotifications = @"OpenFeintUserOptionUserAllowsNotifications";
static NSString* OpenFeintUserOptionLoggedInUserSharesOnlineStatus = @"OpenFeintUserOptionLoggedInUserSharesOnlineStatus";
static NSString* OpenFeintUserOptionLocalGameInfo = @"OpenFeintUserOptionLocalGameInfo";
static NSString* OpenFeintUserOptionLocalUser = @"OpenFeintUserOptionLocalUser";
static NSString* OpenFeintUserOptionPendingFriendsCount = @"OpenFeintSettingPendingFriendsCount";
static NSString* OpenFeintUserOptionUnreadIMCount = @"OpenFeintUserOptionUnreadIMCount";
static NSString* OpenFeintUserOptionUnreadPostCount = @"OpenFeintUserOptionUnreadPostCount";
static NSString* OpenFeintUserOptionUnreadInviteCount = @"OpenFeintUserOptionUnreadInviteCount";

static NSString* OpenFeintUserOptionShouldWarnOnIncompleteDelegates = @"OpenFeintUserOptionShouldWarnOnIncompleteDelegates";

static NSString* OpenFeintUserOptionDistanceUnit = @"OpenFeintUserOptionDistanceUnit";

static NSString* OpenFeintUserOptionLastAnnouncementDate = @"OpenFeintLastAnnouncementDate_UserID";
static NSString* OpenFeintUserOptionSuggestionsForumId = @"OpenFeintUserOptionSuggestionsForumId";
static NSString* OpenFeintUserOptionDoneWithGetTheMost = @"OpenFeintUserOptionDoneWithGetTheMost";

static NSString* OpenFeintUserOptionIsDisabled = @"OpenFeintUserOptionIsDisabled";

static NSString* OpenFeintUserSynchedWithGameCenterAchievements = @"OpenFeintUserSynchedWithGameCenterAchievements";
static NSString* OpenFeintUserSynchedWithGameCenterLeaderboards = @"OpenFeintUserSynchedWithGameCenterLeaderboards";

@interface SendDenialDelegate : NSObject
{
    NSMutableData *data;
}
@property (nonatomic, retain) NSMutableData* data;
@end

NSURLConnection* sDenialConnection = nil;
@implementation SendDenialDelegate
@synthesize data;
-(void)connection:(NSURLConnection*) connection didReceiveResponse:(NSURLResponse*)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    OFLog(@"Status code: %d", [httpResponse statusCode]);
    if([httpResponse statusCode] == 201) {  //created
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:OpenFeintUserOptionSentDisapprovalToServer];        
    }
}

-(void) connectionDidFailWithError:(NSURLConnection*) connection {
    OFLog(@"There was a problem sending the OpenFeint refusal to the server");
}

-(void)dealloc{
    self.data = nil;
    [super dealloc];
}

@end


@implementation OpenFeint (UserOptions)

+ (void)initializeUserOptions
{
	NSData* user = [NSKeyedArchiver archivedDataWithRootObject:[OFUser invalidUser]];
	NSData* game = [NSKeyedArchiver archivedDataWithRootObject:[OFGameProfilePageInfo defaultInfo]];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"YES", OpenFeintUserOptionShouldAutomaticallyPromptLogin,
								 user, OpenFeintUserOptionLocalUser,
								 game, OpenFeintUserOptionLocalGameInfo,
								 nil
								 ];

	[defaults registerDefaults:appDefaults];
}

+ (void)setDontAutomaticallyPromptLogin
{
	[[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:OpenFeintUserOptionShouldAutomaticallyPromptLogin];
}

+ (bool)shouldAutomaticallyPromptLogin
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:OpenFeintUserOptionShouldAutomaticallyPromptLogin];
}

+ (void)setUserApprovedFeint
{
	[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:OpenFeintUserOptionUserFeintApproval];
}

+ (void)setUserDeniedFeint
{
	[[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:OpenFeintUserOptionUserFeintApproval];
}

+ (bool)hasUserSetFeintAccess
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:OpenFeintUserOptionUserFeintApproval] != nil;
}

+ (bool)_hasUserApprovedFeint
{
	return [[[NSUserDefaults standardUserDefaults] stringForKey:OpenFeintUserOptionUserFeintApproval] isEqualToString:@"YES"];
}

+ (void)_resetHasUserSetFeintAccess
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:OpenFeintUserOptionUserFeintApproval];
	[OpenFeint setLocalUser:[OFUser invalidUser]];
	[[OpenFeint provider] destroyLocalCredentials];
}

+ (void)setShouldWarnOnIncompleteDelegates:(BOOL)shouldWarnOnIncompleteDelegates
{
	[[NSUserDefaults standardUserDefaults] setBool:shouldWarnOnIncompleteDelegates forKey:OpenFeintUserOptionShouldWarnOnIncompleteDelegates];
}

+ (BOOL)shouldWarnOnIncompleteDelegates
{
#if defined(_DEBUG) || defined(DEBUG)
	NSNumber* asNumber = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionShouldWarnOnIncompleteDelegates];
	// If the setting isn't there, then we should warn.  Otherwise, do what it says.
	return !asNumber || [asNumber boolValue];
#else
	return false;
#endif
}

+ (NSString*)lastLoggedInUserId
{
	return [[OpenFeint localUser] resourceId];
}

+ (NSString*)lastLoggedInUserProfilePictureUrl
{
	return [[OpenFeint localUser] profilePictureUrl];
}

+ (BOOL)lastLoggedInUserUsesFacebookProfilePicture
{
	return [[OpenFeint localUser] usesFacebookProfilePicture];
}

+ (NSString*)lastLoggedInUserName
{
	return [[OpenFeint localUser] name];
}

+ (void)setLoggedInUserHasSetName:(BOOL)hasSetName
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:hasSetName] forKey:OpenFeintUserOptionLastLoggedInUserHasSetName];
}

+ (BOOL)lastLoggedInUserHasSetName
{
	NSNumber* asNumber = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLastLoggedInUserHasSetName];
	return asNumber && [asNumber boolValue];
}

+ (void)setLoggedInUserHadFriendsOnBootup:(BOOL)hadFriends
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:hadFriends] forKey:OpenFeintUserOptionLastLoggedInUserHadSetNameOnBootup];
}

+ (BOOL)lastLoggedInUserHadFriendsOnBootup
{
	NSNumber* asNumber = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLastLoggedInUserHadSetNameOnBootup];
	return asNumber && [asNumber boolValue];
}

+ (void)setLoggedInUserSharesOnlineStatus:(BOOL)loggedInUserSharesOnlineStatus
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:loggedInUserSharesOnlineStatus] forKey:OpenFeintUserOptionLoggedInUserSharesOnlineStatus];
}

+ (BOOL)loggedInUserSharesOnlineStatus
{
	NSNumber* asNumber = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLoggedInUserSharesOnlineStatus];
	return asNumber && [asNumber boolValue];
}

+ (void)setLoggedInUserHasNonDeviceCredential:(BOOL)hasNonDeviceCredential
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:hasNonDeviceCredential] forKey:OpenFeintUserOptionLastLoggedInUserNonDeviceCredential];
}

+ (BOOL)loggedInUserHasNonDeviceCredential
{
	NSNumber* asNumber = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLastLoggedInUserNonDeviceCredential];
	return asNumber && [asNumber boolValue];
}

+ (void)setLoggedInUserHasHttpBasicCredential:(BOOL)hasHttpBasicCredential
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:hasHttpBasicCredential] forKey:OpenFeintUserOptionLastLoggedInUserHttpBasicCredential];
}

+ (BOOL)loggedInUserHasHttpBasicCredential
{
	NSNumber* asNumber = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLastLoggedInUserHttpBasicCredential];
	return asNumber && [asNumber boolValue];
}

+ (void)setLoggedInUserHasFbconnectCredential:(BOOL)hasFbconnectCredential
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:hasFbconnectCredential] forKey:OpenFeintUserOptionLastLoggedInUserFbconnectCredential];
}

+ (BOOL)loggedInUserHasFbconnectCredential
{
	NSNumber* asNumber = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLastLoggedInUserFbconnectCredential];
	return asNumber && [asNumber boolValue];
}

+ (void)setLoggedInUserHasTwitterCredential:(BOOL)hasTwitterCredential
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:hasTwitterCredential] forKey:OpenFeintUserOptionLastLoggedInUserTwitterCredential];
}

+ (BOOL)loggedInUserHasTwitterCredential
{
	NSNumber* asNumber = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLastLoggedInUserTwitterCredential];
	return asNumber && [asNumber boolValue];
}

+ (void)setLoggedInUserIsNewUser:(BOOL)isNewUser
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isNewUser] forKey:OpenFeintUserOptionLastLoggedInUserIsNewUser];
}

+ (BOOL)loggedInUserIsNewUser
{
	NSNumber* asNumber = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLastLoggedInUserIsNewUser];
	return asNumber && [asNumber boolValue];
}

+ (void)setClientApplicationId:(NSString*)clientApplicationId
{
	[[NSUserDefaults standardUserDefaults] setObject:clientApplicationId forKey:OpenFeintUserOptionClientApplicationId];
}

+ (NSString*)clientApplicationId
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:OpenFeintUserOptionClientApplicationId];
}

+ (void)setInitialDashboardScreen:(NSString*)initialDashboardScreen
{
	[[NSUserDefaults standardUserDefaults] setObject:initialDashboardScreen forKey:OpenFeintUserOptionInitialDashboardScreen];
}

+ (NSString*)initialDashboardScreen
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:OpenFeintUserOptionInitialDashboardScreen];
}

+ (void)setInitialDashboardModalContentURL:(NSString*)urlString
{
    [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:OpenFeintUserOptionInitialDashboardModalContentURL];
}
     
+ (NSString*)initialDashboardModalContentURL
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionInitialDashboardModalContentURL];
}

+ (void)setClientApplicationIconUrl:(NSString*)clientApplicationIconUrl
{
	[[NSUserDefaults standardUserDefaults] setObject:clientApplicationIconUrl forKey:OpenFeintUserOptionClientApplicationIconUrl];
}

+ (NSString*)clientApplicationIconUrl
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:OpenFeintUserOptionClientApplicationIconUrl];
}

+ (void)setUnviewedChallengesCount:(NSInteger)numChallenges
{
	[[NSUserDefaults standardUserDefaults] setInteger:numChallenges forKey:OpenFeintUserOptionUnviewedChallengesCount];
	[OpenFeint postUnviewedChallengeCountChangedTo:numChallenges];
	[OpenFeint updateApplicationBadge];
}

+ (NSInteger)unviewedChallengesCount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:OpenFeintUserOptionUnviewedChallengesCount];
}

+ (void)setPendingFriendsCount:(NSInteger)numFriends
{
	[[NSUserDefaults standardUserDefaults] setInteger:numFriends forKey:OpenFeintUserOptionPendingFriendsCount];
	[OpenFeint postPendingFriendsCountChangedTo:numFriends];
}

+ (NSInteger)pendingFriendsCount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:OpenFeintUserOptionPendingFriendsCount];
}

+ (void)setUnreadIMCount:(NSInteger)unread
{
	[[NSUserDefaults standardUserDefaults] setInteger:unread forKey:OpenFeintUserOptionUnreadIMCount];
	[OpenFeint postUnreadInboxCountChangedTo:[OpenFeint unreadInboxTotal]];
	[OpenFeint postUnreadIMCountChangedTo:unread];
}

+ (NSInteger)unreadIMCount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:OpenFeintUserOptionUnreadIMCount];
}

+ (void)setUnreadPostCount:(NSInteger)unread
{
	[[NSUserDefaults standardUserDefaults] setInteger:unread forKey:OpenFeintUserOptionUnreadPostCount];
	[OpenFeint postUnreadInboxCountChangedTo:[OpenFeint unreadInboxTotal]];
	[OpenFeint postUnreadPostCountChangedTo:unread];
}

+ (NSInteger)unreadPostCount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:OpenFeintUserOptionUnreadPostCount];
}

+ (void)setUnreadInviteCount:(NSInteger)unread
{
	[[NSUserDefaults standardUserDefaults] setInteger:unread forKey:OpenFeintUserOptionUnreadInviteCount];
	[OpenFeint postUnreadInboxCountChangedTo:[OpenFeint unreadInboxTotal]];
	[OpenFeint postUnreadInviteCountChangedTo:unread];
}

+ (NSInteger)unreadInviteCount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:OpenFeintUserOptionUnreadInviteCount];
}

+ (void)setUnreadIMCount:(NSInteger)unreadIMs andUnreadPostCount:(NSInteger)unreadPosts andUnreadInviteCount:(NSInteger)unreadInvites
{
	[[NSUserDefaults standardUserDefaults] setInteger:unreadIMs forKey:OpenFeintUserOptionUnreadIMCount];
	[[NSUserDefaults standardUserDefaults] setInteger:unreadPosts forKey:OpenFeintUserOptionUnreadPostCount];
	[[NSUserDefaults standardUserDefaults] setInteger:unreadInvites forKey:OpenFeintUserOptionUnreadInviteCount];
	[OpenFeint postUnreadInboxCountChangedTo:[OpenFeint unreadInboxTotal]];
	[OpenFeint postUnreadIMCountChangedTo:unreadIMs];
	[OpenFeint postUnreadPostCountChangedTo:unreadPosts];
	[OpenFeint postUnreadInviteCountChangedTo:unreadInvites];
}

+ (NSInteger)unreadInboxTotal
{
	return [OpenFeint unreadIMCount] + [OpenFeint unreadPostCount] + [OpenFeint unreadInviteCount];
}

+ (void)setUserHasRememberedChoiceForNotifications:(BOOL)hasRememberedChoice
{
	[[NSUserDefaults standardUserDefaults] setBool:hasRememberedChoice
											forKey:OpenFeintUserOptionUserHasRememberedChoiceForNotifications];
}

+ (BOOL)userHasRememberedChoiceForNotifications
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:OpenFeintUserOptionUserHasRememberedChoiceForNotifications];
}

+ (void)setUserAllowsNotifications:(BOOL)allowed
{
	[[NSUserDefaults standardUserDefaults] setBool:allowed
											forKey:OpenFeintUserOptionUserAllowsNotifications];
}

+ (BOOL)userAllowsNotifications
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:OpenFeintUserOptionUserAllowsNotifications];
}

+ (BOOL)appHasAchievements {
	return [[OpenFeint localGameProfileInfo] hasAchievements];
}

+ (BOOL)appHasChallenges {
	return [[OpenFeint localGameProfileInfo] hasChallenges];
}

+ (BOOL)appHasLeaderboards {
	return [[OpenFeint localGameProfileInfo] hasLeaderboards];
}

+ (BOOL)appHasFeaturedApplication {
	return [[OpenFeint localGameProfileInfo] hasFeaturedApplication];
}

+ (void)setLocalGameProfileInfo:(OFGameProfilePageInfo*)profileInfo
{
	NSData* encoded = [NSKeyedArchiver archivedDataWithRootObject:profileInfo];
	[[NSUserDefaults standardUserDefaults] setObject:encoded forKey:OpenFeintUserOptionLocalGameInfo];
	[OpenFeint setClientApplicationId:profileInfo.resourceId];
}

+ (OFGameProfilePageInfo*)localGameProfileInfo
{
	NSData* encoded = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLocalGameInfo];
	return (OFGameProfilePageInfo*)[NSKeyedUnarchiver unarchiveObjectWithData:encoded];
}

+ (void)setLocalUser:(OFUser*)user
{
	OFUser* previousUser = [[self localUser] retain];

	NSData* encoded = [NSKeyedArchiver archivedDataWithRootObject:user];
	[[NSUserDefaults standardUserDefaults] setObject:encoded forKey:OpenFeintUserOptionLocalUser];

	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance)
	{
		OFSafeRelease(instance->mCachedLocalUser);
		instance->mCachedLocalUser = [user retain];
	}

	[OpenFeint postUserChangedNotificationFromUser:previousUser toUser:user];
	[previousUser release];
}

+ (OFUser*)localUser
{
	OFUser* localUser = nil;
	
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance)
	{
		if(instance->mCachedLocalUser == nil)
		{
			NSData* encoded = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionLocalUser];
			instance->mCachedLocalUser = [(OFUser*)[NSKeyedUnarchiver unarchiveObjectWithData:encoded] retain];
		}
		
		localUser = instance->mCachedLocalUser;
	}

	return localUser;
}

+ (void)loggedInUserChangedNameTo:(NSString*)name
{
	[OpenFeint setLoggedInUserHasSetName:YES];
	OFUser* user = [self localUser];
	[user setName:name];
	[self setLocalUser:user];
}

+ (void)setUserDistanceUnit:(OFUserDistanceUnitType)distanceUnit
{
	if (![OpenFeint allowLocationServices]) distanceUnit = kDistanceUnitNotAllowed;
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	[standardUserDefaults setInteger:distanceUnit forKey:OpenFeintUserOptionDistanceUnit];
	[standardUserDefaults synchronize];
}

+ (OFUserDistanceUnitType)userDistanceUnit
{
	return (OFUserDistanceUnitType)[[NSUserDefaults standardUserDefaults] integerForKey:OpenFeintUserOptionDistanceUnit];
}

+ (NSDate*)lastAnnouncementDateForLocalUser
{
	NSString* key = [NSString stringWithFormat:@"%@%@", OpenFeintUserOptionLastAnnouncementDate, [OpenFeint lastLoggedInUserId]];
	NSDate* lastDate = [[NSUserDefaults standardUserDefaults] objectForKey:key];
	if (!lastDate)
	{
		lastDate = [NSDate distantPast];
		[[NSUserDefaults standardUserDefaults] setObject:lastDate forKey:key];
	}
	
	return lastDate;
}

+ (void)setLastAnnouncementDateForLocalUser:(NSDate*)date
{
	NSString* key = [NSString stringWithFormat:@"%@%@", OpenFeintUserOptionLastAnnouncementDate, [OpenFeint lastLoggedInUserId]];
	
	NSDate* currentDate = [OpenFeint lastAnnouncementDateForLocalUser];
	if ([currentDate laterDate:date] == date)
	{
		[[NSUserDefaults standardUserDefaults] setObject:date forKey:key];
	}
}

+ (NSString*)suggestionsForumId
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:OpenFeintUserOptionSuggestionsForumId];
}

+ (void)setSuggestionsForumId:(NSString*)forumId
{
	[[NSUserDefaults standardUserDefaults] setObject:forumId forKey:OpenFeintUserOptionSuggestionsForumId];
}

+ (void)setDoneWithGetTheMost:(BOOL)enabled
{
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:OpenFeintUserOptionDoneWithGetTheMost];
}

+ (BOOL)doneWithGetTheMost
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:OpenFeintUserOptionDoneWithGetTheMost];
}

+ (void)setDisabled:(BOOL)disabled
{
	[[NSUserDefaults standardUserDefaults] setBool:disabled forKey:OpenFeintUserOptionIsDisabled];
}

+ (BOOL)isDisabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:OpenFeintUserOptionIsDisabled];
}

+ (void)setSynchWithGameCenterAchievements:(BOOL)synched
{
	[[NSUserDefaults standardUserDefaults] setBool:synched forKey:OpenFeintUserSynchedWithGameCenterAchievements];
}

+ (BOOL)isSynchedWithGameCenterAchievements
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:OpenFeintUserSynchedWithGameCenterAchievements];
}

+ (void)setSynchWithGameCenterLeaderboards:(BOOL)synched
{
	[[NSUserDefaults standardUserDefaults] setBool:synched forKey:OpenFeintUserSynchedWithGameCenterLeaderboards];
}

+ (BOOL)isSynchedWithGameCenterLeaderboards
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:OpenFeintUserSynchedWithGameCenterLeaderboards];
}

#pragma mark TabBar badge gathering functions
+ (NSString*) nowPlayingBadge {
    NSInteger value = [OpenFeint unviewedChallengesCount] + [OFAnnouncementService unreadAnnouncements];
    return [NSString stringWithFormat:@"%u", value];
}

+ (NSString*) myFeintBadge {
    NSInteger value = [OpenFeint pendingFriendsCount] + [OpenFeint unreadInboxTotal];
    return [NSString stringWithFormat:@"%u", value];
}


@end
