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

#import <Foundation/Foundation.h>

@class ASIHTTPRequest, OFXPRequest;

@protocol OFXPResponseText <NSObject>
- (void)onResponseText:(NSString*)body withResponseCode:(unsigned int)responseCode;
@end

@protocol OFXPResponseData <NSObject>
- (void)onResponseData:(NSData*)body withResponseCode:(unsigned int)responseCode;
@end

@protocol OFXPResponseJSON <NSObject>
- (void)onResponseJSON:(id)body withResponseCode:(unsigned int)responseCode;
@end

@protocol ExtendedRequest
- (void)setXPRequest:(OFXPRequest*)_request;
@end

@interface OFXPRequest : NSObject {
	id<OFXPResponseText> mResponseText;
	id<OFXPResponseData> mResponseData;
	id<OFXPResponseJSON> mResponseJSON;
	ASIHTTPRequest* mRequest;
	NSString* mResponseAsString;
	NSObject* mResponseAsJSON;
	NSData* mResponseAsData;

	NSString* mPath;
	
	BOOL mRetryIfNotLoggedIn;

    BOOL isSigned;
    
    BOOL requiresSignature;
    BOOL requiresUserSession;
    BOOL requriesDeviceSession;
}

// Here's the basic deal.
+ (id)requestWithPath:(NSString*)path andASIClass:(Class)asiHttpRequestSubclass;

// Here are specific deals.
+ (id)getRequestWithPath:(NSString*)path;
+ (id)getRequestWithPath:(NSString*)path andQuery:(NSDictionary*)query;
+ (id)getRequestWithPath:(NSString*)path andQueryString:(NSString*)queryString;
+ (id)putRequestWithPath:(NSString*)path andBody:(NSDictionary*)body;
+ (id)putRequestWithPath:(NSString*)path andBodyString:(NSString*)bodyString;
+ (id)postRequestWithPath:(NSString*)path andBody:(NSDictionary*)body;
+ (id)postRequestWithPath:(NSString*)path andBodyString:(NSString*)bodyString;
+ (id)deleteRequestWithPath:(NSString*)path;
+ (id)deleteRequestWithPath:(NSString*)path andQuery:(NSDictionary*)query;


// And here is the super deluxe generic deal.
+ (id)requestWithPath:(NSString *)path andMethod:(NSString*)method andArgs:(NSDictionary*)args;
+ (id)requestWithPath:(NSString *)path andMethod:(NSString*)method andArgString:(NSString*)args;

// If you call this, you'll get notified when the request succeeds or fails,
// with the plain text of the body.  This returns self, so you can chain.
- (id)onRespondText:(id<OFXPResponseText>)responseBlock;

// If you call this, you'll get notified when the request succeeds or fails,
// with the plain data of the body.  This returns self, so you can chain.
- (id)onRespondData:(id<OFXPResponseData>)responseBlock;

// If you call this, you'll get notified when the request succeeds or fails,
// with the body all JSON-parsed just for you.  This returns self, so you can chain.
- (id)onRespondJSON:(id<OFXPResponseJSON>)responseBlock;

// This starts executing the request.  Make sure you set the success/failure blocks before
// calling this.
- (void)execute;

// Signs this request (if desired and not already done) with the given key/secret.
- (void)signWithKey:(NSString*)key secret:(NSString*)secret;

// Used by OFSession to fail a queued request in response to a failed session change operation.
- (void)forceFailure:(unsigned int)responseCode;

@property (nonatomic, assign) BOOL retryIfNotLoggedIn;
@property (nonatomic, assign) BOOL requiresSignature;
@property (nonatomic, assign) BOOL requiresDeviceSession;
@property (nonatomic, assign) BOOL requiresUserSession;

@property (nonatomic, retain, readonly) ASIHTTPRequest* request;

@end
