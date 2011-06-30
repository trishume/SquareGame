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

#import "OFJsonCoder.h"
#import "OFJsonValueTypes.h"
#import "NSDateFormatter+OpenFeint.h"
#import <objc/runtime.h>

#define KEY_FOR_KLASS_OBJECT_IN_MAP @"_KLASS_OBJECT_IN_MAP_"

static NSMutableDictionary* s_classMap = nil;

#pragma mark JSON Object Context

@interface OFJsonObjectContext : NSObject
{
	id object;
	NSString* unresolvedKey;
	NSMutableDictionary* klassInfo;
	BOOL shouldIgnoreNextMapStart;
	BOOL shouldIgnoreNextMapEnd;
}

@property (nonatomic, retain) id object;
@property (nonatomic, retain) NSString* unresolvedKey;
@property (nonatomic, retain) NSMutableDictionary* klassInfo;
@property (nonatomic, assign) BOOL shouldIgnoreNextMapStart;
@property (nonatomic, assign) BOOL shouldIgnoreNextMapEnd;

+ (id)context;

@end

@implementation OFJsonObjectContext

@synthesize object;
@synthesize unresolvedKey;
@synthesize klassInfo;
@synthesize shouldIgnoreNextMapStart;
@synthesize shouldIgnoreNextMapEnd;

+ (id)context
{
	return [[[OFJsonObjectContext alloc] init] autorelease];
}

- (void)dealloc
{
	self.object = nil;
	self.unresolvedKey = nil;
	self.klassInfo = nil;
	[super dealloc];
}

@end

#pragma mark JSON Coder Private Interface

@interface OFJsonCoder ()
@property (nonatomic, retain) id rootObject;
@property (nonatomic, retain) NSMutableArray* objectContextStack;
@property (nonatomic, retain) OFJsonParser* parser;
@property (nonatomic, retain) NSString* encodedJson;
@property (nonatomic, retain) NSData* encodedJsonData;
- (void)beginEncode;
- (void)finishEncode;
- (void)finishEncodeData;
- (void)internalEncodeObject:(id)object;
@end

#pragma mark JSON Coder Implementation

@implementation OFJsonCoder

@synthesize rootObject;
@synthesize objectContextStack;
@synthesize parser;
@synthesize encodedJson;
@synthesize encodedJsonData;

#pragma mark Life-cycle Methods

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self.objectContextStack = [NSMutableArray arrayWithCapacity:8];
		self.parser = [[[OFJsonParser alloc] init] autorelease];
		self.parser.delegate = self;
	}
	
	return self;
}

- (void)dealloc
{
	self.objectContextStack = nil;
	self.rootObject = nil;
	self.parser = nil;
	self.encodedJson = nil;
	[super dealloc];
}

#pragma mark Public Interface

+ (void)registerClass:(Class)klass namedValueMap:(NSMutableDictionary*)namedValueMap
{
	if (!s_classMap)
		s_classMap = [[NSMutableDictionary alloc] initWithCapacity:8];
	
	NSString* className = [klass classNameForJsonCoding];
	[namedValueMap setObject:klass forKey:KEY_FOR_KLASS_OBJECT_IN_MAP];
	
	if (![s_classMap objectForKey:className])
	{
		[s_classMap setObject:namedValueMap forKey:className];
	}
	else
	{
		// Ignore duplicate classes for now
	}

}

+ (NSString*)encodeObject:(id)object
{
	OFJsonCoder* coder = [[[OFJsonCoder alloc] init] autorelease];
	[coder beginEncode];
	[coder internalEncodeObject:object];
	[coder finishEncode];
	
	return coder.encodedJson;
}

+ (NSData*)encodeObjectToData:(id)object
{
	OFJsonCoder* coder = [[[OFJsonCoder alloc] init] autorelease];
	[coder beginEncode];
	[coder internalEncodeObject:object];
	[coder finishEncodeData];
	
	return coder.encodedJsonData;
}

+ (id)decodeJson:(NSString*)jsonString
{
	OFJsonCoder* coder = [[[OFJsonCoder alloc] init] autorelease];
	[coder.parser parse:jsonString];
		
	return coder.rootObject;
}

+ (id)decodeJsonFromData:(NSData*)jsonData
{
	OFJsonCoder* coder = [[[OFJsonCoder alloc] init] autorelease];
	[coder.parser parseData:jsonData];
	
	return coder.rootObject;
}


#pragma mark OFJsonParserDelegate Methods

- (void)jsonParserDidStartObject:(OFJsonParser*)_parser
{
	OFJsonObjectContext* ctx = [objectContextStack lastObject];
	if (ctx.shouldIgnoreNextMapStart)
	{
		ctx.shouldIgnoreNextMapStart = NO;
		return;
	}

	[objectContextStack addObject:[OFJsonObjectContext context]];
}

- (void)jsonParserDidEndObject:(OFJsonParser*)_parser
{
	OFJsonObjectContext* ctx = [objectContextStack lastObject];
	if (ctx.shouldIgnoreNextMapEnd)
	{
		ctx.shouldIgnoreNextMapEnd = NO;
		return;
	}
	
	[ctx retain];
	[objectContextStack removeLastObject];
	
	[self jsonParser:_parser didEncounterValue:ctx.object];

	[ctx release];
}

- (void)jsonParserDidStartArray:(OFJsonParser*)_parser
{
	OFJsonObjectContext* ctx = [OFJsonObjectContext context];
	[objectContextStack addObject:ctx];
	ctx.object = [NSMutableArray arrayWithCapacity:8];
}

- (void)jsonParserDidEndArray:(OFJsonParser*)_parser
{
	OFJsonObjectContext* ctx = [objectContextStack lastObject];
	[ctx retain];
	[objectContextStack removeLastObject];
	
	[self jsonParser:_parser didEncounterValue:ctx.object];

	[ctx release];
}

- (void)jsonParser:(OFJsonParser*)_parser didEncounterKey:(id)key
{
	OFJsonObjectContext* ctx = [objectContextStack lastObject];
	ctx.unresolvedKey = key;

	if (!ctx.object)
	{
		ctx.klassInfo = [s_classMap objectForKey:ctx.unresolvedKey];
		
		if (ctx.klassInfo)
		{
			Class klass = [ctx.klassInfo objectForKey:KEY_FOR_KLASS_OBJECT_IN_MAP];
			ctx.object = [[class_createInstance(klass, 0) init] autorelease];
			ctx.shouldIgnoreNextMapStart = YES;
			ctx.shouldIgnoreNextMapEnd = YES;
			ctx.unresolvedKey = nil;
		}
		else
		{
			ctx.object = [NSMutableDictionary dictionaryWithCapacity:8];
		}
	}

	OFJsonObjectValue* valueType = (OFJsonObjectValue*)[ctx.klassInfo objectForKey:key];
	if ([valueType isKindOfClass:[OFJsonObjectValue class]] && valueType.objectKlass)
	{
		OFJsonObjectContext* newCtx = [OFJsonObjectContext context];
		[objectContextStack addObject:newCtx];
		[self jsonParser:_parser didEncounterKey:[valueType.objectKlass classNameForJsonCoding]];
		newCtx.shouldIgnoreNextMapEnd = NO;
	}
}

- (void)jsonParser:(OFJsonParser*)_parser didEncounterValue:(id)value
{
	OFJsonObjectContext* ctx = [objectContextStack lastObject];

	// ignore NSNull values
	if ([value isKindOfClass:[NSNull class]])
	{
		// if we were expecting an object we're going to skip it
		if (ctx.shouldIgnoreNextMapStart)
		{
			[self jsonParserDidStartObject:_parser];
			[self jsonParserDidEndObject:_parser];
		}
		return;
	}

	if (ctx == nil)
	{
		self.rootObject = value;
	}
	else
	{
		if ([ctx.object isKindOfClass:[NSDictionary class]])
		{
			[ctx.object setValue:value forKey:ctx.unresolvedKey];
		}
		else if ([ctx.object isKindOfClass:[NSArray class]])
		{
			[ctx.object addObject:value];
		}
		else
		{
			OFJsonValueType* valueType = [ctx.klassInfo objectForKey:ctx.unresolvedKey];
			if (valueType != nil)
			{
				[valueType setValue:value onObject:ctx.object];
			}
			else
			{
				// Unrecognized key... just ignore
			}
		}
	}
}

#pragma mark Encoding Methods

- (void)beginEncode
{
	self.encodedJson = @"";

	yajl_gen_config config;
	config.beautify = 0;
	config.indentString = NULL;

	generator = yajl_gen_alloc(&config, NULL);
}
	
- (void)finishEncode
{	
	const unsigned char* buf = NULL;
	unsigned int bufLen = 0;
	yajl_gen_status status = yajl_gen_get_buf(generator, &buf, &bufLen);

	if (status == yajl_gen_generation_complete || status == yajl_gen_status_ok)
	{
		self.encodedJson = [[[NSString alloc] initWithBytes:buf length:bufLen encoding:NSUTF8StringEncoding] autorelease];
	}
	
	yajl_gen_free(generator);
	generator = NULL;
}

- (void)finishEncodeData
{	
	const unsigned char* buf = NULL;
	unsigned int bufLen = 0;
	yajl_gen_status status = yajl_gen_get_buf(generator, &buf, &bufLen);
    
	if (status == yajl_gen_generation_complete || status == yajl_gen_status_ok)
	{
        self.encodedJsonData = [NSData dataWithBytes:buf length:bufLen];
	}
	
	yajl_gen_free(generator);
	generator = NULL;
}


- (void)internalEncodeObject:(id)object
{
	if ([object isKindOfClass:[NSArray class]])
	{
		yajl_gen_array_open(generator);
		
		for (id sub in object)
		{
			[self internalEncodeObject:sub];
		}

		yajl_gen_array_close(generator);
	}
	else if ([object isKindOfClass:[NSDictionary class]])
	{
		yajl_gen_map_open(generator);
		
		for (id key in object)
		{
			[self internalEncodeObject:key];
			[self internalEncodeObject:[object objectForKey:key]];
		}
		
		yajl_gen_map_close(generator);
	}
	else if ([object conformsToProtocol:@protocol(OFJsonCoding)])
	{
		yajl_gen_map_open(generator);

		[self internalEncodeObject:[[object class] classNameForJsonCoding]];
		
		yajl_gen_map_open(generator);

		[object encodeWithJsonCoder:self];

		yajl_gen_map_close(generator);
		yajl_gen_map_close(generator);
	}
	else if ([object isKindOfClass:[NSNumber class]])
	{
		if ((*[object objCType]) == 'c')
		{
			yajl_gen_bool(generator, [object boolValue]);
		}
		else
		{
			char const* utf8 = [[object stringValue] UTF8String];
			yajl_gen_number(generator, utf8, strlen(utf8));
		}
	}
	else if ([object isKindOfClass:[NSString class]])
	{
		char const* utf8 = [object UTF8String];
		yajl_gen_string(generator, (const unsigned char*)utf8, strlen(utf8));
	}
	else if (object == nil || [object isKindOfClass:[NSNull class]])
	{
		yajl_gen_null(generator);
	}
}

- (void)encodeObject:(id)object withKey:(NSString*)key
{
	[self internalEncodeObject:key];
	[self internalEncodeObject:object];
}

- (void)encodeBool:(BOOL)val withKey:(NSString*)key
{
	[self internalEncodeObject:key];
	yajl_gen_bool(generator, val);
}

- (void)encodeInteger:(int)val withKey:(NSString*)key
{
	[self internalEncodeObject:key];
	[self internalEncodeObject:[NSNumber numberWithInt:val]];
}

- (void)encodeInt64:(int64_t)val withKey:(NSString*)key
{
	[self internalEncodeObject:key];
	[self internalEncodeObject:[NSNumber numberWithLongLong:val]];
}

- (void)encodeDate:(NSDate*)val withKey:(NSString*)key
{
	[self internalEncodeObject:key];
	[self internalEncodeObject:[[NSDateFormatter railsFormatter] stringFromDate:val]];
}

- (void)encodeUrl:(NSURL*)val withKey:(NSString*)key
{
	[self internalEncodeObject:key];
	[self internalEncodeObject:[val absoluteString]];
}

@end
