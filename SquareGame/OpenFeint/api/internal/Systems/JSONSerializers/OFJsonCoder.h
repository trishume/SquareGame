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

#pragma once

#import "OFJsonParser.h"
#import "OFJsonValueTypes.h"
#import "yajl_gen.h"

@class OFJsonCoder;

// All classes which adopt this protocol must also register themselves with 
//
// OFJsonCoder's +(void)registerClass:namedValueMap:
//
// For convenience I have defined a macro: AUTOREGISTER_CLASS_WITH_OFJSONCODER
// which will implement a the +(void)load method to perform registration
// automatically.
@protocol OFJsonCoding
@required
+ (NSString*)classNameForJsonCoding;
+ (void)registerJsonValueTypesForDecoding:(NSMutableDictionary*)valueTypes;
- (void)encodeWithJsonCoder:(OFJsonCoder*)coder;
@end

// Interface for Json encoding/decoding
// Out of the box this class can encode/decode the follow types:
//  * NSDictionary
//  * NSArray
//  * NSString
//  * NSNumber
// in addition any classes which adopt OFJsonCoding and are registered with
// +(void)registerClass:namedValueMap: can also be decoded.
@interface OFJsonCoder : NSObject<OFJsonParserDelegate>
{
	id rootObject;	
	NSMutableArray* objectContextStack;
	OFJsonParser* parser;
	yajl_gen generator;
	NSString* encodedJson;
    NSData* encodedJsonData;
}

// Codable class management
+ (void)registerClass:(Class)klass namedValueMap:(NSMutableDictionary*)namedValueMap;

// Basic serialization entry points
+ (NSString*)encodeObject:(id)object;
+ (NSData*)encodeObjectToData:(id)object;
+ (id)decodeJson:(NSString*)jsonString;
+ (id)decodeJsonFromData:(NSData*)jsonData;

// Methods to use while serializing an OFJsonCoding object
- (void)encodeObject:(id)object withKey:(NSString*)key;
- (void)encodeBool:(BOOL)val withKey:(NSString*)key;
- (void)encodeInteger:(int)val withKey:(NSString*)key;
- (void)encodeInt64:(int64_t)val withKey:(NSString*)key;
- (void)encodeDate:(NSDate*)val withKey:(NSString*)key;
- (void)encodeUrl:(NSURL*)val withKey:(NSString*)key;

@end


#define AUTOREGISTER_CLASS_WITH_OFJSONCODER_BODY											\
	NSAutoreleasePool* _of_autorelease_pool = [[NSAutoreleasePool alloc] init];				\
	NSMutableDictionary* namedValueMap = [NSMutableDictionary dictionaryWithCapacity:8];	\
	[self registerJsonValueTypesForDecoding:namedValueMap];									\
	[OFJsonCoder registerClass:[self class] namedValueMap:namedValueMap];					\
	[_of_autorelease_pool release];

#define AUTOREGISTER_CLASS_WITH_OFJSONCODER													\
+ (void)load																				\
{																							\
	AUTOREGISTER_CLASS_WITH_OFJSONCODER_BODY												\
}
