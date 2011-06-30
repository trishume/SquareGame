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

@class OFRequestHandle;
@protocol OFTimeStampDelegate;

//////////////////////////////////////////////////////////////////////////////////////////
/// @category Public
/// The public interface for OFTimeStamp exposes information about OpenFeint's Time 
//////////////////////////////////////////////////////////////////////////////////////////
@interface OFTimeStamp : OFResource<OFCallbackable>
{
@private
	NSDate* time;
	int secondsSinceEpoch;
}

//////////////////////////////////////////////////////////////////////////////////////////
/// Set a delegate for all OFTimeStamp related actions. Must adopt the 
/// OFTimeStampDelegate protocol.
///
/// @note Defaults to nil. Weak reference
//////////////////////////////////////////////////////////////////////////////////////////
+ (void)setDelegate:(id<OFTimeStampDelegate>)delegate;

//////////////////////////////////////////////////////////////////////////////////////////
/// The blob needs to be explicity downloaded.  After calling this the blob property will
/// be filled out if we have data attached to this high score.
///
/// @return OFRequestHandle for the server request.  Use this to cancel the request
///
/// @note Invokes		- (void)didGetServerTime:(OFTimeStamp*)timeStamp on success and
///						- (void)didFailGetServerTime on failure
//////////////////////////////////////////////////////////////////////////////////////////
+ (OFRequestHandle*)getServerTime;

//////////////////////////////////////////////////////////////////////////////////////////
/// The time associated witht his object
//////////////////////////////////////////////////////////////////////////////////////////
@property (nonatomic, readonly)				NSDate*		time;
@property (nonatomic, readonly)				int			secondsSinceEpoch;

+ (NSString*)getResourceName;

@end

//////////////////////////////////////////////////////////////////////////////////////////
/// Adopt the OFTimeStamp Protocol to receive information regarding 
/// OFTimeStamp.  You must call OFTimeStamp's +(void)setDelegate: method to receive
/// information.
//////////////////////////////////////////////////////////////////////////////////////////
@protocol OFTimeStampDelegate
@optional

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked when getServerTime successfully completes
///
/// @param timeStamp	The current server time stamp
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didGetServerTime:(OFTimeStamp*)timeStamp;

//////////////////////////////////////////////////////////////////////////////////////////
/// Invoked when getServerTime fails.
//////////////////////////////////////////////////////////////////////////////////////////
- (void)didFailGetServerTime;

@end
