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

#import "OFForumThread.h"

@protocol OFAnnouncementDelegate;
@class OFRequestHandle;

//////////////////////////////////////////////////////////////////////////////////////////
/// Describes a way to sort announcements.
///
/// EAnnouncemenTSortType_CREATION_DATE		Sort by the date the announcement is created
/// EAnnouncementSortType_UPDATE_DATE		Sort by the time the announcement was last posted
///											to (or created if no posts).
//////////////////////////////////////////////////////////////////////////////////////////
enum EAnnouncementSortType
{
	EAnnouncementSortType_CREATION_DATE = 0,
	EAnnouncementSortType_UPDATE_DATE,
	EAnnouncementSortType_COUNT,
};

//////////////////////////////////////////////////////////////////////////////////////////
/// The public interface for OFAnnouncement allows you to get all new announcements and see
/// information about them.
//////////////////////////////////////////////////////////////////////////////////////////
@interface OFAnnouncement : OFForumThread <OFCallbackable>
{
	NSString* body;
	NSDate* originalPostDate;
	BOOL isImportant;
	BOOL isUnread;
	NSString* linkedClientApplicationId;
}

//////////////////////////////////////////////////////////////////////////////////////////
/// Set a delegate for all OFAnnouncement related actions. Must adopt the 
/// OFAnnouncementDelegate protocol.
///
/// @note Defaults to nil. Weak reference
//////////////////////////////////////////////////////////////////////////////////////////
+ (void)setDelegate:(id<OFAnnouncementDelegate>)delegate;

//////////////////////////////////////////////////////////////////////////////////////////
///  Get all announcements
///  
/// @return OFRequestHandle* if a server call must be done.  If the announcements are already cached
///			on the device, this will be null.
///
/// @note Invokes	- (void)didDownloadAnnouncementsAppAnnouncements:(NSArray*)appAnnouncements devAnnouncements:(NSArray*)devAnnouncements; on success and
///					- (void)didFailDownloadAnnouncements; on failure
//////////////////////////////////////////////////////////////////////////////////////////
+ (OFRequestHandle*)downloadAnnouncementsAndSortBy:(EAnnouncementSortType)sortType;

//////////////////////////////////////////////////////////////////////////////////////////
/// Gets Posts for an announcement
///
/// @return OFRequestHandle for the server request.  Use this to cancel the request
///
/// @note Invokes		- (void)didGetPosts:(NSArray*)posts OFAnnouncement:(OFAnnouncement*)announcement; on success and
///						- (void)didFailGetPostsOFAnnouncement:(OFAnnouncement*)announcement; on failure.
//////////////////////////////////////////////////////////////////////////////////////////
- (OFRequestHandle*)getPosts;

//////////////////////////////////////////////////////////////////////////////////////////
/// mark this post as read.
///
/// @note this also affects the latest announcement read date if this announcement was created
/// at a later date than the currently stashed latest announcement read date.  If this is the case,
/// next time announcements are requested, all announcements with a less present updated date will
/// be considered read.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)markAsRead;

//////////////////////////////////////////////////////////////////////////////////////////
/// Body of the announcement as seen on the developer dashboard
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly) NSString* body;

//////////////////////////////////////////////////////////////////////////////////////////
/// The date of the posting of the announcement originally to the OpenFeint dashboard
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly) NSDate* originalPostDate;

//////////////////////////////////////////////////////////////////////////////////////////
/// Whether or not the announcement "has been read".
///
/// @note When downloading announcements we get the latest ceated date of all the announcements read by the current user.
/// All announcements with a creation date before the date are considered read,
/// even if the user has not physically opened them in the OpenFeint Dashboard or if the dev hasn't
/// called markAsRead: on the announcement.
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly) BOOL isUnread;

//////////////////////////////////////////////////////////////////////////////////////////
/// inherited public properties
///
/// The title of the announcment
/// @property NSString* title;
///
/// The date of last update to this announcement (i.e. creation time or post).
/// @property (retain) NSDate* date;
///
//////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////
/// @internal
//////////////////////////////////////////////////////////////////////////////////////////
- (NSComparisonResult)compareByCreationDate:(OFAnnouncement*)announcement;
- (NSComparisonResult)compareByUpdateDate:(OFAnnouncement*)announcement;
@property (nonatomic, readonly) BOOL isImportant;
@property (nonatomic, readonly) NSString* linkedClientApplicationId;

@end


/////////////////////////////////////////////////////////////////////////////////////
/// Adopt the OFAnnouncementDelegate Protocol to receive information regarding OFAnnouncement.
/// You must call OFAnnouncement's +(void)setDelegate: method to receive information.
/////////////////////////////////////////////////////////////////////////////////////
@protocol OFAnnouncementDelegate
@optional

/////////////////////////////////////////////////////////////////////////////////////
/// Invoked when downloadAnnouncements successfully completes.  This is called immediately
/// if we have the announcements already cached.
///
/// @param appAnnouncements		app announcements defined on the dev dashboard
/// @param devAnnouncements		dev announcements defined on the dev dashboard
/////////////////////////////////////////////////////////////////////////////////////
- (void)didDownloadAnnouncementsAppAnnouncements:(NSArray*)appAnnouncements devAnnouncements:(NSArray*)devAnnouncements;

/////////////////////////////////////////////////////////////////////////////////////
/// Invoked when the downloadAnnouncements fails
/////////////////////////////////////////////////////////////////////////////////////
- (void)didFailDownloadAnnouncements;

/////////////////////////////////////////////////////////////////////////////////////
/// Invoked when getPosts successfully completes
///
/// @param posts		An array of the OFForumPosts for a particular announcment.
///						Each element of the array is of type (OFForumPost*).
/// @param announecment	The announcement which the posts are attached to.
/////////////////////////////////////////////////////////////////////////////////////
- (void)didGetPosts:(NSArray*)posts OFAnnouncement:(OFAnnouncement*)announcement;

/////////////////////////////////////////////////////////////////////////////////////
/// Invoked when getPosts fails
///
/// @param announcment	The announcement for which the posts were requested.
/////////////////////////////////////////////////////////////////////////////////////
- (void)didFailGetPostsOFAnnouncement:(OFAnnouncement*)announcement;

@end





