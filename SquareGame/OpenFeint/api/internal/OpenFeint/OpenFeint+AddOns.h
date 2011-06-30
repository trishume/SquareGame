////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009-2010 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma once

#import "OpenFeint.h"
#import "OpenFeintAddOn.h"

@interface OpenFeint (AddOns)
+ (void)registerAddOn:(Class<OpenFeintAddOn>)klass;
+ (void)preInitializeAddOns:(NSDictionary*)settings;
+ (void)initializeAddOns:(NSDictionary*)settings;
+ (void)shutdownAddOns;
+ (BOOL)allowAddOnsToRespondToPushNotification:(NSDictionary*)notificationInfo duringApplicationLaunch:(BOOL)duringApplicationLaunch;
///This should be considered deprecated.  The reason it is left here is to not risk breaking existing addons
+ (void)notifyAddOnsUserLoggedIn;
///This notification happens after the user has finished the introflow, which eliminates accidentally logging into the temporary user
+ (void)notifyAddOnsUserLoggedInPostIntro;
+ (void)notifyAddOnsOfflineUserLoggedInPostIntro;
+ (void)notifyAddOnsUserLoggedOut;
+ (void)setDefaultAddOnSettings:(OFSettings*) settings;
+ (void)loadAddOnSettings:(OFSettings*) settings fromReader:(OFXmlReader&) reader;
@end

#define OPENFEINT_AUTOREGISTER_ADDON \
	+ (void)load \
	{ \
		[OpenFeint registerAddOn:self]; \
	}
