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

#import "OFParentalControls.h"

@interface OFParentalControls ()
	@property (nonatomic, assign, readwrite) BOOL enabled;
@end

@implementation OFParentalControls

@synthesize enabled;

#pragma mark -
#pragma mark Life-cycle
#pragma mark -

- (id)init
{
	self = [super init];
	if (self != nil)
	{
	}

	return self;
}

- (void)dealloc
{
	[super dealloc];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<OFParentalControls: 0x%x, enabled: %@>", self, enabled ? @"YES" : @"NO"];
}

#pragma mark -
#pragma mark OFJsonCoding
#pragma mark -

AUTOREGISTER_CLASS_WITH_OFJSONCODER

+ (NSString*)classNameForJsonCoding
{
    return @"parental_control";
}

+ (void)registerJsonValueTypesForDecoding:(NSMutableDictionary*)valueMap
{
	[valueMap setObject:[OFJsonBoolValue valueWithSelector:@selector(setEnabled:)] forKey:@"enabled"];
}

- (void)encodeWithJsonCoder:(OFJsonCoder*)coder
{
	[coder encodeObject:[NSNumber numberWithBool:enabled] withKey:@"enabled"];
}

@end
