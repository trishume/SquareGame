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

#import "OFResource.h"

@class OFService;
@class OFAchievement;

@interface OFUnlockedAchievement : OFResource
{
@package
	OFAchievement* achievement;
	bool isInvalidResult;
	double percentComplete; // Yeah, this is duplicate data.  Since we can't rely on the xml parsing to happen in any particular order, I don't have a chance to put this on the achievement just through its set method.
}

+ (OFResourceDataMap*)getDataMap;
+ (OFService*)getService;
+ (NSString*)getResourceName;
+ (NSString*)getResourceDiscoveredNotification;

@property (nonatomic, readonly) OFAchievement* achievement;
@property (nonatomic, readonly) bool isInvalidResult;
@property (nonatomic, readonly) double percentComplete;

@end
