//  Copyright 2010 Aurora Feint, Inc.
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

#import "OFJsonValueTypes.h"
#import "NSDateFormatter+OpenFeint.h"

#pragma mark JsonValueType Internal Interface

@interface OFJsonValueType ()
- (id)initWithSelector:(SEL)valueSetter;
@end

#pragma mark JsonValueType Implementation

@implementation OFJsonValueType

+ (id)valueWithSelector:(SEL)valueSetter
{
	return [[[OFJsonValueType alloc] initWithSelector:valueSetter] autorelease];
}

- (id)initWithSelector:(SEL)valueSetter
{
	self = [super init];
	if (self != nil)
	{
		selector = valueSetter;
	}
	
	return self;
}

- (void)setValue:(id)value onObject:(id)target
{
	@throw [NSException 
		exceptionWithName:NSGenericException 
		reason:@"Must override setValue:onObject: for derived OFJsonValueType objects"
		userInfo:nil];
}

@end

#pragma mark Json Object Value

@implementation OFJsonObjectValue

@synthesize objectKlass;

+ (id)valueWithKnownClass:(Class)klass selector:(SEL)valueSetter
{
	OFJsonObjectValue* value = [[[OFJsonObjectValue alloc] initWithSelector:valueSetter] autorelease];
	value.objectKlass = klass;
	return value;
}

+ (id)valueWithSelector:(SEL)valueSetter
{
	return [[[OFJsonObjectValue alloc] initWithSelector:valueSetter] autorelease];
}

- (void)setValue:(id)value onObject:(id)target
{
	[target performSelector:selector withObject:value];
}
@end

#pragma mark Json Integer Value

@implementation OFJsonIntegerValue
+ (id)valueWithSelector:(SEL)valueSetter
{
	return [[[OFJsonIntegerValue alloc] initWithSelector:valueSetter] autorelease];
}
- (void)setValue:(id)value onObject:(id)target
{
	int ival = 0;

	if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]])
	{
		ival = [value intValue];
	}
	
	NSInvocation* setter = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[setter setSelector:selector];
	[setter setTarget:target];
	[setter setArgument:&ival atIndex:2];
	[setter invoke];
}
@end

#pragma mark Json Int64 Value

@implementation OFJsonInt64Value
+ (id)valueWithSelector:(SEL)valueSetter
{
	return [[[OFJsonInt64Value alloc] initWithSelector:valueSetter] autorelease];
}
- (void)setValue:(id)value onObject:(id)target
{
	int64_t ival = 0;

	if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]])
	{
		ival = [value longLongValue];
	}

	NSInvocation* setter = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[setter setSelector:selector];
	[setter setTarget:target];
	[setter setArgument:&ival atIndex:2];
	[setter invoke];
}
@end

#pragma mark Json Double Value

@implementation OFJsonDoubleValue
+ (id)valueWithSelector:(SEL)valueSetter
{
	return [[[OFJsonDoubleValue alloc] initWithSelector:valueSetter] autorelease];
}
- (void)setValue:(id)value onObject:(id)target
{
	double dval = 0;

	if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]])
	{
		dval = [value doubleValue];
	}

	NSInvocation* setter = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[setter setSelector:selector];
	[setter setTarget:target];
	[setter setArgument:&dval atIndex:2];
	[setter invoke];
}
@end

#pragma mark Json Bool Value

@implementation OFJsonBoolValue
+ (id)valueWithSelector:(SEL)valueSetter
{
	return [[[OFJsonBoolValue alloc] initWithSelector:valueSetter] autorelease];
}
- (void)setValue:(id)value onObject:(id)target
{
	BOOL bval = NO;

	if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]])
	{
		bval = [value boolValue];
	}
	
	NSInvocation* setter = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
	[setter setSelector:selector];
	[setter setTarget:target];
	[setter setArgument:&bval atIndex:2];
	[setter invoke];
}
@end

#pragma mark Json Date Value

@implementation OFJsonDateValue
+ (id)valueWithSelector:(SEL)valueSetter
{
	return [[[OFJsonDateValue alloc] initWithSelector:valueSetter] autorelease];
}
- (void)setValue:(id)value onObject:(id)target
{
	NSDate* date = nil;

	if ([value isKindOfClass:[NSString class]])
	{
		date = [[[NSDateFormatter railsFormatter] dateFromString:(NSString*)value] retain];
	}
	
	[target performSelector:selector withObject:date];
}
@end

#pragma mark Json Url Value

@implementation OFJsonUrlValue
+ (id)valueWithSelector:(SEL)valueSetter
{
	return [[[OFJsonUrlValue alloc] initWithSelector:valueSetter] autorelease];
}
- (void)setValue:(id)value onObject:(id)target
{
	NSURL* url = nil;

	if ([value isKindOfClass:[NSString class]])
	{
		url = [NSURL URLWithString:(NSString*)value];
	}
	
	[target performSelector:selector withObject:url];
}
@end
