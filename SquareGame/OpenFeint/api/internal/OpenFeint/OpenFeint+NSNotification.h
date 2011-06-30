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

#import "OpenFeint.h"

@class OFUser;

/////////////////////////////////////////////////////
// Online/Offline Notification
//
// This notification is posted when the user goes online
extern NSString * OFNSNotificationUserOnline;
// This notification is posted when the user goes offline
extern NSString * OFNSNotificationUserOffline;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// User Changed Notification
//
// This notification is posted when the user changes
extern NSString * OFNSNotificationUserChanged;
// These are the keys for the userInfo dictionary in the UserChanged notification
extern NSString * OFNSNotificationInfoPreviousUser;
extern NSString * OFNSNotificationInfoCurrentUser;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// Unviewed Challenge Count Notification
//
// This notification is posted when the unviewed challenge count changes
extern NSString * OFNSNotificationUnviewedChallengeCountChanged;
// These are the keys for the userInfo dictionary in the UnviewedChallengeCountChanged notification
extern NSString * OFNSNotificationInfoUnviewedChallengeCount;
/////////////////////////////////////////////////////

//Presence Notifications
extern NSString  *OFNSNotificationFriendPresenceChanged;


/////////////////////////////////////////////////////
// Pending Friend Count Notification
//
// This notification is posted when the pending friend count changes
extern NSString * OFNSNotificationPendingFriendCountChanged;
// These are the keys for the userInfo dictionary in the PendingFriendCountChanged notification
extern NSString * OFNSNotificationInfoPendingFriendCount;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// Add/Remove Friends Notification
extern NSString * OFNSNotificationAddFriend;
extern NSString * OFNSNotificationRemoveFriend;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// Unread Announcement Notification
//
// This notification is posted when the unread announcement count changes
extern NSString * OFNSNotificationUnreadAnnouncementCountChanged;
// These are the keys for the userInfo dictionary in the UnreadAnnouncementCountChanged notification
extern NSString * OFNSNotificationInfoUnreadAnnouncementCount;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// Unread Inbox Notification
//
// This notification is posted when the unread inbox count changes.
// NB: this will be called before the unread IM/Post/Invite notification,
// but one of them will be called as well.
extern NSString * OFNSNotificationUnreadInboxCountChanged;
// These are the keys for the userInfo dictionary in the UnreadInboxCountChanged notification
extern NSString * OFNSNotificationInfoUnreadInboxCount;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// Unread IM Notification
//
// This notification is posted when the unread IM count changes
extern NSString * OFNSNotificationUnreadIMCountChanged;
// These are the keys for the userInfo dictionary in the UnreadIMCountChanged notification
extern NSString * OFNSNotificationInfoUnreadIMCount;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// Unread Post Notification
//
// This notification is posted when the unread post count changes
extern NSString * OFNSNotificationUnreadPostCountChanged;
// These are the keys for the userInfo dictionary in the UnreadPostCountChanged notification
extern NSString * OFNSNotificationInfoUnreadPostCount;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// Unread Invite Notification
//
// This notification is posted when the unread invite count changes
extern NSString* OFNSNotificationUnreadInviteCountChanged;
// These are the keys for the userInfo dictionary in the UnreadInviteCountChanged notification
extern NSString * OFNSNotificationInfoUnreadInviteCount;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// Dashboard Orientation Changed Notification
//
// This notification is posted when the dashboard orientation changes while the dashboard is
// open.
extern NSString * OFNSNotificationDashboardOrientationChanged;
// These are the keys for the userInfo dictionary in the DashboardOrientationChanged notification
extern NSString * OFNSNotificationInfoOldOrientation;
extern NSString * OFNSNotificationInfoNewOrientation;
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
// Bootstrap Notifications
//
// This notification is posted when bootstrap begins.
extern NSString * OFNSNotificationBootstrapBegan;
// These are the keys for the userInfo dictionary in the BootstrapBegan notification
extern NSString * OFNSNotificationBootstrapBeganUserId;
//
// This notification is posted when bootstrap succeeds.
extern NSString * OFNSNotificationBootstrapSucceeded;
// This notification is posted when bootstrap fails.
extern NSString * OFNSNotificationBootstrapFailed;
// This notification is posted when bootstrap completes, in both success and failure cases.
extern NSString * OFNSNotificationBootstrapCompleted;



@interface OpenFeint (NSNotification)

+ (void)postUserChangedNotificationFromUser:(OFUser*)from toUser:(OFUser*)to;
+ (void)postUnviewedChallengeCountChangedTo:(NSUInteger)unviewedChallengeCount;
+ (void)postFriendPresenceChanged:(OFUser *)theUser withPresence:(NSString *)thePresence;
+ (void)postPendingFriendsCountChangedTo:(NSUInteger)pendingFriendCount;
+ (void)postAddFriend:(OFUser*)newFriend;
+ (void)postRemoveFriend:(OFUser*)oldFriend;
+ (void)postUnreadAnnouncementCountChangedTo:(uint)unreadAnnouncementCount;
+ (void)postUnreadInboxCountChangedTo:(NSUInteger)unreadInboxCount;
+ (void)postUnreadIMCountChangedTo:(NSUInteger)unreadIMCount;
+ (void)postUnreadPostCountChangedTo:(NSUInteger)unreadPostCount;
+ (void)postUnreadInviteCountChangedTo:(NSUInteger)unreadInviteCount;
+ (void)postDashboardOrientationChangedTo:(UIInterfaceOrientation)newOrientation from:(UIInterfaceOrientation)oldOrientation;
+ (void)postBootstrapBegan:(NSString*)userId;
+ (void)postBootstrapSucceeded;
+ (void)postBootstrapFailed;

@end
