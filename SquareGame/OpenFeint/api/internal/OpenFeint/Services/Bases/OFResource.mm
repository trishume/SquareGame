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
#import "OFResource+Overridables.h"

@interface OFResource ()
@property (nonatomic, retain) NSString* resourceId;
@end

@implementation OFResource

@synthesize resourceId;

AUTOREGISTER_CLASS_WITH_OFJSONCODER

#pragma mark Life-cycle

- (id)initWithId:(NSString*)_resourceId
{
	self = [super init];
	if (self != nil)
	{
		self.resourceId = _resourceId;
	}
	
	return self;
}

- (void) dealloc
{
	self.resourceId = nil;
	[super dealloc];
}

#pragma mark OFJsonCoding

+ (NSString*)classNameForJsonCoding
{
	return @"resource";
}

+ (void)registerJsonValueTypesForDecoding:(NSMutableDictionary*)valueMap
{
	[valueMap setObject:[OFJsonObjectValue valueWithSelector:@selector(setResourceId:)] forKey:@"id"];
}

- (void)encodeWithJsonCoder:(OFJsonCoder*)coder
{
	[coder encodeObject:self.resourceId withKey:@"id"];
}

@end
