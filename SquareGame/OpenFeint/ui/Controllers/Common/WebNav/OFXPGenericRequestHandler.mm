////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2010 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "OFXPGenericRequestHandler.h"
#import "OFWebUIController.h"

@implementation OFXPGenericRequestHandler

@synthesize webView=mWebView, requestId=mRequestId;

+ (OFXPGenericRequestHandler*)handlerWithWebView:(OFWebUIController*)webView andRequestId:(NSString*)requestId
{
	OFXPGenericRequestHandler* rv = [[[self alloc] init] autorelease];
	rv.webView = webView;
	rv.requestId = requestId;
	return rv;
}

- (void)onResponseText:(NSString*)body withResponseCode:(unsigned int)responseCode
{
	body = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	// Sanity check on reponse to make sure it sort of looks like json.
	if ([body length] == 0 || !([body hasPrefix:@"{"] && [body hasSuffix:@"}"])) {
		body = @"{}";
	}
	
	NSString *js = [NSString stringWithFormat:
					@"OF.api.completeRequest(\"%@\", \"%d\", %@)",
					self.requestId, responseCode, body];
	[self.webView executeJavascript:js];
}

- (void)dealloc
{
	[mWebView release];
	[mRequestId release];
	[super dealloc];
}

@end
