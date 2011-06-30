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

#import "OFSessionObserver.h"
#import "OFCallbackable.h"

@class OFXPRequest;
@class OFUser;
@class OFDevice;

@interface OFSession : NSObject< OFCallbackable >
{
    NSMutableSet* priorityObservers;
	NSMutableSet* observers;
    NSString* key;
    NSString* secret;
    
    NSInvocation* postDeviceInvocation;
    
    NSMutableArray* queuedRequests;
	
	OFUser* currentUser;
	OFDevice* currentDevice;

    struct {
        BOOL sessionChangeInProgress;
		BOOL createdDeviceSession;
		BOOL createdUserSession;
    } stateFlags;
}

@property (nonatomic, retain, readonly) OFUser* currentUser;
@property (nonatomic, retain, readonly) OFDevice* currentDevice;

// designated initializer
- (id)initWithProductKey:(NSString*)key secret:(NSString*)secret;

// observer management. these objects are notified upon session
// state changes (login, logout, failure, etc.)
- (void)addObserver:(id<OFSessionObserver>)observer;
- (void)addPriorityObserver:(id<OFSessionObserver>)observer;
- (void)removeObserver:(id<OFSessionObserver>)observer;

// @return @c YES if session changes are allowed, @c NO if not
- (BOOL)sessionChangeAllowed;

// methods to change session state
- (void)loginNewUser;
- (void)loginUserId:(NSString*)userId password:(NSString*)password;
- (void)logoutUser;

- (void)performRequest:(OFXPRequest*)request;

@end
