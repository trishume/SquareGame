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

#import "OFServerException.h"

@interface OFServerException ()
@property (nonatomic, retain, readwrite) NSString* className;
@property (nonatomic, retain, readwrite) NSString* message;
@end

@implementation OFServerException

@synthesize className;
@synthesize message;

#pragma mark -
#pragma mark Exception Types
#pragma mark -

- (BOOL)isStaleObjectException
{
	return [className isEqualToString:@"StaleObjectError"];
}

#pragma mark -
#pragma mark Life-cycle
#pragma mark -

+ (id)serverExceptionWithClass:(NSString*)className message:(NSString*)message;
{
	OFServerException* exc = [[[OFServerException alloc] init] autorelease];
	exc.className = [className length] ? className : @"ServerException";
	exc.message = message;
	return exc;
}

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
	self.className = nil;
	self.message = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<OFServerException: 0x%x, class: %@, message: %@>", self, className, message];
}

#pragma mark -
#pragma mark OFJsonCoding
#pragma mark -

AUTOREGISTER_CLASS_WITH_OFJSONCODER

+ (NSString*)classNameForJsonCoding
{
    return @"exception";
}

+ (void)registerJsonValueTypesForDecoding:(NSMutableDictionary*)valueMap
{
	[valueMap setObject:[OFJsonObjectValue valueWithSelector:@selector(setClassName:)] forKey:@"class"];
	[valueMap setObject:[OFJsonObjectValue valueWithSelector:@selector(setMessage:)] forKey:@"message"];
}

- (void)encodeWithJsonCoder:(OFJsonCoder*)coder
{
	[coder encodeObject:className withKey:@"class"];
	[coder encodeObject:message withKey:@"message"];
}

@end
