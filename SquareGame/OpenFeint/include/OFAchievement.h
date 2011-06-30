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

#import "OFResource.h"
#import "OFSqlQuery.h"

@class OFRequestHandle;
class OFHttpService;
class OFImageViewHttpServiceObserver;

@protocol OFAchievementDelegate;

//////////////////////////////////////////////////////////////////////////////////////////
///	The public interface for OFAchievement exposes information about a particular 
/// achievement and it's unlock state for the local user
//////////////////////////////////////////////////////////////////////////////////////////
@interface OFAchievement : OFResource<OFCallbackable>
{
@private
	NSString* title;
	NSString* description;
	NSUInteger gamerscore;
	NSString* iconUrl;
	BOOL isSecret;
	double percentComplete;
	NSDate* unlockDate;
	
	BOOL isUnlockedByComparedToUser;
	NSString* comparedToUserId;
	
	NSString* endVersion;
	NSString* startVersion;
	NSUInteger position;	
	
	OFPointer<OFHttpService> mHttpService;
	OFPointer<OFImageViewHttpServiceObserver> mHttpServiceObserver;
}
//////////////////////////////////////////////////////////////////////////////////////////
/// Set a delegate for all OFAchievement related actions. Must adopt the 
/// OFAchievementDelegate protocol.
///
/// @note Defaults to nil. Weak reference
//////////////////////////////////////////////////////////////////////////////////////////
+ (void)setDelegate:(id<OFAchievementDelegate>)delegate;

//////////////////////////////////////////////////////////////////////////////////////////
/// Retrieves all of the achievements for this application.
///
/// @note The returned achievements will contain unlock information for the local user.
///
/// @return NSArray populated with OFAchievement objects representing each achievement 
//////////////////////////////////////////////////////////////////////////////////////////
+ (NSArray*)achievements;

//////////////////////////////////////////////////////////////////////////////////////////
/// Retrieves a achievement based on the achievement id on the developer dashboard
///
/// @param achievementID	The leaderboard id
///
/// @return OFAchievement corresponding to the achievement id
//////////////////////////////////////////////////////////////////////////////////////////
+ (OFAchievement*)achievement:(NSString*)achievementId;

//////////////////////////////////////////////////////////////////////////////////////////
/// Submits all deferred achievement unlocks to the server
///
/// @note Invokes -(void)didSubmitDeferredAchievements on success and
///			-(void)didFailSubmittingDeferredAchievements: on failure.
///
/// @return OFRequestHandle for the server request.  Use this to cancel the request. nil if there were no deferred unlocks
//////////////////////////////////////////////////////////////////////////////////////////
+ (OFRequestHandle*)submitDeferredAchievements;

//////////////////////////////////////////////////////////////////////////////////////////
/// Set a url to goto when someone clicks the social post.
//////////////////////////////////////////////////////////////////////////////////////////
+ (void)setCustomUrlForSocialNotificaion:(NSString*)url;

//////////////////////////////////////////////////////////////////////////////////////////
/// Updates the progression of an achievement.  Set to 100.0f to unlock the achievement
///
/// @param float updatePercentComplete.  Number between 0.0f and 100.0f for which you would like to update the progression of this achievement.
///
/// @return OFRequestHandle for the server request.  Use this to cancel the request
///
/// @note Invokes	- (void)didUpdateProgressionCompleteOFAchievement:(OFAchievement*)achievement; on success and
///					- (void)didFailUpdateProgressionCompleteOFAchievement:(OFAchievement*)achievement; on failure
//////////////////////////////////////////////////////////////////////////////////////////
- (OFRequestHandle*)updateProgressionComplete:(double)updatePercentComplete andShowNotification:(BOOL)showUpdateNotification;

//////////////////////////////////////////////////////////////////////////////////////////
/// Updates an achievement's progression for the current user, but deffers the submition of this information
/// to the server until "submitDeferredAchievements" is called in your app.
///
/// @param float updatePercentComplete.  Number between 0.0f and 100.0f for which you would like to update the progression of this achievement.
///
/// @note	If you defer achievements, the user will still see the achievement unlock
///			immediately and it will be stored locally that it is unlocked.  If the user
///			quits the app before you have a chance to submit the defered achievments,
///			the next time the app is started up online and logged into OpenFeint, we will
///			sync to the server automatically all defered achievements from previous games.
///
//////////////////////////////////////////////////////////////////////////////////////////
- (void)deferUpdateProgressionComplete:(double)updatePercentComplete andShowNotification:(BOOL)showUpdateNotification;

//////////////////////////////////////////////////////////////////////////////////////////
/// Get the icon for this achievement
///
/// @return OFRequestHandle for the server request.  Use this to cancel the request
///
/// @note Invokes	- (void)didGetIcon:(UIImage*)image OFAchievement:(OFAchievement*)achievement; on success and
///					- (void)didFailGetIconOFAchievement:(OFAchievement*)achievement; on failure
//////////////////////////////////////////////////////////////////////////////////////////
- (OFRequestHandle*)getIcon;

//////////////////////////////////////////////////////////////////////////////////////////
/// Achievement title
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly)			NSString*	title;

//////////////////////////////////////////////////////////////////////////////////////////
/// Achievement description
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly)			NSString*	description;

//////////////////////////////////////////////////////////////////////////////////////////
/// Gamerscore value for the achievement
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly)			NSUInteger	gamerscore;

//////////////////////////////////////////////////////////////////////////////////////////
/// If @c YES then this achievement is secret. This means that it's details are hidden 
/// from users who have not yet unlocked it.
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly)			BOOL		isSecret;

//////////////////////////////////////////////////////////////////////////////////////////
/// The date that this achievement was unlocked, if it is unlocked, nil otherwise.
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly)			NSDate*		unlockDate;

//////////////////////////////////////////////////////////////////////////////////////////
/// If @c YES then this achievement completely unlocked, (i.e. percentComplete is 100%)
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly) BOOL isUnlocked;

//////////////////////////////////////////////////////////////////////////////////////////
/// returns the whole percent complete for this achievement. i.e. 60.5 is 60.5%
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly)	double percentComplete;

//////////////////////////////////////////////////////////////////////////////////////////
/// @internal
//////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithLocalSQL:(OFSqlQuery*)queryRow;
+ (NSString*)getResourceName;

@property (nonatomic, readonly) BOOL isUnlockedByComparedToUser;
@property (nonatomic, readonly) NSString* comparedToUserId;
@property (nonatomic, readonly) NSString* endVersion;
@property (nonatomic, readonly) NSString* startVersion;
@property (nonatomic, readonly) NSUInteger position;
@property (nonatomic, readonly)	NSString*	iconUrl;

@end


//////////////////////////////////////////////////////////////////////////////////////////
/// Adopt the OFAchievementDelegate Protocol to receive information regarding 
/// OFAchievements.  You must call OFAchievement's +(void)setDelegate: method to receive
/// information.
//////////////////////////////////////////////////////////////////////////////////////////
@protocol OFAchievementDelegate<NSObject>
@optional
//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked by an OFAchievement class when submitDeferredAchievements successfully 
/// completes.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didSubmitDeferredAchievements;

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked by an OFAchievement class when submitDeferredAchievements fails.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didFailSubmittingDeferredAchievements;

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked by an OFAchievement class when unlock successfully completes
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didUpdateProgressionCompleteOFAchievement:(OFAchievement*)achievement;

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked by an OFAchievement class when unlock fails.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didFailUpdateProgressionCompleteOFAchievement:(OFAchievement*)achievement;

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked when getIcon successfully completes
///
/// @param image		The image requested
/// @param achievement	The achievement this image belongs to.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didGetIcon:(UIImage*)image OFAchievement:(OFAchievement*)achievement;

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked when getIcon fails.
///
/// @param achievement	The OFAchievement for which the image was requested
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didFailGetIconOFAchievement:(OFAchievement*)achievement;

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked when forceSyncGameCenterAchievements succeeds.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didForceSyncGameCenterAchievements;

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked when forceSyncGameCenterAchievements fails.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didFailForceSyncGameCenterAchievements;


@end


@interface OFAchievement (Deprecated)

//////////////////////////////////////////////////////////////////////////////////////////
/// Unlocks an achievement for the local user
///
/// @param achievementId	The unique Achievement id from api.openfeint.com  
///
/// @return OFRequestHandle for the server request.  Use this to cancel the request
//////////////////////////////////////////////////////////////////////////////////////////
- (OFRequestHandle*)unlock;

//////////////////////////////////////////////////////////////////////////////////////////
/// Unlocks an achievement for the current user, but deffers the submition of this information
/// to the server until "submitDeferredAchievements" is called in your app.
///
/// @note	If you defer achievements, the user will still see the achievement unlock
///			immediately and it will be stored locally that it is unlocked.  If the user
///			quits the app before you have a chance to submit the defered achievments,
///			the next time the app is started up online and logged into OpenFeint, we will
///			sync to the server automatically all defered achievements from previous games.
///
//////////////////////////////////////////////////////////////////////////////////////////
- (void)unlockAndDefer;

//////////////////////////////////////////////////////////////////////////////////////////
/// Resend all achievement info to the GameCenter server.
/// This may be used to make sure that GameCenter achievements are properly synchronized
/// with OpenFeint achievements.  The recommended place for this to be called is from the
///		userLoggedInToGameCenter delegate method.
//////////////////////////////////////////////////////////////////////////////////////////
+ (void)forceSyncGameCenterAchievements;

@end
