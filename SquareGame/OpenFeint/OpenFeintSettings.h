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

#pragma once

////////////////////////////////////////////////////////////
///
/// NSNumber UIInterfaceOrientation
///
/// 	Default: UIInterfaceOrientationPortrait
///
/// 	Defines what orientation the OpenFeint dashboard launches in. The dashboard does not auto rotate.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingDashboardOrientation;


////////////////////////////////////////////////////////////
///
/// NSString 
///
/// Your application's (short) display name.
///
/// 	Used as the game tab's title
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingShortDisplayName;

////////////////////////////////////////////////////////////
///
/// NSNumber bool
///
/// Default: false 
///
/// Behavior: 	Allows this application to send and receive Push Notifications. Only available on OS 3.0.
///				If set to true you must call OpenFeint::applicationDidRegisterForRemoteNotificationsWithDeviceToken
///				and OpenFeint::applicationDidFailToRegisterForRemoteNotifications from your UIApplicationDelegate.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingEnablePushNotifications;

////////////////////////////////////////////////////////////
///
/// NSNumber bool
///
/// Default: false 
///
/// Behavior: 	If this setting is enabled the game will function as if the device has parental controls enabled.
///				This means that forums, chat, IM, profile pictures are all disabled.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingDisableUserGeneratedContent;

////////////////////////////////////////////////////////////
///
/// NSNumber ENotificationPosition. see OpenFeint.h
///
/// Default: ENotificationPosition_TOP_LEFT on iPad,  ENotificationPosition_TOP on iPhone.
///
/// Behavior: 	iPhone:
///				ENotificationPosition_TOP:			iPhone notifications show up on the top of the screen
///				ENotificationPosition_BOTTOM:		iPhone notifications show up on the bottom of the screen
///				
///				iPad:
///				ENotificationPosition_BOTTOM_LEFT:	iPad notifications show up on the lower left corner of the screen
///				ENotificationPosition_TOP_LEFT:		iPad notifications show up on the top left corner of the screen
///				ENotificationPosition_BOTTOM_RIGHT:	iPad notifications show up  on the bottom right corner of the screen
///				ENotificationPosition_TOP_RIGHT:	iPad notifications show up on the top right of the screen
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingNotificationPosition;

////////////////////////////////////////////////////////////
///
/// NSNumber bool
///
/// Default: false 
///
/// Behavior: 	If this is true then the application will prompt the user to approve OpenFeint every time the
///				application launches in DEBUG mode only. This makes testing custom approval screens easier.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingAlwaysAskForApprovalInDebug;

////////////////////////////////////////////////////////////
///
/// NSNumber bool
///
/// Default: false 
///
/// Behavior: 	If this is false, then OpenFeint will check to make sure you're handling dashboard notifications
///				in DEBUG mode only, and give you a message if you aren't.  If this is fully intentional you
///				can set this to true; however it is strongly recommended that you implement these delegate
///				methods to pause and unpause your game when the dashboard comes up.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingDisableIncompleteDelegateWarning;

////////////////////////////////////////////////////////////
///
/// UIWindow
///
/// Default: nil
///
/// Behavior: 	You can specify a UIWindow here which will be the window that OpenFeint launches it's dashboard
///				in and the window that OpenFeint displays it's notification views in. If you *do not* specify a
///				UIWindow here OpenFeint will choose the UIApplication's keyWindow, and failing that it will
///				choose the first of the UIApplication's UIWindow objects.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingPresentationWindow;

////////////////////////////////////////////////////////////
///
/// NSString
///
/// Default: nil
///
/// Behavior: 	If this setting is present then OpenFeint will attempt to authenticate as the specified user id
///				during the initialization process.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingInitialUserId;

////////////////////////////////////////////////////////////
///
/// NSString
///
/// Default: nil
///
/// Behavior: 	If this setting is present, then OpenFeint will attempt to load nibs with the given suffix
///				before attempting to load nibs with its default suffix ("Of").  You can use this if you want
///				to override specific controller nibs within OpenFeint with your own.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingOverrideSuffixString;

////////////////////////////////////////////////////////////
///
/// NSString
///
/// Default: nil
///
/// Behavior: 	If this setting is present, then OpenFeint will attempt to instantiate classes with the given
///				prefix before attempting to instantiate classes with its default prefix ("OF").  You can use
///				this if you want to override specific UI classes within OpenFeint with your own.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingOverrideClassNamePrefixString;

////////////////////////////////////////////////////////////
///
/// NSString
///
/// Default: nil
///
/// Behavior: 	If this setting is present and set to YES blobs will not be compressed before uploaded to the cloud. 
///				It is recomended to use this only if your data is already in a very compact format that will not compress.
//				To find out how well your data compresses pass in the OpenFeintSettingOutputCloudStorageCompressionRatio setting.
///
///				NOTE: This flag applies to ALL of your cloud storage. You can not selectively use compression. If you're not sure
///					  if you should use compression or not then it's safest to leave it enabled
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingDisableCloudStorageCompression;

////////////////////////////////////////////////////////////
///
/// NSString
///
/// Default: nil
///
/// Behavior: 	If this setting is present and set to YES then OpenFeint will output the compression ratio of all compressed blobs to the console
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingOutputCloudStorageCompressionRatio;

////////////////////////////////////////////////////////////
///
/// NSString
///
/// Default: nil
///
/// Behavior: 	If this setting is present and set to YES then OpenFeint will output
///             cloud storage blobs without the compression header.   This is intended for compatibiity with products
///             already using the older compression, which did not include a header.   This should not be enabled for
///             any new projects.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingCloudStorageLegacyHeaderlessCompression;

////////////////////////////////////////////////////////////
/// NSNumber bool
///
/// Default: no
///
/// Behavior: 	If this is marked yes, then OpenFeint will post achievement updates and leaderboard updates
///				to both OpenFeint server and if there is a mapping in OFGameCenter.plist, also post them to
///				GameCenter.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingGameCenterEnabled;

////////////////////////////////////////////////////////////
///
/// NSNumber bool
///
/// Default: NO
///
/// Behavior: 	If this setting is present and set to YES then OpenFeint only work if the player is online
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingRequireOnlineStatus;

////////////////////////////////////////////////////////////
///
/// NSNumber bool
///
/// Default: YES
///
/// Behavior: 	If this setting is present and set to NO, the user will not be prompted to login at application start
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingPromptUserForLogin;

////////////////////////////////////////////////////////////
///
/// NSNumber bool
///
/// Default: NO
///
/// Behavior: 	If this setting is present and set to YES, location services will not be enabled
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingDisableLocationServices;

////////////////////////////////////////////////////////////
///
/// NSNumber bool
///
/// Default: NO
///
/// Behavior: 	If this setting is present and set to YES,
///				the dashboard will snap instead of rotating smoothly when the interface orientation changes.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingSnapDashboardRotation;

////////////////////////////////////////////////////////////
///
/// NSNumber bool
///
/// Default: NO
///
/// Behavior: 	If this setting is present and set to YES,
///				push notifications sent through OpenFeint will use the sandbox server instead of the
///				production server.  It is recommended that you use this while using these features
///				in a development environment, but this should not be turned on in the shipped game.
///
////////////////////////////////////////////////////////////
extern NSString* OpenFeintSettingUseSandboxPushNotificationServer;
