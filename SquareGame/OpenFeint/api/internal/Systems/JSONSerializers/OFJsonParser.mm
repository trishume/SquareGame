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

#pragma mark YAJL Callbacks

int yajl_null(void * ctx)
{
	OFJsonParser* parser = (OFJsonParser*)ctx;
	[parser.delegate jsonParser:parser didEncounterValue:[NSNull null]];
	return 1;
}

int yajl_boolean(void * ctx, int boolVal)
{
	OFJsonParser* parser = (OFJsonParser*)ctx;
	[parser.delegate jsonParser:parser didEncounterValue:[NSNumber numberWithBool:boolVal]];
	return 1;
}

int yajl_number(void * ctx, const char * numberVal, unsigned int numberLen)
{
	NSString* valueAsNsString = [[[NSString alloc] initWithBytes:numberVal length:numberLen encoding:NSUTF8StringEncoding] autorelease];
	OFJsonParser* parser = (OFJsonParser*)ctx;
	[parser.delegate jsonParser:parser didEncounterValue:valueAsNsString];
	return 1;
}

int yajl_string(void * ctx, const unsigned char * stringVal, unsigned int stringLen)
{
	NSString* valueAsNsString = [[[NSString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding] autorelease];
	OFJsonParser* parser = (OFJsonParser*)ctx;
	[parser.delegate jsonParser:parser didEncounterValue:valueAsNsString];
	return 1;
}

int yajl_start_map(void * ctx)
{
	OFJsonParser* parser = (OFJsonParser*)ctx;
	[parser.delegate jsonParserDidStartObject:parser];
	return 1;
}

int yajl_map_key(void * ctx, const unsigned char * key, unsigned int stringLen)
{
	NSString* keyAsNsString = [[[NSString alloc] initWithBytes:key length:stringLen encoding:NSUTF8StringEncoding] autorelease];
	OFJsonParser* parser = (OFJsonParser*)ctx;
	[parser.delegate jsonParser:parser didEncounterKey:keyAsNsString];
	return 1;
}

int yajl_end_map(void * ctx)
{
	OFJsonParser* parser = (OFJsonParser*)ctx;
	[parser.delegate jsonParserDidEndObject:parser];
	return 1;
}

int yajl_start_array(void * ctx)
{
	OFJsonParser* parser = (OFJsonParser*)ctx;
	[parser.delegate jsonParserDidStartArray:parser];
	return 1;
}

int yajl_end_array(void * ctx)
{
	OFJsonParser* parser = (OFJsonParser*)ctx;
	[parser.delegate jsonParserDidEndArray:parser];
	return 1;
}

#pragma mark Implementation

@implementation OFJsonParser

@synthesize delegate;

#pragma mark Life-cycle

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		yajl_parser_config cfg;
		cfg.allowComments = 1;
		cfg.checkUTF8 = 1;

		callbacks = (yajl_callbacks*)malloc(sizeof(yajl_callbacks));
		callbacks->yajl_null = &yajl_null;
		callbacks->yajl_boolean = &yajl_boolean;
		callbacks->yajl_integer = NULL;
		callbacks->yajl_double = NULL;
		callbacks->yajl_number = &yajl_number;
		callbacks->yajl_string = &yajl_string;
		callbacks->yajl_start_map = &yajl_start_map;
		callbacks->yajl_map_key = &yajl_map_key;
		callbacks->yajl_end_map = &yajl_end_map;
		callbacks->yajl_start_array = &yajl_start_array;
		callbacks->yajl_end_array = &yajl_end_array;
		
		handle = yajl_alloc(callbacks, &cfg, NULL, self);
	}
	
	return self;
}

- (void)dealloc
{
	yajl_free(handle);
	free(callbacks);
	[super dealloc];
}

#pragma mark Public Methods

- (void)parse:(NSString*)jsonChunk
{
	yajl_status st = yajl_parse(handle, (unsigned char const*)[jsonChunk UTF8String], [jsonChunk lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
	if (st == yajl_status_error)
	{
		unsigned char* error = yajl_get_error(handle, 1, (unsigned char const*)[jsonChunk UTF8String], [jsonChunk lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        OFLog(@"Could not parse JSON data: %s", error);
		yajl_free_error(handle, error);
	}
}
- (void)parseData:(NSData*)jsonChunk
{
	yajl_status st = yajl_parse(handle, (unsigned char const*)[jsonChunk bytes], [jsonChunk length]);
	if (st == yajl_status_error)
	{
		unsigned char* error = yajl_get_error(handle, 1, (unsigned char const*)[jsonChunk bytes], [jsonChunk length]);
        OFLog(@"Could not parse JSON data: %s", error);
		yajl_free_error(handle, error);
	}
}


- (void)finishParsing
{
	yajl_status st = yajl_parse_complete(handle);
	if (st == yajl_status_error)
	{
		unsigned char* error = yajl_get_error(handle, 1, NULL, 0);
        OFLog(@"Could not parse JSON data: %s", error);
		yajl_free_error(handle, error);
	}
}

@end
