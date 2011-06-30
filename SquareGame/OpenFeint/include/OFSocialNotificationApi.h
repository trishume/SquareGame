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

@class OFRequestHandle;
@class OFAchievement;
@class OFHighScore;
@class OFLeaderboard;

@protocol OFSocialNotificationApiDelegate;
@protocol OFSocialNotificationSubmitTextOverrideDelegate;

//////////////////////////////////////////////////////////////////////////////////////////
/// The public interface for OFSocialNotificationApi allows you to post notifications to
/// social networks if the user is connected via OpenFeint to a social network.
//////////////////////////////////////////////////////////////////////////////////////////
@interface OFSocialNotificationApi : NSObject

//////////////////////////////////////////////////////////////////////////////////////////
/// Set a delegate for all OFSocialNotifications related actions. Must adopt the 
/// OFSocialNotificationApiDelegate protocol.
///
/// @note Defaults to nil. Weak reference.
//////////////////////////////////////////////////////////////////////////////////////////
+ (void)setDelegate:(id<OFSocialNotificationApiDelegate>)delegate;

//////////////////////////////////////////////////////////////////////////////////////////
/// Set a url for social notifications you post through the api.  This will be linked to 
/// social notification posts.
///
/// @param url			the url linked on social notifications.
//////////////////////////////////////////////////////////////////////////////////////////
+ (void)setCustomUrl:(NSString*)url;

//////////////////////////////////////////////////////////////////////////////////////////
/// Prompt the current user to post to social networks.
///
/// @param text			The prepopulated text that is not editable in the message.
/// @param message		The suggested message for the user to send.  This is editable by the user.  If you set this parameter to nil, OpenFeint
///						fills in placeholder text of "Add a Message!".  The place holder text will not be sent along with the social notification.
/// @param imageName	Name of the image on the developer dashboard.
///
/// @note imageName can be nil if there is no image to post.
//////////////////////////////////////////////////////////////////////////////////////////
+ (void)sendWithPrepopulatedText:(NSString*)text originalMessage:(NSString*)message imageNamed:(NSString*)imageName;

//////////////////////////////////////////////////////////////////////////////////////////
/// @internal
//////////////////////////////////////////////////////////////////////////////////////////
+ (void)sendSuccess;
+ (void)sendFailure;

@end


//////////////////////////////////////////////////////////////////////////////////////////
/// Adopt the OFSocialNotificationApiDelegate Protocol to receive information regarding 
/// OFSocialNotifications.  You must call OFSocialNotification's +(void)setDelegate: method to receive
/// information.
//////////////////////////////////////////////////////////////////////////////////////////
@protocol OFSocialNotificationApiDelegate<NSObject>
@optional
//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked by an OFSocialNotificationApi class when sendWithPrepopulatedText successfully 
/// completes.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didSendSocialNotification;

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked by an OFSocialNotificationApi class when sendWithPrepopulatedText fails.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didFailSendSocialNotification;

@end
