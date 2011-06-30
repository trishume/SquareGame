// 
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
// 

//#define OF_DEBUG_JSON_RESPONSE

#import "OFResourceRequest.h"

@interface OFResourceRequest ()
@property (nonatomic, retain) id resources;
@property (nonatomic, assign) unsigned int httpResponseCode;
@end

@implementation OFResourceRequest

@synthesize resources;
@synthesize httpResponseCode;

- (void)execute
{
#if defined(OF_DEBUG_JSON_RESPONSE)
    [self onRespondText:self];
#endif
	[self onRespondJSON:self];
	[super execute];
}

- (void)onResponseText:(NSString *)body withResponseCode:(unsigned int)responseCode
{
#if defined(OF_DEBUG_JSON_RESPONSE)
    OFLog(@"OFResourceRequest response (code %d):\n%@", responseCode, body); 
    [self onRespondText:nil];
#endif
}

- (void)onResponseJSON:(id)body withResponseCode:(unsigned int)responseCode
{
	id returnedObject = body;

	if ([body isKindOfClass:[NSDictionary class]] && [body count] == 1)
	{
		returnedObject = [[body objectEnumerator] nextObject];
	}
	
    [self onRespondJSON:nil];
    
	self.resources = returnedObject;
	self.httpResponseCode = responseCode;

	if (target && selector)
	{
		[target performSelector:selector withObject:self];
	}
}

- (id)onRespondTarget:(id)_target selector:(SEL)_selector
{
	target = _target;
	selector = _selector;
	return self;
}

@end
