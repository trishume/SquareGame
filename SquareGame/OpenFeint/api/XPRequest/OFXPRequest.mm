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

#import "OFXPRequest.h"
#import "OFSettings.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "MPOAuthSignatureParameter.h" // for hmac
#import "OFJsonCoder.h"
#import "OFSession.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFServerException.h"

#pragma mark Private OFXPRequest methods

@interface OFXPRequest ()
@property (nonatomic, retain) ASIHTTPRequest* request;
@property (nonatomic, retain) id<OFXPResponseText> responseText;
@property (nonatomic, retain) id<OFXPResponseData> responseData;
@property (nonatomic, retain) id<OFXPResponseJSON> responseJSON;
@property (nonatomic, retain) NSString* responseAsString;
@property (nonatomic, retain) NSObject* responseAsJson;
@property (nonatomic, retain) NSData* responseAsData;
@property (nonatomic, retain) NSString* path;
- (void)failWithExceptionClass:(NSString*)className error:(NSString*)errorMessage responseCode:(unsigned int)responseCode;
- (void)requestFinishedOnRequestThread;
@end

#pragma mark ASIHTTPRequest extensions

// In lieu of modules, we are just going to derive from ASIHTTPRequest and ASIFormDataRequest, overriding the
// -requestFinished method.  This allows us to do the parsing functionality off the main thread, before the
// delegates get invoked.  Also, we have a protocol, just so that we can be assured the subclasses we're using
// are compatible with this behavior.

@interface ExtendedGetRequest : ASIHTTPRequest <ExtendedRequest>
{
    OFXPRequest* xpRequest;
}
@end

@implementation ExtendedGetRequest
- (void)setXPRequest:(OFXPRequest*)_request
{
    [xpRequest release];
    xpRequest = [_request retain];
}
- (void)requestFinished
{
    [xpRequest requestFinishedOnRequestThread]; 
    [super requestFinished]; 
}
@end

@interface ExtendedFormRequest : ASIFormDataRequest <ExtendedRequest>
{
    OFXPRequest* xpRequest;
}
@end

@implementation ExtendedFormRequest
- (void)setXPRequest:(OFXPRequest*)_request
{
    [xpRequest release];
    xpRequest = [_request retain];
}
- (void)requestFinished
{
    [xpRequest requestFinishedOnRequestThread]; 
    [super requestFinished]; 
}
@end

#pragma mark Utility functions

static NSString* uriEncode(NSString* str)
{
	return [(NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8) autorelease];
}

@protocol ArgBuilder
- (void)addArgument:(id)arg forKey:(NSString*)key;
@end

static void buildDict(id<ArgBuilder> builder, NSDictionary* body, NSString* prefix);

static void buildArr(id<ArgBuilder> builder, NSArray* arr, NSString* key)
{
	NSString* fullKey = [NSString stringWithFormat:@"%@[]", key];
	for (id o in arr)
	{
		if ([o isKindOfClass:[NSDictionary class]])
		{
			buildDict(builder, (NSDictionary*)o, fullKey);
		} 
		else if ([o isKindOfClass:[NSArray class]])
		{
			buildArr(builder, (NSArray*)o, fullKey);
		}
		else
		{
			[builder addArgument:o forKey:fullKey];
		}
	}
}

static void buildDict(id<ArgBuilder> builder, NSDictionary* body, NSString* prefix)
{
	for (NSString* k in [body allKeys])
	{
		id v = [body objectForKey:k];
		NSString* fullKey = prefix ? [NSString stringWithFormat:@"%@[%@]", prefix, k] : k;
		if ([v isKindOfClass:[NSDictionary class]])
		{
			buildDict(builder, (NSDictionary*)v, fullKey);
		} 
		else if ([v isKindOfClass:[NSArray class]])
		{
			buildArr(builder, (NSArray*)v, fullKey);
		}
		else
		{
			[builder addArgument:v forKey:fullKey];
		}
	}
}

static void buildRoot(id<ArgBuilder> builder, NSDictionary* body) {
	buildDict(builder, body, NULL);
}

@interface FormBuilder : NSObject<ArgBuilder>
{
	ASIFormDataRequest* request;
};
- (void)addArgument:(id)arg forKey:(NSString*)key;
+ (FormBuilder*)builderForRequest:(ASIFormDataRequest*)request;
@property (nonatomic, retain) ASIFormDataRequest* request;
@end
@implementation FormBuilder
@synthesize request;
- (void)addArgument:(id)arg forKey:(NSString*)key {
	[self.request addPostValue:arg forKey:key];
}
+ (FormBuilder*)builderForRequest:(ASIFormDataRequest*)request
{
	FormBuilder* rv = [[self new] autorelease];
	rv.request = request;
	return rv;
}
@end

@interface QueryBuilder : NSObject<ArgBuilder>
{
	NSMutableString* accum;
};
- (void)addArgument:(id)arg forKey:(NSString*)key;
- (NSString*)queryString;
@end
@implementation QueryBuilder
- (void)addArgument:(id)arg forKey:(NSString*)key
{
	if (accum)
	{
		[accum appendFormat:@"&%@=%@", uriEncode(key), uriEncode(arg)];
	}
	else
	{
		accum = [NSMutableString stringWithFormat:@"%@=%@", uriEncode(key), uriEncode(arg)];
	}
}
- (NSString*)queryString
{
	return accum;
}	
@end

@implementation OFXPRequest

#pragma mark OFXPRequest properties

@synthesize requiresSignature;
@synthesize requiresUserSession;
@synthesize requiresDeviceSession;

@synthesize retryIfNotLoggedIn = mRetryIfNotLoggedIn;
@synthesize responseText = mResponseText;
@synthesize responseData = mResponseData;
@synthesize responseJSON = mResponseJSON;

@synthesize responseAsString = mResponseAsString;
@synthesize responseAsJson = mResponseAsJSON;
@synthesize responseAsData = mResponseAsData;

@synthesize path = mPath;

- (void)setRequest:(ASIHTTPRequest*)request
{
	// Cleanup existing
	mRequest.delegate = nil;
    [(ASIHTTPRequest<ExtendedRequest>*)mRequest setXPRequest:nil];
	
	//setup new.
	mRequest = [request retain];
	request.delegate = self;
    [(ASIHTTPRequest<ExtendedRequest>*)mRequest setXPRequest:self];
}

- (ASIHTTPRequest*)request
{
	return mRequest;
}

#pragma mark -
#pragma mark Life-Cycle
#pragma mark -

- (id)init
{
	self = [super init];
    if (self != nil)
    {
        mRetryIfNotLoggedIn = YES;
        requiresSignature = YES;
        requiresUserSession = YES;
        requiresDeviceSession = YES;
    }

	return self;
}

- (void)dealloc
{
    self.responseText = nil;
    self.responseJSON = nil;
    self.responseData = nil;

	self.responseAsString = nil;
	self.responseAsJson = nil;
	self.responseAsData = nil;

    self.path = nil;
	self.request = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Creation Methods
#pragma mark -

- (void)genRequestWithURL:(NSURL*)url andASIClass:(Class)asiHttpRequestSubclass
{
	ASIHTTPRequest* req = [asiHttpRequestSubclass requestWithURL:url];
	OFAssert([req conformsToProtocol:@protocol(ExtendedRequest)], @"%s doesn't conform to the ExtendedRequest protocol", object_getClassName(req));
	
	// setup our config
	req.timeOutSeconds = 20.f;
	req.numberOfTimesToRetryOnTimeout = 2;
	
	self.request = req;
}

- (void)genRequestWithPath:(NSString*)path andASIClass:(Class)asiHttpRequestSubclass
{
	static NSString* sServerURL = [[[[NSURL URLWithString:OFSettings::Instance()->getServerUrl()] standardizedURL] absoluteString] retain];
	
	if ([path hasPrefix:@"/"])
	{
		path = [path substringFromIndex:1];
	}

	[self genRequestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", sServerURL, path]] andASIClass:(Class)asiHttpRequestSubclass];
}

+ (NSString*)embedQueryInPath:(NSString*)path andQuery:(NSDictionary*)query
{
	QueryBuilder* queryBuilder = [QueryBuilder new];
	buildRoot(queryBuilder, query);
	NSString* queryString = [queryBuilder queryString];
	[queryBuilder release];
	if (queryString) 
	{
		path = [NSString stringWithFormat:@"%@?%@", path, queryString];
	}
	return path;
}

+ (id)request
{
	return [[[self alloc] init] autorelease];
}

+ (id)requestWithPath:(NSString*)_path andASIClass:(Class)asiHttpRequestSubclass
{
	OFXPRequest* req = [self request];
    req.path = _path;
    [req genRequestWithPath:_path andASIClass:asiHttpRequestSubclass];
	return req;
}

+ (id)getRequestWithPath:(NSString*)path
{
	return [self requestWithPath:path andASIClass:[ExtendedGetRequest class]];
}

+ (id)getRequestWithPath:(NSString*)path andQuery:(NSDictionary*)query
{
	return [self getRequestWithPath:[self embedQueryInPath:path andQuery:query]];
}

+ (id)getRequestWithPath:(NSString*)path andQueryString:(NSString*)queryString
{
	return [self getRequestWithPath:[NSString stringWithFormat:@"%@?%@", path, queryString]];
}

+ (id)putRequestWithPath:(NSString*)path andBody:(NSDictionary*)body
{
	OFXPRequest* req = [self requestWithPath:path andASIClass:[ExtendedFormRequest class]];
    req.request.requestMethod = @"PUT";
	buildRoot([FormBuilder builderForRequest:(ASIFormDataRequest*)req->mRequest], body);
	return req;
}

+ (id)putRequestWithPath:(NSString*)path andBodyString:(NSString*)bodyString
{
	OFXPRequest* req = [self requestWithPath:path andASIClass:[ExtendedFormRequest class]];
    req.request.requestMethod = @"PUT";
	// quick hack
    [req.request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded; charset=UTF-8"];
    req.request.postBody = [NSMutableData dataWithData:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	return req;
}

+ (id)postRequestWithPath:(NSString*)path andBody:(NSDictionary*)body
{
	OFXPRequest* req = [self requestWithPath:path andASIClass:[ExtendedFormRequest class]];
    req.request.requestMethod = @"POST";
	buildRoot([FormBuilder builderForRequest:(ASIFormDataRequest*)req.request], body);
	return req;
}

+ (id)postRequestWithPath:(NSString*)path andBodyString:(NSString*)bodyString
{
	OFXPRequest* req = [self requestWithPath:path andASIClass:[ExtendedFormRequest class]];
    req.request.requestMethod = @"POST";
	// quick hack
    [req.request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded; charset=UTF-8"];
    req.request.postBody = [NSMutableData dataWithData:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
	return req;
}

+ (id)deleteRequestWithPath:(NSString*)path
{
	OFXPRequest* req = [self requestWithPath:path andASIClass:[ExtendedGetRequest class]];
    req.request.requestMethod = @"DELETE";
	return req;
}

+ (id)deleteRequestWithPath:(NSString*)path andQuery:(NSDictionary*)query
{
	return [self deleteRequestWithPath:[self embedQueryInPath:path andQuery:query]];
	
}

// And here is the super deluxe generic deal.
+ (id)requestWithPath:(NSString *)path andMethod:(NSString*)method andArgs:(NSDictionary*)args
{
	if ([method isEqualToString:@"GET"])
		return [self getRequestWithPath:path andQuery:args];
	
	if ([method isEqualToString:@"POST"])
		return [self postRequestWithPath:path andBody:args];
	
	if ([method isEqualToString:@"PUT"])
		return [self putRequestWithPath:path andBody:args];
	
	if ([method isEqualToString:@"DELETE"])
		return [self deleteRequestWithPath:path];
	
	return nil;
}

+ (id)requestWithPath:(NSString *)path andMethod:(NSString*)method andArgString:(NSString*)args
{
	if ([method isEqualToString:@"GET"])
		return [self getRequestWithPath:path andQueryString:args];
	
	if ([method isEqualToString:@"POST"])
		return [self postRequestWithPath:path andBodyString:args];
	
	if ([method isEqualToString:@"PUT"])
		return [self putRequestWithPath:path andBodyString:args];
	
	if ([method isEqualToString:@"DELETE"])
		return [self deleteRequestWithPath:path];
	
	return nil;
}

#pragma mark -
#pragma mark Response Delegate Methods
#pragma mark -

// If you call this, you'll get notified when the request succeeds or fails,
// with the plain text of the body.  This returns self, so you can chain.
- (id)onRespondText:(id<OFXPResponseText>)responseBlock
{
	self.responseText = responseBlock;
	return self;
}

// If you call this, you'll get notified when the request succeeds or fails,
// with the plain data of the body.  This returns self, so you can chain.
- (id)onRespondData:(id<OFXPResponseData>)responseBlock;
{
	self.responseData = responseBlock;
	return self;
}

// If you call this, you'll get notified when the request succeeds or fails,
// with the body all JSON-parsed just for you.  This returns self, so you can chain.
- (id)onRespondJSON:(id<OFXPResponseJSON>)responseBlock;
{
	self.responseJSON = responseBlock;
	return self;
}

#pragma mark -
#pragma mark Signing
#pragma mark -

- (void)signWithKey:(NSString*)key secret:(NSString*)secret
{
    if (!isSigned && requiresSignature)
    {
        NSString* q = nil;
        
        if ([mRequest.requestMethod isEqualToString:@"GET"] || [mRequest.requestMethod isEqualToString:@"DELETE"])
        {
            q = [mRequest.url query];
        }
        else
        {
            [mRequest buildPostBody];
            NSData* postBody = [mRequest postBody];
            if (postBody)
            {
                q = [[[NSString alloc] initWithData:postBody encoding:NSUTF8StringEncoding] autorelease];
            }
        }

        if (nil == q) q = @"";
        NSString* toSign = [NSString stringWithFormat:@"%@+%@+%@+%@", [mRequest.url path], secret, mRequest.requestMethod, q];
        NSString* signingKey = [NSString stringWithFormat:@"%@&", secret];
        
        // I'm cheating, we can remove this dependency later
        NSString* sig = [MPOAuthSignatureParameter HMAC_SHA1SignatureForText:toSign usingSecret:signingKey];
        
        [mRequest addRequestHeader:@"X-OF-Signature" value:sig];
        [mRequest addRequestHeader:@"X-OF-Key" value:key];
        isSigned = YES;
    }
}

#pragma mark -
#pragma mark Execution
#pragma mark -

// This generates and starts executing the request.  Make sure you set the success/failure blocks before
// calling this.
- (void)execute
{
    [[OpenFeint session] performRequest:self];
}

- (void)retry
{
	self.request = [mRequest copy];
    [self execute];
}

#pragma mark -
#pragma mark Response Methods
#pragma mark -

- (void)failWithExceptionClass:(NSString*)className error:(NSString*)errorMessage responseCode:(unsigned int)responseCode
{
	OFServerException* exc = [OFServerException serverExceptionWithClass:className message:errorMessage];
	NSString* asString = [OFJsonCoder encodeObject:exc];
	
	[mResponseText onResponseText:asString withResponseCode:responseCode];
	[mResponseData onResponseData:[asString dataUsingEncoding:NSUTF8StringEncoding] withResponseCode:responseCode];
	[mResponseJSON onResponseJSON:exc withResponseCode:responseCode];
}

- (void)forceFailure:(unsigned int)responseCode
{
	[self failWithExceptionClass:@"SessionFailure" error:@"Request failed due to device/user session failure." responseCode:responseCode];
}

// This is called on the request thread, before -requestFinished: is called.
- (void)requestFinishedOnRequestThread
{
	// If we have any of these callbacks, we're going to need the data in string format.
	if (mResponseText || mResponseJSON)
	{
		NSStringEncoding encoding = [mRequest responseEncoding];
		if (!encoding) encoding = NSUTF8StringEncoding;
		NSData* d = [mRequest responseData];
		mResponseAsString = [[NSString alloc] initWithBytes:[d bytes] length:[d length] encoding:encoding];
		if (!mResponseAsString)
		{
			// @HACK we are being bitten by the fact that the server doesn't really know what the encoding is.
			// it's probably straight ASCII in the database.  We need to fix this server-side in the long run
			// and make sure the output encoding is correctly translating data coming out of the db.  For now
			// though, we can just use ASCII iff the response encoding fails.
			mResponseAsString = [[NSString alloc] initWithBytes:[d bytes] length:[d length] encoding:NSASCIIStringEncoding];
		}
	}
	
	// same for json...
	if (mResponseJSON)
	{
		self.responseAsJson = [OFJsonCoder decodeJson:mResponseAsString];
	}
	
	// same for data.
	if (mResponseData)
	{
		self.responseAsData = [mRequest responseData];
	}
}

// This relies on -requestFinishedOnRequestThread being called first.
- (void)requestFinished:(ASIHTTPRequest *)request
{
	if (401 == request.responseStatusCode && mRetryIfNotLoggedIn) {
		NSString* uid = [OpenFeint lastLoggedInUserId];
		if (uid && [uid length] > 0 && ![uid isEqualToString:@"0"])
		{
            [[OpenFeint session] loginUserId:uid password:nil];
            [self retry];
			return;
		}
	}

	[mResponseText onResponseText:mResponseAsString withResponseCode:mRequest.responseStatusCode];
	[mResponseData onResponseData:mResponseAsData withResponseCode:mRequest.responseStatusCode];
	[mResponseJSON onResponseJSON:mResponseAsJSON withResponseCode:mRequest.responseStatusCode];
	
	// we're done here
	self.request = nil;
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSString* asString = @"Unknown connection failure";
	if (request.error && request.error.localizedDescription)
	{
		asString = request.error.localizedDescription;
	}

	[self failWithExceptionClass:nil error:[asString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] responseCode:0];
	
	// we're done here
	self.request = nil;
}

@end
