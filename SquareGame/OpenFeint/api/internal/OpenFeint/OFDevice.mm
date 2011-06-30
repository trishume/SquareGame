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

#import "OFDevice.h"
#import "OFParentalControls.h"

@interface OFDevice ()
	@property (nonatomic, retain, readwrite) NSArray* users;
@end

@implementation OFDevice

@synthesize users, parentalControls;

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
	self.parentalControls = nil;
	self.users = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<OFDevice: 0x%x, Users: %@, Parental Controls: %@>", self, users, parentalControls];
}

#pragma mark -
#pragma mark OFJsonCoding
#pragma mark -

AUTOREGISTER_CLASS_WITH_OFJSONCODER

+ (NSString*)classNameForJsonCoding
{
    return @"device";
}

+ (void)registerJsonValueTypesForDecoding:(NSMutableDictionary*)valueMap
{
	[valueMap setObject:[OFJsonObjectValue valueWithKnownClass:[OFParentalControls class] selector:@selector(setParentalControls:)] forKey:@"parental_control"];
	[valueMap setObject:[OFJsonObjectValue valueWithSelector:@selector(setUsers:)] forKey:@"users"];
}

- (void)encodeWithJsonCoder:(OFJsonCoder*)coder
{
	[coder encodeObject:parentalControls withKey:@"parental_control"];
	[coder encodeObject:users withKey:@"users"];
}

@end
