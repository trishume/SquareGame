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
#import "OpenFeint+Private.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OFControllerLoader.h"
#import <QuartzCore/QuartzCore.h>
#import "OFPoller.h"
#import "OFProvider.h"
#import "OFPoller.h"
#import "OFDeadEndErrorController.h"
#import "OFReachability.h"
#import "OFServerMaintenanceNoticeController.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+NSNotification.h"
#import "OFNotification.h"
#import "OFNotificationDelegate.h"
#import "OFActionRequest.h"
#import "OFNavigationController.h"
#import "OFIntroNavigationController.h"
#import "OpenFeint+Settings.h"
#import "OpenFeint+Dashboard.h"
#import "OFXmlDocument.h"
#import "OFTransactionalSaveFile.h"
#import <sqlite3.h>
#import "OFAchievementService+Private.h"
#import "OFImageCache.h"
#import "OFUserFeintApprovalController.h"
#import "OFLinkSocialNetworksController.h"
#import "OFDelegateChained.h"
#import "OFUsersCredential.h"
#import "OFExtendedCredentialController.h"
#import "OFTableControllerHelper.h"
#import "OFRootController.h"
#import "OFDoBootstrapController.h"
#import "IPhoneOSIntrospection.h"
#import "OFTabBarController.h"
#import "OFChallengeListController.h"
#import "OFViewHelper.h"
#import "OFOfflineService.h"
#import "OFTabbedDashboardController.h"
#import "OFFramedNavigationController.h"
#import "OFGameProfileController.h"
#import "OFHighScoreController.h"
#import "OFLeaderboardController.h"
#import "OFLeaderboardService+Private.h"
#import "OFAnnouncementService+Private.h"
#import "OFImageLoader.h"
#import "OpenFeint+UserStats.h"
#import "UIApplication+OpenFeint.h"
#import "OFWebApprovalController.h"
#import "OFHttpService.h"
#import "OFImageView.h"
#import "OFPointer.h"
#import "OpenFeint+GameCenter.h"
#import "OFAchievementListController.h"
#import "OpenFeint+AddOns.h"
#import "OFSession.h"
#import "OFServerException+Session.h"
#import "OFUser.h"
#import "OFParentalControls.h"
#import "OFDevice.h"

namespace
{
	OpenFeint* gInstance = nil;
	unsigned int kOverlayBackgroundViewTag = 489;

	// We want to reserve 3MB when the dashboard isn't open.
	static const int kOFReservedMemorySize = (3*1024*1024);
}

@implementation OpenFeint (Private)

static BOOL s_BootstrapCompleted = NO;
extern OFIntroNavigationController *gOFretainedIntroController;

+ (BOOL)hasBootstrapCompleted{
	return s_BootstrapCompleted;
}

+ (void)invalidateBootstrap{
	s_BootstrapCompleted = NO;
}

+ (void) createSharedInstance
{
	NSAssert(gInstance == nil, @"Attempting to initialize OpenFeint a second time. This is not allowed.");
	gInstance = [[OpenFeint alloc] init];
}

+ (void)destroySharedInstance
{
	NSAssert(gInstance != nil, @"Attempting to shutdown OpenFeint when it has not been initialized. This is not allowed.");
	OFSafeRelease(gInstance);
}

+(void) loginGameCenterCheck
{

    [OpenFeint incrementNumberOfOnlineGameSessions];
	[OpenFeint incrementNumberOfGameSessions];
    
    if([OpenFeint isUsingGameCenter]) 
	{
//        [OpenFeint initializeGameCenter];
    }
    else if([OpenFeint isSuccessfullyBootstrapped])
	{
        [OpenFeint loginShowNotifications];
	}
    
    
	NSString* userId = [OpenFeint lastLoggedInUserId];
	[[OFOfflineService sharedInstance] performSelector:@selector(sendPendingData:) withObject:userId];
	
	[OFAnnouncementService downloadAnnouncements];
    
}


+ (void)loginShowNotifications
{
	if (![OpenFeint isShowingFullScreen])
	{        
		NSUInteger numChallenges = [OpenFeint unviewedChallengesCount];
        NSUInteger numInvites = [OpenFeint unreadInviteCount];
		NSUInteger numInbox = [OpenFeint unreadInboxTotal];
		NSUInteger numFriends = [OpenFeint pendingFriendsCount];
		
		NSString* notificationText = nil;

		if (numChallenges > 0)
		{
            OFLOCALIZECOMMENT("Multiple items in string")
			notificationText = [NSString stringWithFormat:@"Hi %@! You have %u new challenge%@.", 
				[OpenFeint lastLoggedInUserName], 
				numChallenges, 
				(numChallenges > 1 ? @"s" : @"")];
		}
        else if (numInvites > 0)
        {
            OFLOCALIZECOMMENT("Multiple items in string")
			notificationText = [NSString stringWithFormat:OFLOCALSTRING(@"Hi %@! You have %u new invitation%@."), 
                                [OpenFeint lastLoggedInUserName], 
                                numInvites, 
                                (numInvites > 1 ? @"s" : @"")];            
        }
		else if (numInbox > 0)
		{
            OFLOCALIZECOMMENT("Multiple items in string")
			notificationText = [NSString stringWithFormat:OFLOCALSTRING(@"Hi %@! You have %u unread conversation%@."), 
				[OpenFeint lastLoggedInUserName], 
				numInbox, 
				(numInbox > 1 ? @"s" : @"")];
		}
		else if(numFriends > 0)
		{
            OFLOCALIZECOMMENT("Multiple items in string")
			notificationText = [NSString stringWithFormat:OFLOCALSTRING(@"Hi %@! You have %u pending friend%@."), 
				[OpenFeint lastLoggedInUserName], 
				numFriends, 
				(numFriends > 1 ? @"s" : @"")];
		}
		else
		{
			notificationText = [NSString stringWithFormat:OFLOCALSTRING(@"Welcome back, %@"), [OpenFeint lastLoggedInUserName]];
		}
		
		OFNotificationData* notificationData = [OFNotificationData dataWithText:notificationText andCategory:kNotificationCategoryLogin andType:kNotificationTypeSuccess];
		notificationData.imageName = @"OpenFeintLogoNotificationIcon.png";
		[[OFNotification sharedInstance] showBackgroundNotice:notificationData andStatus:OFNotificationStatusSuccess];
	}
}

+ (void)loginWasAborted:(BOOL)sslError
{
	if (sslError)
	{
		[self performSelector:@selector(showSSLNotification) withObject:nil afterDelay:3.f];
	}

	[OpenFeint incrementNumberOfGameSessions];
    if([OpenFeint isUsingGameCenter]) {
        [OpenFeint initializeGameCenter];
        return;
    }
	NSString* noticeText;
	NSString* userId = [OpenFeint lastLoggedInUserId];

	if (![userId isEqualToString:@"0"] && [OpenFeint lastLoggedInUserName])
	{
		noticeText = [NSString stringWithFormat:OFLOCALSTRING(@"Welcome back, %@, you are OFFLINE"), [OpenFeint lastLoggedInUserName]];
	}
	else
	{
		noticeText = OFLOCALSTRING(@"Not Logged In To OpenFeint");
	}
	
	OFNotificationData* notice = [OFNotificationData dataWithText:noticeText andCategory:kNotificationCategoryLogin andType:kNotificationTypeSuccess];
	[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusFailure];	
}

+ (void)showSSLNotification
{
	OFNotificationData* notice = 
		[OFNotificationData 
			dataWithText:OFLOCALSTRING(@"Check your date & time settings.") 
			andCategory:kNotificationCategoryLogin 
			andType:kNotificationTypeSuccess];
	[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusFailure];	
}

+ (void)launchLoginFlowAndShowDashboard:(bool)shouldShowDashboard withOptionalRequest:(OFActionRequest*)request
{
	const bool isAutomaticallyPrompting = shouldShowDashboard == false;
	NSString* complicatedErrorOccurred = OFLOCALSTRING(@"Unable to login to OpenFeint. Restart to try again.");
	OFNotificationData* notice = [OFNotificationData dataWithText:complicatedErrorOccurred andCategory:kNotificationCategoryLogin andType:kNotificationTypeError];
	if(![self isShowingFullScreen])
	{
		if(isAutomaticallyPrompting && ![self shouldAutomaticallyPromptLogin] && !request.failedNotAuthorized)
		{
			[self loginWasAborted:NO];
		}
		else
		{
			[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusFailure];
		}
	}
	else
	{
		[self displayErrorMessage:complicatedErrorOccurred];
	}
	
	[request abandonInLightOfASeriousError];
}

+ (void)launchLoginFlowThenDismiss
{
	[self launchLoginFlowAndShowDashboard:false withOptionalRequest:nil];
}

+ (void)launchLoginFlowToDashboard
{
	[self launchLoginFlowAndShowDashboard:true withOptionalRequest:nil];
}

+ (void)launchLoginFlowForRequest:(OFActionRequest*)request;
{
	[self launchLoginFlowAndShowDashboard:[OpenFeint isDashboardHubOpen] withOptionalRequest:request];
}

- (void)invokeAndClearBootstrapDelegates:(std::vector<OFDelegate>&)delegates
{
	std::vector<OFDelegate>::const_iterator it = delegates.begin();
	std::vector<OFDelegate>::const_iterator itEnd = delegates.end();
	for (; it != itEnd; ++it)
	{
		it->invoke();
	}
	mBootstrapSuccessDelegates.clear();
	mBootstrapFailureDelegates.clear();
}

- (void)_invokeLoggedInDelegate
{
	if (_openFeintFlags.isConfirmAccountFlowActive)
	{
		_openFeintFlags.hasDeferredLoginDelegate = YES;
		return;
	}
	else
	{
        [OpenFeint initializeGameCenter];
		if ([OpenFeint isOnline])
		{
			OF_OPTIONALLY_INVOKE_DELEGATE_WITH_PARAMETER([OpenFeint getDelegate], userLoggedIn:, (id)[OpenFeint lastLoggedInUserId]);
            [OpenFeint notifyAddOnsUserLoggedInPostIntro];
		}
		else
		{
			OF_OPTIONALLY_INVOKE_DELEGATE_WITH_PARAMETER([OpenFeint getDelegate], offlineUserLoggedIn:, (id)[OpenFeint lastLoggedInUserId]);
            [OpenFeint notifyAddOnsOfflineUserLoggedInPostIntro];
		}
	}
}

- (void)session:(OFSession*)session didLoginUser:(OFUser*)user previousUser:(OFUser*)previousUser
{
	if (!_openFeintFlags.isBootstrapInProgress)
		return;

	mSuccessfullyBootstrapped = true;
	
	s_BootstrapCompleted = YES;
	
	[self invokeAndClearBootstrapDelegates:mBootstrapSuccessDelegates];
	
	[OpenFeint switchToOnlineDashboard];

	//s_BootstrapCompleted = YES;
			
#ifdef __IPHONE_3_0
	if (mPushNotificationsEnabled)
	{
		if ([OpenFeint isTargetAndSystemVersionThreeOh])
		{
			const int notificationFlags = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert;
			[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationType)notificationFlags];
		}
	}
#endif
	
	//s_BootstrapCompleted = YES;
	
	
    
	BOOL disabled = [OpenFeint isDisabled];
	
    if([[OpenFeint getDelegate] respondsToSelector:@selector(privateIgnoreSocialNetworks)]) disabled = YES;
    
	
	if (disabled || [OpenFeint doneWithGetTheMost]) {
		//OfLog(@"GetTheMost screen is not needed.");
	} else if ([OFLinkSocialNetworksController hasSessionSeenLinkSocialNetworksScreen]) {
		//OfLog(@"GetTheMost screen still needed but already seen since app start.");
	} else if ([OpenFeint isShowingFullScreen]) {
		//OfLog(@"GetTheMost screen delayed on full screen from _succeededBootstrapping.");
	} else {
		_openFeintFlags.isConfirmAccountFlowActive = YES;
		
		UIViewController* getTheMostController = nil;
		OFNavigationController* navController = nil;
		
		getTheMostController = (UIViewController*)OFControllerLoader::load(@"LinkSocialNetworks");
		navController = [[[OFNavigationController alloc] initWithRootViewController:getTheMostController] autorelease];
		[navController setNavigationBarHidden:YES animated:NO];
		
        OFIntroNavigationController *introController = [[[OFIntroNavigationController alloc] initWithNavigationController:navController] autorelease];
        
		if ([OpenFeint isShowingFullScreen]){
			//OfLog(@"GetTheMost screen launched in full screen from _succeededBootstrapping.");
			[[OpenFeint getRootController] presentModalViewController:introController animated:YES];
		} else {
			//OfLog(@"GetTheMost screen launched as indepedent modal from _succeededBootstrapping.");
			[OpenFeint presentRootControllerWithModal:introController];
		}
	}	

	[self _invokeLoggedInDelegate];
	
	if (disabled && _openFeintFlags.isConfirmAccountFlowActive)
	{
		[OpenFeint dismissRootControllerOrItsModal];
	}

	_openFeintFlags.isBootstrapInProgress = NO;
}

- (void)session:(OFSession*)session didLogoutUser:(OFUser*)user
{
	OFRetainedPtr<NSString> userId = [OpenFeint lastLoggedInUserId];
	[OpenFeint setLocalUser:[OFUser invalidUser]];
	[[OpenFeint provider] destroyLocalCredentials];
	[OpenFeint setUserDeniedFeint];
	[OpenFeint switchToOfflineDashboard];
	mSuccessfullyBootstrapped = NO;
	[OpenFeint invalidateBootstrap];
	[OpenFeint setDoneWithGetTheMost:NO];
	[OFLinkSocialNetworksController invalidateSessionSeenLinkSocialNetworksScreen];
	OF_OPTIONALLY_INVOKE_DELEGATE_WITH_PARAMETER([OpenFeint getDelegate], userLoggedOut:, (id)userId.get());
}
	
- (void)session:(OFSession*)session failureWithException:(OFServerException*)exception
{
	if (!_openFeintFlags.isBootstrapInProgress)
		return;

	[OpenFeint loginWasAborted:[exception isSslFailureException]];
	[self invokeAndClearBootstrapDelegates:mBootstrapFailureDelegates];
	[self _invokeLoggedInDelegate];
	
	_openFeintFlags.isBootstrapInProgress = NO;
}

+ (void)abortBootstrap {
	[OpenFeint sharedInstance]->_openFeintFlags.isBootstrapInProgress = NO;
}

+ (void)doBootstrapAsUserId:(NSString*)userId newUser:(BOOL)createNewAccount onSuccess:(const OFDelegate&)chainedOnSuccess onFailure:(const OFDelegate&)chainedOnFailure
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance && instance->_openFeintFlags.isBootstrapInProgress)
		return;

	if([OpenFeint hasUserApprovedFeint])
	{
		[OpenFeint addBootstrapDelegates:chainedOnSuccess onFailure:chainedOnFailure];
		instance->_openFeintFlags.isBootstrapInProgress = YES;
		if (createNewAccount)
			[instance->mSession loginNewUser];
		else
			[instance->mSession loginUserId:userId password:nil];
	}
	else if (![OpenFeint hasUserSetFeintAccess])
	{
        instance->mForceUserCheckOnBootstrap = NO;
		OFDelegate nilDelegate;
		[OpenFeint presentUserFeintApprovalModal:nilDelegate deniedDelegate:nilDelegate];
	}
    else {
        instance->mForceUserCheckOnBootstrap = NO;
        [OpenFeint initializeGameCenter];
    }
}

+ (void)doBootstrapAsNewUserOnSuccess:(const OFDelegate&)chainedOnSuccess onFailure:(const OFDelegate&)chainedOnFailure
{
	[self doBootstrapAsUserId:nil newUser:YES onSuccess:chainedOnSuccess onFailure:chainedOnFailure];
}

+ (void)doBootstrapAsUserId:(NSString*)userId onSuccess:(OFDelegate const&)chainedOnSuccess onFailure:(OFDelegate const&)chainedOnFailure
{
	[self doBootstrapAsUserId:userId newUser:NO onSuccess:chainedOnSuccess onFailure:chainedOnFailure];
}

+ (void)addBootstrapDelegates:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	instance->mBootstrapSuccessDelegates.push_back(onSuccess);
	instance->mBootstrapFailureDelegates.push_back(onFailure);
}

+ (BOOL)isSuccessfullyBootstrapped
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	return instance ? instance->mSuccessfullyBootstrapped : NO;
}

+ (void)presentConfirmAccountModal:(OFDelegate&)onCompletionDelegate useModalInDashboard:(BOOL)useModalInDashboard
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	instance->_openFeintFlags.isConfirmAccountFlowActive = YES;
	
	OFDoBootstrapController* approvalFlow = (OFDoBootstrapController*)OFControllerLoader::load(@"DoBootstrap");
	[approvalFlow setCompleteDelegate:onCompletionDelegate];
	
	if (([OpenFeint isShowingFullScreen] && useModalInDashboard) || ![OpenFeint isShowingFullScreen])
	{
		OFNavigationController* newNavController = [[[OFNavigationController alloc] initWithRootViewController:approvalFlow] autorelease];
		[newNavController setNavigationBarHidden:YES animated:NO];
		
		OFIntroNavigationController *introController = [[[OFIntroNavigationController alloc] initWithNavigationController:newNavController] autorelease];
		if([OpenFeint getRootController])
		{
			[[OpenFeint getRootController] presentModalViewController:introController animated:YES];
		}
		else 
		{
			//This happens right now when we are not showingFullScreen and the user had a custom approval screen.  We don't have a root controller
			//because openfeint dashboard isn't open.
			[OpenFeint presentRootControllerWithModal:introController];
		}

	}
	else
	{
		UINavigationController* navController = [OpenFeint getActiveNavigationController];
		OFAssert(navController, "Must have a navigation controller in this case!");            
		[navController pushViewController:approvalFlow animated:YES];
	}
}

// XXX obviously this is always going to make the view fullscreen
// XXX but that's fine for our case :D
+ (void)transformView:(UIView*)view toOrientation:(UIInterfaceOrientation)orientation
{
	CGAffineTransform newTransform = CGAffineTransformIdentity;
	CGRect bounds = [[UIScreen mainScreen] bounds];
	CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
	switch (orientation) 
	{
		case UIInterfaceOrientationLandscapeRight:
			newTransform = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
			bounds = CGRectMake(0.f, 0.f, bounds.size.height, bounds.size.width);
			break;
		case UIInterfaceOrientationLandscapeLeft:
			newTransform = CGAffineTransformMake(0, -1, 1, 0, 0, 0);
			bounds = CGRectMake(0.f, 0.f, bounds.size.height, bounds.size.width);
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			newTransform = CGAffineTransformMake(-1, 0, 0, -1, 0, 0);
			break;
		case UIInterfaceOrientationPortrait:
			newTransform = CGAffineTransformTranslate(newTransform, 0, 0);
			break;
		default:
			OFAssert(false, "invalid orientation used");
			break;
	}
	
	[view setTransform:newTransform];
	view.bounds = bounds;
	view.center = center;
}

+ (void)transformViewToDashboardOrientation:(UIView*)view
{
	UIInterfaceOrientation dashboardOrientation = [OpenFeint sharedInstance]->mDashboardOrientation;
	[self transformView:view toOrientation:dashboardOrientation];
}

+ (bool)tryCreateDashboardWithModal:(UIViewController*)modal
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	
	if ([OpenFeint isShowingFullScreen] || (instance->mOFRootController && instance->mIsDashboardDismissing))
	{
		instance->mQueuedRootModal = [modal retain];
		return false;
	}

	instance->mIsDashboardDismissing = false;
	
	// jkw: Must be called before the root controller is loaded
	[self dashboardWillAppear];
	
	if (!instance->mOFRootController)
	{
		instance->mOFRootController = [OFControllerLoader::load(@"Root") retain];
	}

	[OpenFeint transformViewToDashboardOrientation:instance->mOFRootController.view];
	
    [instance->mOFRootController viewWillAppear:YES];
	[[OpenFeint getTopApplicationWindow] addSubview:instance->mOFRootController.view];
    [instance->mOFRootController viewDidAppear:YES];
		
	return true;
}

+ (void)presentModalOverlay:(UIViewController*)modal
{
    [self presentModalOverlay:modal opaque:YES];
}

+ (void)presentModalOverlay:(UIViewController*)modal opaque:(BOOL)isOpaque
{
	if ([OpenFeint isDisabled])
		return;
    if([OpenFeint isLargeScreen])
        isOpaque = NO;

	OpenFeint* instance = [OpenFeint sharedInstance];
		
	if(![self tryCreateDashboardWithModal:modal])
	{
		instance->mIsQueuedModalAnOverlay = true;
		return;
	}

	instance->mIsShowingOverlayModal = true;

	CGRect dashboardBounds = [OpenFeint getDashboardBounds];
    
    if (isOpaque)
    {
        UIView* backgroundView = [[[UIView alloc] initWithFrame:dashboardBounds] autorelease];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        backgroundView.autoresizesSubviews = YES;
        backgroundView.backgroundColor = [UIColor blackColor];
        backgroundView.tag = kOverlayBackgroundViewTag;
        backgroundView.alpha = 0.0f;
        [instance->mOFRootController.view addSubview:backgroundView];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5f];
        backgroundView.alpha = 0.85f;
        [UIView commitAnimations];
    }
    else
    {
        [instance->mOFRootController.bgDropShadow removeFromSuperview];
    }
	
	CGRect modalRect = modal.view.frame;
	modalRect.origin.x = 0.5f * (dashboardBounds.size.width - modalRect.size.width);
	modal.view.frame = modalRect;
	
	instance->mOFRootController.transitionIn = kCATransitionFromBottom;
	instance->mOFRootController.transitionOut = kCATransitionFromTop;
	[instance->mOFRootController showController:modal];
}

+ (void)presentRootControllerWithModal:(UIViewController*)modal
{
	if ([OpenFeint isDisabled])
		return;

	OpenFeint* instance = [OpenFeint sharedInstance];

	if(![self tryCreateDashboardWithModal:modal])
	{
		instance->mIsQueuedModalAnOverlay = false;
		return;
	}

	instance->mIsShowingOverlayModal = false;
    
    CGRect rootBounds = instance->mOFRootController.view.bounds;
    modal.view.frame = CGRectMake(0.f, 0.f, rootBounds.size.width, rootBounds.size.height);
    
    instance->mOFRootController.transitionIn = kCATransitionFromTop;
    instance->mOFRootController.transitionOut = kCATransitionFromBottom;
    [instance->mOFRootController showController:modal];
    
    OFSafeRelease(gOFretainedIntroController);
}

+ (void)presentRootControllerWithTabbedDashboard:(NSString*)controllerName
{
	[self presentRootControllerWithTabbedDashboard:controllerName pushControllers:nil];
}

+ (void)presentRootControllerWithTabbedDashboard:(NSString*)controllerName pushControllers:(NSArray*)pushControllers
{
	OFTabbedDashboardController* tabController = nil;
	BOOL alreadyOpen = NO;
	
	if ([OpenFeint isDashboardHubOpen])
	{
		// We may be being launched from inside a notification?
		tabController = (OFTabbedDashboardController*)gInstance->mOFRootController.contentController;
		alreadyOpen = YES;
	}
	else
	{
		tabController = (OFTabbedDashboardController*)OFControllerLoader::load(@"TabbedDashboard");
	}
	
	bool online = [OpenFeint isOnline];
	
	NSString* override = [OpenFeint initialDashboardScreen];
	if (!controllerName && [OpenFeint hasUserApprovedFeint] && override && override.length)
	{
		controllerName = override;
	}
	
	controllerName = (controllerName ? controllerName : [tabController defaultTab]);

	// The only tab guaranteed to work offline is the NowPlaying tab.
	if (![OpenFeint isOnline])
	{
		controllerName = [tabController offlineTab];
		pushControllers = nil;
	}

	if (!alreadyOpen)
	{
		[OpenFeint presentRootControllerWithModal:tabController];
	}
	[tabController showTabViewControllerNamed:controllerName];

	OFFramedNavigationController* navController = (OFFramedNavigationController*) tabController.tabBar.selectedViewController;
	if (alreadyOpen)
	{
		[navController popToRootViewControllerAnimated:NO];
	}
	
    UIViewController* controllerToPush = nil;
	bool allowed = true;
	for (NSObject* obj in pushControllers)
	{
		if (allowed)
		{
			if ([obj isKindOfClass:[NSString class]])
			{
				if (controllerToPush && [controllerToPush isKindOfClass:[OFLeaderboardController class]])
				{
					//The previous controller was leaderboard, the string is a leaderboardId for high scores
					OFLeaderboard* leaderboard = [OFLeaderboardService getLeaderboard:(NSString*)obj];
					if( leaderboard )
					{
						controllerToPush = (UIViewController*)OFControllerLoader::load(OpenFeintControllerHighScores);
						controllerToPush.title = @"HighScore";
						OFHighScoreController* highScoreController = (OFHighScoreController*)controllerToPush;
						highScoreController.leaderboard = leaderboard;
					} 
					else
					{
						controllerToPush = nil;
					}
				} else { 
					NSString* pushControllerName = (NSString*)obj;
					controllerToPush = (UIViewController*)OFControllerLoader::load(pushControllerName);
				}
			}
			else if ([obj isKindOfClass:[UIViewController class]])
			{
				controllerToPush = (UIViewController*)obj;
			}
			else
				OFAssert(false, "Unrecognized argument type!");
			
			allowed = online; //if offline assume controller is not allowed
			if (controllerToPush && [controllerName isEqualToString:OpenFeintDashBoardTabNowPlaying])
			{
				OFGameProfilePageInfo* localInfo = [OpenFeint localGameProfileInfo];
				[navController changeGameContext:localInfo];
				[OFGameProfileController setPushControllerData:controllerToPush withGameProfileInfo:localInfo];

				if ([controllerToPush.title isEqualToString: @"Achievements"])
				{
					allowed = [OpenFeint appHasAchievements];
				}
				else if ([controllerToPush.title isEqualToString: @"Leaderboards"] ||
						 [controllerToPush.title isEqualToString: @"HighScore"])
				{
					allowed = [OpenFeint appHasLeaderboards] || [OFLeaderboardService hasLeaderboards];
				}
			}
			
			if (allowed)
			{
				[navController pushViewController:controllerToPush animated:YES];
				
				if(controllerToPush && [controllerToPush isKindOfClass:[OFAchievementListController class]])
				{
					[((OFAchievementListController*)controllerToPush) postPushAchievementListController];
				}
			}
		}
	}
	
#if defined(_DEBUG) || defined(DEBUG)
	if ([self shouldWarnOnIncompleteDelegates])
	{
		// Only do this once per install anyway...
		[self setShouldWarnOnIncompleteDelegates:NO];
		
		// Let's look at our delegate
		id delegate = [self sharedInstance]->mDelegatesContainer.openFeintDelegate;
		
		if (!delegate ||
			![delegate respondsToSelector:@selector(dashboardWillAppear)] ||
			![delegate respondsToSelector:@selector(dashboardDidDisappear)])
		{
			NSString* msg = nil;
			if (!delegate) {
				msg = [NSString stringWithFormat:
					   OFLOCALSTRING(@"Please make sure to provide a delegate to OpenFeint!")];
			} else {
				msg = [NSString stringWithFormat:
					   OFLOCALSTRING(@"%s doesn't implement some of the dashboard-handling "
					   "messages from OpenFeintDelegate.h.  Please make sure "
					   "to pause your game and stop updating the view when you "
					   "open the Dashboard!  See OpenFeintDelegate.h for details."),
					   object_getClassName(delegate)];
			}
			UIAlertView* av = [[UIAlertView alloc] initWithTitle:OFLOCALSTRING(@"OpenFeint Developer Warning")
														 message:msg
														delegate:nil
											   cancelButtonTitle:OFLOCALSTRING(@"OK")
											   otherButtonTitles:nil];
			
			[av show];
			[av release];
		}
	}	
#endif
}

- (void)_presentRootControllerWithTabbedDashboard
{
	if ([OpenFeint isOnline])
	{
	  [OpenFeint presentRootControllerWithTabbedDashboard:nil];
	} else {
		[OpenFeint destroyDashboard];
	}
}

+ (void) launchDashboardWithDelegate:(id<OpenFeintDelegate>)delegate tabControllerName:(NSString*)tabControllerName
{
	[self launchDashboardWithDelegate:delegate tabControllerName:tabControllerName andControllers:nil];
}

+ (void) launchDashboardWithDelegate:(id<OpenFeintDelegate>)delegate tabControllerName:(NSString*)tabControllerName andController:(NSString*)controller
{
	NSArray* controllers = [[[NSArray alloc] initWithObjects:controller,nil] autorelease];
	[self launchDashboardWithDelegate:delegate tabControllerName:tabControllerName andControllers:controllers];
}

+ (void) launchDashboardWithDelegate:(id<OpenFeintDelegate>)delegate tabControllerName:(NSString*)tabControllerName andControllers:(NSArray*)controllers
{
    //with some GL games, the main autorelease pool is not released until later, this causes a 
    //circular dependency which keeps the Dashboard loaded in the background.   By putting a 
    //release pool here, we are guaranteed that the dashboard get autoreleased.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	OpenFeint* instance = [OpenFeint sharedInstance];
	instance->mLaunchDelegate = delegate;
	
	bool allowOfflineDashboard = !instance->mRequireOnlineStatus && [OFLeaderboardService hasLeaderboards];
	if (![OpenFeint hasUserApprovedFeint] && !allowOfflineDashboard)
	{
		OFDelegate nilDelegate;
		OFDelegate presentRootControllerDelegate([OpenFeint sharedInstance], @selector(_presentRootControllerWithTabbedDashboard));
		[OpenFeint presentUserFeintApprovalModal:presentRootControllerDelegate deniedDelegate:nilDelegate];
        
        OFWebApprovalController *webController = [[OFIntroNavigationController activeIntroNavigationController].navController.viewControllers objectAtIndex:0];
        if ([webController isKindOfClass:[OFWebApprovalController class]])
        {
            [webController show];
        }
        
	}
	else if (([instance->mProvider isAuthenticated] && [OpenFeint lastLoggedInUserId]) || allowOfflineDashboard) 
	{
		[OpenFeint presentRootControllerWithTabbedDashboard:tabControllerName pushControllers:controllers];
	}
	else if (!OFReachability::Instance()->isGameServerReachable()) 
	{
		[[[[UIAlertView alloc] initWithTitle:OFLOCALSTRING(@"No OpenFeint Account") 
									 message:OFLOCALSTRING(@"You must go online once and connect to the OpenFeint server.") 
									delegate:nil 
						   cancelButtonTitle:OFLOCALSTRING(@"OK") 
						   otherButtonTitles:nil] autorelease] show];
	}
	else
	{
		[self launchLoginFlowToDashboard];
	}
    [pool release];
}

+ (void)switchToOnlineDashboard
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (!instance->_openFeintFlags.isOpenFeintDashboardInOnlineMode)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:OFNSNotificationUserOnline object:nil userInfo:nil];
		
		UIViewController* topController = instance->mOFRootController.contentController;
		if ([topController isKindOfClass:[OFTabBarController class]])
		{
			OFTabBarController* tabController = (OFTabBarController*)topController;
			[OFTabbedDashboardController setOnlineMode:tabController];
		}

		[OpenFeint reloadInactiveTabBars];

		instance->_openFeintFlags.isOpenFeintDashboardInOnlineMode = YES;
	}
}

+ (void)switchToOfflineDashboard
{
	OpenFeint* instance = [OpenFeint sharedInstance];	
	if (instance->_openFeintFlags.isOpenFeintDashboardInOnlineMode)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:OFNSNotificationUserOffline object:nil userInfo:nil];

		[OpenFeint setUnviewedChallengesCount:0];
		[OpenFeint setUnreadIMCount:0 andUnreadPostCount:0 andUnreadInviteCount:0];
		[OpenFeint setPendingFriendsCount:0];
		[OFAnnouncementService clearLocalAnnouncements];

		UIViewController* topController = instance->mOFRootController.contentController;
		if([topController isKindOfClass:[OFTabBarController class]])
		{
			OFTabBarController* tabController = (OFTabBarController*)topController;
			[tabController showTabViewControllerNamed:OpenFeintDashBoardTabNowPlaying showAtRoot:YES];
			OFFramedNavigationController* navController = (OFFramedNavigationController*) tabController.tabBar.selectedViewController;
			[OFTabbedDashboardController setOfflineMode:tabController];

			if ([[navController topViewController] isKindOfClass:[OFGameProfileController class]])
			{
				[(OFGameProfileController*)[navController topViewController] refreshView];
			}

			if (instance->mOFRootController.modalViewController != nil)
			{
				[instance->mOFRootController dismissModalViewControllerAnimated:YES];
			}
		}
	// needs testing
	//	else
	//	{
	//		[OpenFeint presentRootControllerWithTabbedDashboard:OpenFeintDashBoardTabNowPlaying pushControllers:nil];
	//	}
	
		instance->_openFeintFlags.isOpenFeintDashboardInOnlineMode = NO;
	}
}

+ (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if(instance->mIsDashboardDismissing)
	{
		instance->mIsDashboardDismissing = false;
		
		[OpenFeint destroyDashboard];

		if (instance->mQueuedRootModal)
		{
			if (instance->mIsQueuedModalAnOverlay)
				[OpenFeint presentModalOverlay:instance->mQueuedRootModal];
			else
				[OpenFeint presentRootControllerWithModal:instance->mQueuedRootModal];

			OFSafeRelease(instance->mQueuedRootModal);
		}
	}
	else
	{
		[OpenFeint dashboardDidAppear];
	}
}

+ (void)dismissRootController
{
	if (![OpenFeint isShowingFullScreen])
	{
		return;
	}
	
	OpenFeint* instance = [OpenFeint sharedInstance];

	instance->mIsDashboardDismissing = true;
	
	if(instance->mIsShowingOverlayModal)
	{
		UIView* backgroundView = OFViewHelper::findViewByTag(instance->mOFRootController.view, kOverlayBackgroundViewTag);
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5f];
		backgroundView.alpha = 0.0f;
		[UIView commitAnimations];
	}

	[instance->mOFRootController hideController];
			
	[self dashboardWillDisappear];
}
	
+ (void)dismissRootControllerOrItsModal
{
	if (![OpenFeint isShowingFullScreen])
	{
		return;
	}
	
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance->mOFRootController.modalViewController != nil)
	{
		[instance->mOFRootController dismissModalViewControllerAnimated:YES];
	}
	else
	{
		[OpenFeint dismissRootController];
	}	

	if (instance->_openFeintFlags.isConfirmAccountFlowActive)
	{
		instance->_openFeintFlags.isConfirmAccountFlowActive = NO;

		if (instance->_openFeintFlags.hasDeferredLoginDelegate)
		{
			[instance _invokeLoggedInDelegate];
		}
	}
}

+ (UIWindow*)getTopApplicationWindow
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	
	if (instance && instance->mPresentationWindow)
		return instance->mPresentationWindow;

	UIApplication* clientApp = [UIApplication sharedApplication];
	
	NSAssert([[clientApp windows] count] > 0, @"Your application must have at least one window set before launching OpenFeint");
	UIWindow* topWindow = [clientApp keyWindow];
	if (!topWindow)
	{
		OFLog(@"OpenFeint found no key window. Uses first available window instead."); 
		topWindow = [[clientApp windows] objectAtIndex:0];
	}
	
	return topWindow;
}

+ (id<OpenFeintDelegate>)getDelegate
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	
	if(instance->mLaunchDelegate)
	{
		return instance->mLaunchDelegate;
	}
	
	return instance->mDelegatesContainer.openFeintDelegate;
}

+ (id<OFNotificationDelegate>)getNotificationDelegate
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	return instance->mDelegatesContainer.notificationDelegate;
}

+ (id<OFChallengeDelegate>)getChallengeDelegate
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	return instance->mDelegatesContainer.challengeDelegate;
}

+ (id<OFBragDelegate>)getBragDelegate
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	return instance->mDelegatesContainer.bragDelegate;
}

+ (UIInterfaceOrientation)getDashboardOrientation
{
	return [OpenFeint sharedInstance] ? [OpenFeint sharedInstance]->mDashboardOrientation : UIInterfaceOrientationPortrait;
}

+ (BOOL)isInLandscapeMode
{
    if ([OpenFeint isLargeScreen]) return YES; // Force landscape assets and configuration for large screen formats
	UIInterfaceOrientation activeOrientation = [OpenFeint getDashboardOrientation];
	return activeOrientation == UIInterfaceOrientationLandscapeLeft || activeOrientation == UIInterfaceOrientationLandscapeRight;
}

+ (BOOL)isInLandscapeModeOniPad
{
    return UIInterfaceOrientationIsLandscape([self getDashboardOrientation]);
}

+ (BOOL)isLargeScreen
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    return (CGRectGetMaxX(screenBounds) >= 768);
}

+ (CGRect)getDashboardBounds
{
	CGRect dashboardBounds = [[UIScreen mainScreen] bounds];
    if ([OpenFeint isLargeScreen])
    {
        dashboardBounds = CGRectMake(3.f, 3.f, 640.f, 480.f);
    }
    else
    {
        if ([OpenFeint isInLandscapeMode])
        {
            dashboardBounds = CGRectMake(dashboardBounds.origin.x, dashboardBounds.origin.y, dashboardBounds.size.height, dashboardBounds.size.width);
        }
    }
    
	return dashboardBounds;
}


+ (void)destroyDashboard
{
	[self dashboardDidDisappear];

	OpenFeint* instance = [OpenFeint sharedInstance];
    
    [instance->mOFRootController cleanupSubviews];
	[instance->mOFRootController dismissModalViewControllerAnimated:NO];
	[instance->mOFRootController.view removeFromSuperview];
	OFSafeRelease(instance->mOFRootController);
	
	instance->mLaunchDelegate = nil;
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	[[OFImageCache sharedInstance] purge];
}

+ (void)updateApplicationBadge
{
	NSInteger badgeNumber = [OpenFeint unviewedChallengesCount];
	[UIApplication sharedApplication].applicationIconBadgeNumber = badgeNumber;
}

+ (OpenFeint*) sharedInstance
{
	return gInstance;
}

+ (UIView*)getTopLevelView
{
	OFRootController* root = (OFRootController*)[OpenFeint getRootController];
	if ([root contentController])
	{
		return [root contentController].view;
	}

	return [root view];
}

+ (OFRootController*)getRootController
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	return instance ? instance->mOFRootController : nil;
}

+ (bool)isShowingFullScreen
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance && instance->mOFRootController)
	{
		return !instance->mIsDashboardDismissing && instance->mOFRootController.contentController;
	}

	return false;
}

+ (bool)isDashboardHubOpen
{
	return [self isShowingFullScreen] && [gInstance->mOFRootController.contentController isKindOfClass:[OFTabbedDashboardController class]];
}

+ (UINavigationController*)getActiveNavigationController
{
	OpenFeint* instance = [OpenFeint sharedInstance];	
	
	UIViewController* visibleViewController = instance->mOFRootController.modalViewController;
	if (visibleViewController && [visibleViewController isKindOfClass:[UINavigationController class]])
	{
		return (UINavigationController*)visibleViewController;
	}
	
	visibleViewController = instance->mOFRootController.contentController;
	
	if([visibleViewController isKindOfClass:[UINavigationController class]])
	{
		return (UINavigationController*)visibleViewController;
	}
    else if([visibleViewController isKindOfClass:[OFIntroNavigationController class]])
    {
        return [(OFIntroNavigationController*)visibleViewController navController];
    }
	else if([visibleViewController isKindOfClass:[OFTabBarController class]])
	{
		OFTabBarController* tabBarController = (OFTabBarController*)visibleViewController;
		UIViewController* selectedTab = [[tabBarController tabBar] selectedViewController];
		
		if([selectedTab isKindOfClass:[UINavigationController class]])
		{
			return (UINavigationController*)selectedTab;
		}			
	}
		
	return nil;
}

+ (void)reloadInactiveTabBars
{
	OpenFeint* instance = [OpenFeint sharedInstance];	
	
	UIViewController* topController = instance->mOFRootController.contentController;
	if([topController isKindOfClass:[OFTabBarController class]])
	{
		OFTabBarController* tabController = (OFTabBarController*)topController;
		for (OFTabBarItem* tabItem in tabController.tabBarItems)
		{
			UIViewController* tabPageController = tabItem.viewController;
			if (tabPageController && [tabPageController isKindOfClass:[UINavigationController class]])
			{
				UINavigationController* nestedNavController = (UINavigationController*)tabPageController;

				if (tabPageController != [[tabController tabBar] selectedViewController])
				{
					[nestedNavController popToRootViewControllerAnimated:NO];
					if ([nestedNavController.topViewController isKindOfClass:[OFTableControllerHelper class]])
					{
						OFTableControllerHelper* tableController = (OFTableControllerHelper*)nestedNavController.topViewController;
						[tableController reloadDataFromServer];
					}
				}

				if ([nestedNavController isKindOfClass:[OFFramedNavigationController class]])
				{
					[(OFFramedNavigationController*)nestedNavController refreshProfile];
				}
			}
		}
	}
}

+ (void)_delayedPushViewController:(UIViewController*)errorController inNavController:(UINavigationController*)activeNavController
{
	[OpenFeint sharedInstance]->mIsErrorPending = NO;
	[activeNavController pushViewController:errorController animated:YES];
}

+ (void)displayErrorMessage:(UIViewController*)errorController inNavController:(UINavigationController*)activeNavController
{
	if ([OpenFeint sharedInstance]->mAllowErrorScreens == NO)
		return;

	if ([OpenFeint isShowingErrorScreenInNavController:activeNavController])
	{
		return;
	}
	
	// citron note: The navigation controller system doesn't behave properly if you push
	//				a view, pop a view, and push again all while it's trying to animate one of its views.
	//				By adding a slight delay here, we prevent the user from spamming actions which cause
	//				visual artifiacts in the navigation bar.
	SEL delayedPushSelector = @selector(_delayedPushViewController:inNavController:);
	NSInvocation* delayedPush = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:delayedPushSelector]];
	[delayedPush setSelector:delayedPushSelector];
	[delayedPush setTarget:self];
	[delayedPush setArgument:&errorController atIndex:2];
	[delayedPush setArgument:&activeNavController atIndex:3];	
	[delayedPush retainArguments];	
	const float enoughTimeForViewControllerAnimationsToPlay = 0.1f;
	[delayedPush performSelector:@selector(invoke) withObject:nil afterDelay:enoughTimeForViewControllerAnimationsToPlay];
	
	[OpenFeint sharedInstance]->mIsErrorPending = YES;
}

+ (void)allowErrorScreens:(BOOL)allowed
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance)
	{
		instance->mAllowErrorScreens = allowed;
	}
}

+ (BOOL)areErrorScreensAllowed
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance)
	{
		return instance->mAllowErrorScreens;
	}
	
	return NO;
}

+ (BOOL)isShowingErrorScreenInNavController:(UINavigationController*)navController
{
	if (![OpenFeint sharedInstance])
		return NO;
		
	UIViewController* currentViewController = [navController visibleViewController];
	UIViewController* incomingViewController = (UIViewController*)[navController.viewControllers lastObject];
	
	const bool isTopAnError = [currentViewController isKindOfClass:[OFDeadEndErrorController class]];
	const bool isAnimatingInAnError = [incomingViewController isKindOfClass:[OFDeadEndErrorController class]];
	if(isAnimatingInAnError || isTopAnError || [OpenFeint sharedInstance]->mIsErrorPending)
	{
		return YES;
	}
	
	return NO;
}

+ (void)displayUpgradeRequiredErrorMessage:(NSData*)data
{
	if([OpenFeint isShowingFullScreen])
	{
		OFXmlDocument* errorDocument = [OFXmlDocument xmlDocumentWithData:data];
		NSString* message = [errorDocument getElementValue:"error_message"];
		message = [NSString stringWithFormat:message, [OpenFeint applicationDisplayName]];
		
		UIViewController* viewController = [OFDeadEndErrorController deadEndErrorWithMessage:message];
		viewController.navigationItem.hidesBackButton = YES;

		UINavigationController* activeNavController = [self getActiveNavigationController];
		[OpenFeint displayErrorMessage:viewController inNavController:activeNavController];
	}
}

+ (void)displayServerMaintenanceNotice:(NSData*)data
{
	if([OpenFeint isShowingFullScreen])
	{
		UINavigationController* activeNavController = [self getActiveNavigationController];
		[self displayErrorMessage:[OFServerMaintenanceNoticeController maintenanceControllerWithHtmlData:data] inNavController:activeNavController];
	}
}

+ (void)displayErrorMessage:(NSString*)message
{
	if([OpenFeint isShowingFullScreen])
	{
		UINavigationController* activeNavController = [self getActiveNavigationController];
		if (![OpenFeint isDashboardHubOpen] || OFReachability::Instance()->isGameServerReachable())
		{
			[self displayErrorMessage:[OFDeadEndErrorController deadEndErrorWithMessage:message] inNavController:activeNavController];
		}
		else
		{
			[self displayErrorMessage:[OFDeadEndErrorController deadEndErrorWithMessageAndOfflineButton:message] inNavController:activeNavController];
		}
	}
}

+ (void)displayErrorMessageAndOfflineButton:(NSString*)message
{
	if([OpenFeint isShowingFullScreen])
	{
		UINavigationController* activeNavController = [self getActiveNavigationController];
		[self displayErrorMessage:[OFDeadEndErrorController deadEndErrorWithMessageAndOfflineButton:message] inNavController:activeNavController];
	}
}

+ (OFProvider*)provider
{
	OpenFeint* instance = [self sharedInstance];
	if (instance)
		return instance->mProvider;
		
	return nil;
}

+ (OFSession*)session
{
	OpenFeint* instance = [self sharedInstance];
	if (instance)
		return instance->mSession;
		
	return nil;
}

+ (bool)isTargetAndSystemVersionThreeOh
{
#ifdef __IPHONE_3_0
	return is3PointOhSystemVersion();
#else
	return false;	
#endif
}

+ (bool)isTargetAndSystemVersionFourOh
{
#ifdef __IPHONE_4_0
	return is4PointOhSystemVersion();
#else
	return false;	
#endif
}

+ (void) dashboardDidAppear
{
	[OpenFeint sharedInstance].dashboardVisible = YES;
	[self dashboardLaunched];
	OF_OPTIONALLY_INVOKE_DELEGATE([OpenFeint getDelegate], dashboardDidAppear);	
}

+ (void)dashboardDidDisappear
{
	[OpenFeint sharedInstance].dashboardVisible = NO;
	[OpenFeint dashboardClosed];
	// Wait until the dashboard has fully disappeared before reserving memory,
	// so that we don't attempt to grab memory until there's memory to grab.
	[self reserveMemory];
	
	OF_OPTIONALLY_INVOKE_DELEGATE([OpenFeint getDelegate], dashboardDidDisappear);
}

+ (void) dashboardWillAppear
{	
	[OpenFeint sharedInstance]->mPreviousOrientation = [UIApplication sharedApplication].statusBarOrientation;
	[OpenFeint sharedInstance]->mPreviousStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
	
	[[UIApplication sharedApplication] OFhideStatusBar:![OpenFeint isLargeScreen] animated:YES]; 
	
	[[UIApplication sharedApplication] setStatusBarOrientation:[OpenFeint sharedInstance]->mDashboardOrientation];	

	// Release any memory we've reserved so that we actually have room to allocate the
	// dashboard into.
	[self releaseReservedMemory];
	
	OF_OPTIONALLY_INVOKE_DELEGATE([OpenFeint getDelegate], dashboardWillAppear);
}

+ (void)dashboardWillDisappear
{
	UIApplication* clientApp = [UIApplication sharedApplication];
	
	if (![OpenFeint isLargeScreen])
	{
		[clientApp setStatusBarOrientation:[OpenFeint sharedInstance]->mPreviousOrientation animated:YES];
	}

	[clientApp OFhideStatusBar:[OpenFeint sharedInstance]->mPreviousStatusBarHidden animated:YES];
	
	OF_OPTIONALLY_INVOKE_DELEGATE([OpenFeint getDelegate], dashboardWillDisappear);
}

+ (void)reserveMemory
{
#ifdef OPENFEINT_MEMORY_PAD_ENABLED
	OFAssert([OpenFeint sharedInstance]->mReservedMemory == NULL, "Unbalanced reserve memory requests.");

	[OpenFeint sharedInstance]->mReservedMemory = malloc(kOFReservedMemorySize);

	// It's necessary to actually touch all the memory so that the VMM actually
	// commits all the pages.
	bzero([OpenFeint sharedInstance]->mReservedMemory, kOFReservedMemorySize);
#endif
}

+ (void)releaseReservedMemory
{
#ifdef OPENFEINT_MEMORY_PAD_ENABLED
	OFAssert([OpenFeint sharedInstance]->mReservedMemory != NULL, "Unbalanced reserve memory requests.");
	
	free([OpenFeint sharedInstance]->mReservedMemory);
	[OpenFeint sharedInstance]->mReservedMemory = NULL;
#endif
}

+ (void)setPollingFrequency:(NSTimeInterval)frequency
{
	[[OpenFeint sharedInstance]->mPoller changePollingFrequency:frequency];
}

+ (void)setPollingToDefaultFrequency
{
	[[OpenFeint sharedInstance]->mPoller resetToDefaultPollingFrequency];
}

+ (void)stopPolling
{
	[[OpenFeint sharedInstance]->mPoller stopPolling];
}

+ (void)forceImmediatePoll
{
	[[OpenFeint sharedInstance]->mPoller pollNow];
}

+ (void)clearPollingCacheForClassType:(Class)resourceClassType
{
	[[OpenFeint sharedInstance]->mPoller clearCacheForResourceClass:resourceClassType];
}

+ (void)setupOfflineDatabase
{
    NSString* dbName = @"feint_offline";

    if([OpenFeint clientApplicationId] == nil
             || [[OpenFeint clientApplicationId] isEqualToString:@"0"]
             || [[OpenFeint clientApplicationId] isEqualToString:@""])
    {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"OpenFeint Developer Warning"
                                                     message:@"OpenFeint 2.5 and greater requires an offline config.  You can download an offline config from your app page in the developer dashboard"
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
        [av show];
        [av release];
    }
    else
    {
        dbName = [NSString stringWithFormat:@"feint_offline_%@", [OpenFeint clientApplicationId]];
    }

	if (SQLITE_OK != sqlite3_open([OFTransactionalSaveFile::getSavePathForFile(dbName) UTF8String], &[OpenFeint sharedInstance]->mOfflineDatabaseHandle))
	{
		OFAssert(false, "Failed to initialize offline database!");
		[OpenFeint sharedInstance]->mOfflineDatabaseHandle = nil;
	}
	if (SQLITE_OK != sqlite3_open([OFTransactionalSaveFile::getSavePathForFile(dbName) UTF8String], &[OpenFeint sharedInstance]->mBootstrapOfflineDatabaseHandle))
	{
		OFAssert(false, "Failed to initialize offline database!");
		[OpenFeint sharedInstance]->mBootstrapOfflineDatabaseHandle = nil;
	}

}

+ (void)teardownOfflineDatabase
{
	if (SQLITE_BUSY == sqlite3_close([OpenFeint sharedInstance]->mOfflineDatabaseHandle))
	{
		OFLog(@"Not all SQLite memory has been released in offline database!");
	}
	if (SQLITE_BUSY == sqlite3_close([OpenFeint sharedInstance]->mBootstrapOfflineDatabaseHandle))
	{
		OFLog(@"Not all SQLite memory has been released in offline database!");
	}
}

+ (struct sqlite3*)getOfflineDatabaseHandle
{
	return [OpenFeint sharedInstance]->mOfflineDatabaseHandle;
}

+ (struct sqlite3*)getBootstrapOfflineDatabaseHandle
{
	return [OpenFeint sharedInstance]->mBootstrapOfflineDatabaseHandle;
}

+ (BOOL)allowUserGeneratedContent
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (!instance)
		return NO;

	BOOL allowed = !([OpenFeint session].currentDevice.parentalControls.enabled);
	allowed = allowed && !instance->mDeveloperDisabledUGC;
	
	return allowed;
}

+ (BOOL)allowLocationServices
	{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (!instance)
		return NO;
		
	BOOL allowed = !([OpenFeint session].currentDevice.parentalControls.enabled);
	allowed = allowed && !instance->mDeveloperDisabledLocationServices;
	
	return allowed;
}

+ (ENotificationPosition)notificationPosition
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance)
	{
		return instance->mNotificationPosition;
	}
	
	return ENotificationPosition_BOTTOM_LEFT;
}

+ (BOOL)invertNotifications
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance)
	{
		return (instance->mNotificationPosition == ENotificationPosition_TOP_LEFT ||
				instance->mNotificationPosition == ENotificationPosition_TOP_RIGHT);
	}
	
	return NO;
}

+ (CLLocation*) getUserLocation
{
	CLLocation* userLoc = nil;
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance)
	{
		userLoc = instance->mLocation.userLocation;
	}
	return userLoc;
}

+ (void) setUserLocation:(OFLocation*)userLoc
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (instance)
	{
		OFSafeRelease(instance->mLocation);
		instance->mLocation = [userLoc retain];
	}
}

+ (void) startLocationManagerIfAllowed
{
	OFUserDistanceUnitType userDistanceUnit = [OpenFeint userDistanceUnit];
	if ( userDistanceUnit != kDistanceUnitNotAllowed && [OpenFeint hasUserApprovedFeint] ) 
	{
		OpenFeint* instance = [OpenFeint sharedInstance];
		if (instance)
		{
			OFSafeRelease(instance->mLocation);
			instance->mLocation = [[[OFLocation alloc] init] retain];
		}
	}
}

+ (NSString*)sessionId
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (!instance)
		return @"0";

	return instance->mSessionId;
}

+ (NSDate*)sessionStartDate
{
	OpenFeint* instance = [OpenFeint sharedInstance];
	if (!instance)
		return [NSDate date];

	return instance->mSessionStartDate;
}

+ (OFRequestHandle*)getImageFromUrl:(NSString*)url cachedImage:(UIImage*&)image httpService:(OFPointer<OFHttpService>&)service httpObserver:(OFPointer<OFImageViewHttpServiceObserver>&)observer target:(NSObject<OFCallbackable>*)target onDownloadSuccess:(SEL)success onDownloadFailure:(SEL)failure
{
	image = [[OFImageCache sharedInstance] fetch:url];
	
	OFRequestHandle* handle = nil;
	if(!image)
	{
		handle = [OpenFeint downloadImageFromUrl:url
									 httpService:service
									httpObserver:observer
									   onSuccess:OFDelegate(target, success)
									   onFailure:OFDelegate(target, failure)];
	}
	return handle;
}

+ (OFRequestHandle*)downloadImageFromUrl:(NSString*)url httpService:(OFPointer<OFHttpService>&)service httpObserver:(OFPointer<OFImageViewHttpServiceObserver>&)observer onSuccess:(OFDelegate const&)success onFailure:(OFDelegate const&)failure
{	
	[self destroyHttpService:service];
	
	bool absoluteUrl = [url hasPrefix:@"http"] || [url hasPrefix:@"www"];
	service = absoluteUrl ? OFPointer<OFHttpService>(new OFHttpService(@"")) : [OFProvider createHttpService];
	observer = new OFImageViewHttpServiceObserver(success, failure);
	OFHttpRequest* httpRequest = service->startRequest(url, HttpMethodGet, nil, observer.get());
	return [OFRequestHandle requestHandle:httpRequest];
}

+ (void)destroyHttpService:(OFPointer<OFHttpService>&)service
{
	if (service.get() != NULL)
	{
		service->cancelAllRequests();
		service.reset(NULL);
	}
}

- (void)_rotateDashboardFromOrientation:(UIInterfaceOrientation)oldOrientation toOrientation:(UIInterfaceOrientation)newOrientation
{
	if (![OpenFeint isLargeScreen])
		return;

	CGFloat duration = 0.4f;
	
	if (mSnapDashboardRotation)
	{
		duration = 0.0f;
	}
	
	if (UIInterfaceOrientationIsLandscape(oldOrientation) == UIInterfaceOrientationIsLandscape(newOrientation))
	{
		duration *= 2.f;
	}

	if (mOFRootController != nil)
	{
		[UIView beginAnimations:@"OFInterfaceOrientationRotate" context:nil];
		[UIView setAnimationDuration:duration];
		[OpenFeint transformView:mOFRootController.view toOrientation:newOrientation];
		[OpenFeint postDashboardOrientationChangedTo:newOrientation from:oldOrientation];
		[UIView commitAnimations];
	}
}

+ (NSBundle*)getResourceBundle
{
	static NSBundle * bundle = nil;
	if (!bundle)
	{
		NSArray * bundleNames = [NSArray arrayWithObjects:
								 @"OFResources_Universal",
								 @"OFResources_iPhone_Universal",
								 @"OFResources_iPad",
								 @"OFResources_iPhone_Portrait",
								 @"OFResources_iPhone_Landscape",
								 nil];
		
		for (NSString * bundleName in bundleNames)
		{
			NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
			if (bundlePath)
			{
				bundle = [NSBundle bundleWithPath:bundlePath];
				if (bundle)
				{
					break;
				}
			}
		}
		
		if (!bundle)
		{
			bundle = [NSBundle mainBundle];
		}
		[bundle retain];
	}
	
	return bundle;
}

@end
