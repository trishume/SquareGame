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

#import "yajl_parse.h"

@class OFJsonParser;

@protocol OFJsonParserDelegate
@required
- (void)jsonParserDidStartObject:(OFJsonParser*)parser;
- (void)jsonParserDidEndObject:(OFJsonParser*)parser;
- (void)jsonParserDidStartArray:(OFJsonParser*)parser;
- (void)jsonParserDidEndArray:(OFJsonParser*)parser;
- (void)jsonParser:(OFJsonParser*)parser didEncounterKey:(id)key;
- (void)jsonParser:(OFJsonParser*)parser didEncounterValue:(id)value;
@end

@interface OFJsonParser : NSObject
{
	yajl_handle handle;
	yajl_callbacks* callbacks;

	id delegate;
}

@property (nonatomic, assign) id delegate;

- (void)parse:(NSString*)jsonChunk;
- (void)parseData:(NSData*)jsonChunk;
- (void)finishParsing;

@end
