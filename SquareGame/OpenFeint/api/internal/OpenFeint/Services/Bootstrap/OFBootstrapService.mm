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
#import "OFBootstrapService.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFBootstrap.h"
#import "OFPoller.h"
#import "OpenFeint+Private.h"
#import "OFDelegateChained.h"
#import "OFResourceNameMap.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OpenFeint+Settings.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+UserStats.h"
#import "OFXmlDocument.h"
#import "OFProvider.h"
#import "OFOfflineService.h"
#import "OFGameProfilePageInfo.h"
#import "OFPresenceService.h"
#import "IPhoneOSIntrospection.h"
#import "OFSettings.h"
#import "OFInviteService.h"
#import "OpenFeint+AddOns.h"
#import "OpenFeint+NSNotification.h"

@interface OFBootstrapService ()
@property (nonatomic, assign, readwrite) BOOL bootstrapInProgress;
@end

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFBootstrapService);

@implementation OFBootstrapService

@synthesize bootstrapInProgress;

OPENFEINT_DEFINE_SERVICE(OFBootstrapService);

- (id) init
{
	self = [super init];
	if (self != nil)
	{
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)registerPolledResources:(OFPoller*)poller
{
}

- (void) populateKnownResources:(OFResourceNameMap*)namedResources
{
	namedResources->addResource([OFBootstrap getResourceName], [OFBootstrap class]);
	[OFOfflineService shareKnownResources:namedResources];
}

+ (BOOL) bootstrapInProgress
{
	return [[OFBootstrapService sharedInstance] bootstrapInProgress];
}

+ (void)doBootstrapWithNewAccount:(BOOL)createNewAccount userId:(NSString*)userId onSucceededLoggingIn:(OFDelegate const&)onSuccess onFailedLoggingIn:(OFDelegate const&)onFailure
{
    OFBootstrapService* instance = [OFBootstrapService sharedInstance];
    if ([instance bootstrapInProgress] || [OFProvider willSilentlyDiscardAction])
	{
		onFailure.invoke(nil);
		return;
	}
	
    [instance setBootstrapInProgress:YES];
	instance->success = onSuccess;
	instance->failure = onFailure;

	OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
	OFRetainedPtr<NSString> udid = [UIDevice currentDevice].uniqueIdentifier;
	params->io("udid", udid);
	
	// specificUserId is the same as userId (used in the bootstrap notification below),
	// with the exception being that if userId is @"0", specificUserId will be nil.  I don't
	// want to go through other consumers of userId and make sure their behavior is the
	// same whether they get @"0" or nil.
	NSString* specificUserId = nil;
	
	if (userId && ![userId isEqualToString:@"0"])
	{
		specificUserId = userId;
		
		params->io("user_id", userId);
	}

	if (createNewAccount)
	{
        bool createNewAccountBool = createNewAccount;
		params->io("create_new_account", createNewAccountBool);
	}

	OFRetainedPtr<NSString> hardwareVersion = getHardwareVersion();
	OFRetainedPtr<NSString> osVersion = OFSettings::Instance()->getClientDeviceSystemVersion();
	
	params->io("device_hardware_version", hardwareVersion);
	params->io("device_os_version", osVersion);
	
	//Get any params needed for offline
	[OFOfflineService getBootstrapCallParams:params userId:userId];
	//Send up the latest user stats
	[OpenFeint getUserStatsParams:params];
		
	[OpenFeint postBootstrapBegan:specificUserId];
	
	[[self sharedInstance]
		_performAction:@"bootstrap.xml"
		withParameters:params
		withHttpMethod:@"POST"
		withSuccess:OFDelegate([self sharedInstance], @selector(bootstrapSucceededOnBootstrapThread:), [OpenFeint provider].requestThread)
		withFailure:OFDelegate([self sharedInstance], @selector(bootstrapFailed:))
		withRequestType:OFActionRequestSilent
		withNotice:nil 
		requiringAuthentication:false];
}

- (void)bootstrapSucceededOnBootstrapThread:(OFPaginatedSeries*)resources
{
	if([resources count] == 0)
	{
		[self performSelectorOnMainThread:@selector(bootstrapFailed:) withObject:nil waitUntilDone:NO];
		return;
	}
	
	OFBootstrap* bootstrap = (OFBootstrap*)[resources objectAtIndex:0];

    if([OpenFeint sharedInstance].mForceUserCheckOnBootstrap) {
        [OpenFeint sharedInstance].mForceUserCheckOnBootstrap = NO;
        id delegate = [OpenFeint getDelegate];
        if([delegate respondsToSelector:@selector(userAttemptingToLogin:)]) {
            if(![delegate userAttemptingToLogin:bootstrap.user]) {
				[[OpenFeint class] performSelectorOnMainThread:@selector(abortBootstrap) withObject:nil waitUntilDone:NO];
				[self performSelectorOnMainThread:@selector(bootstrapFailed:) withObject:nil waitUntilDone:NO];
				return;
			}
        }
    }
	
	[OpenFeint storePollingFrequencyDefault:bootstrap.pollingFrequencyDefault];
	[OpenFeint storePollingFrequencyInChat:bootstrap.pollingFrequencyInChat];
	[[OpenFeint provider] setAccessToken:bootstrap.accessToken andSecret:bootstrap.accessTokenSecret];
	[OpenFeint setLoggedInUserHasSetName:bootstrap.loggedInUserHasSetName];
	[OpenFeint setLoggedInUserHadFriendsOnBootup:bootstrap.loggedInUserHadFriendsOnBootup];
	
	[OpenFeint setLoggedInUserHasHttpBasicCredential:bootstrap.loggedInUserHasHttpBasicCredential];
	[OpenFeint setLoggedInUserHasFbconnectCredential:bootstrap.loggedInUserHasFbconnectCredential];
	[OpenFeint setLoggedInUserHasTwitterCredential:bootstrap.loggedInUserHasTwitterCredential];
	
	[OpenFeint setLoggedInUserHasNonDeviceCredential: bootstrap.loggedInUserHasHttpBasicCredential 
													  || bootstrap.loggedInUserHasFbconnectCredential 
													  || bootstrap.loggedInUserHasTwitterCredential];
	
	[OpenFeint setLoggedInUserIsNewUser:bootstrap.loggedInUserIsNewUser];
    
	[OpenFeint setClientApplicationId:bootstrap.clientApplicationId];
	[OpenFeint setClientApplicationIconUrl:bootstrap.clientApplicationIconUrl];
	[OpenFeint setUnviewedChallengesCount:bootstrap.unviewedChallengesCount];
	[OpenFeint setPendingFriendsCount:bootstrap.pendingFriendsCount];
	[OpenFeint setLocalGameProfileInfo:bootstrap.gameProfilePageInfo];
	[OpenFeint setLocalUser:bootstrap.user];
	[OpenFeint setSuggestionsForumId:bootstrap.suggestionsForumId];
	[OpenFeint setInitialDashboardScreen:bootstrap.initialDashboardScreen];
    [OpenFeint setInitialDashboardModalContentURL:bootstrap.initialDashboardModalContentURL];
	[OpenFeint setLoggedInUserSharesOnlineStatus:bootstrap.initializePresenceService];

	[OpenFeint setUnreadIMCount:bootstrap.imsUnreadCount andUnreadPostCount:bootstrap.subscribedThreadsUnreadCount andUnreadInviteCount:bootstrap.invitesUnreadCount];
	
	
	[OpenFeint setUserDistanceUnit: (bootstrap.loggedInUserHasShareLocationEnabled ? kDistanceUnitMiles : kDistanceUnitNotAllowed)];
	
	[[OFPresenceService sharedInstance] setPresenceQueue:bootstrap.presenceQueue];
	[[OFPresenceService sharedInstance] setPipeHttpOverPresence:bootstrap.pipeHttpOverPresenceService];

	if (bootstrap.initializePresenceService)
	{
		[[OFPresenceService sharedInstance] connect];
	}

	[OpenFeint resetUserStats];
	[OpenFeint incrementNumberOfOnlineGameSessions]; //Will get updated on the server the next bootstrap.

	if([resources count] > 1)
	{
		//sync data from host
		OFBootstrap* bootstrap = (OFBootstrap*)[resources objectAtIndex:0];
		OFOffline* offline = (OFOffline*)[resources objectAtIndex:1];
		[OFOfflineService syncOfflineData:offline bootStrap:bootstrap];
	}
	
	[self performSelectorOnMainThread:@selector(bootstrapSucceeded:) withObject:resources waitUntilDone:NO];
}

- (void)bootstrapSucceeded:(OFPaginatedSeries *)resources
{
	[OpenFeint notifyAddOnsUserLoggedIn];
    bootstrapInProgress = NO;
	[OpenFeint postBootstrapSucceeded];	
	success.invoke((NSObject*)resources);
	success = OFDelegate();
	failure = OFDelegate();
}

- (void)bootstrapFailed:(MPOAuthAPIRequestLoader*)loader
{
	bootstrapInProgress = NO;
	[OpenFeint postBootstrapFailed];
	failure.invoke(loader);
	success = OFDelegate();
	failure = OFDelegate();
}

@end
