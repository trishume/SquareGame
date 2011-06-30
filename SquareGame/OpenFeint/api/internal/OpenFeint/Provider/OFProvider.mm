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

#import "OFProvider.h"
#import "MPOAuthAPI.h"
#import "MPURLRequestParameter.h"
#import "OFHttpService.h"
#import "OFActionRequest.h"
#import "OFSettings.h"
#import "OpenFeint+UserOptions.h"
#import "OFDelegateChained.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OpenFeint+Private.h"
#import "OFBootstrapService.h"
#import "FBConnect.h"
#import "OFPresenceService.h"
#import "OpenFeint+AddOns.h"
#import "OFRequestHandle.h"

@implementation OFProvider

@synthesize requestThread = mRequestThread;

- (void)_requestThreadMain
{
	NSAutoreleasePool* threadPool = [[NSAutoreleasePool alloc] init];
    mActiveLoaders = [[NSMutableArray alloc] initWithCapacity:2];
    
	while (![[NSThread currentThread] isCancelled])
	{
		NSAutoreleasePool* perFramePool = [[NSAutoreleasePool alloc] init];
        
        [mRequestThreadLock lockWhenCondition:1];
        OFActionRequest* request = nil;
        if ([mRequestQueue count] > 0)
        {
            request = [[mRequestQueue objectAtIndex:0] retain];
            [mRequestQueue removeObjectAtIndex:0];
            [mActiveLoaders addObject:request.loader];
        }
        [mRequestThreadLock unlockWithCondition:([mRequestQueue count] || [mActiveLoaders count]) ? 1 : 0];
        
        if (request != nil)
        {
            [request dispatch];
            [request release];
        }
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.f]];
        
		[perFramePool release];
	}
    
    OFSafeRelease(mActiveLoaders);
	[threadPool release];
}

- (void)startupRequestThread
{
    mRequestQueue = [[NSMutableArray alloc] initWithCapacity:4];
    mRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(_requestThreadMain) object:nil];
    mRequestThreadLock = [[NSConditionLock alloc] initWithCondition:0];
    [mRequestThread start];
}

- (void)cleanupRequestThread
{
    [mRequestThread cancel];
    [mRequestThreadLock lock];
    [mRequestThreadLock unlockWithCondition:1];
    while (mRequestThread && ![mRequestThread isFinished]) {}
    OFSafeRelease(mRequestThread);
    OFSafeRelease(mRequestThreadLock);
    OFSafeRelease(mRequestQueue);
}

- (id) initWithProductKey:(NSString*)productKey andSecret:(NSString*)productSecret
{
	self = [super init];
	if (self != nil)
	{
		NSDictionary* credentials = [NSDictionary dictionaryWithObjectsAndKeys:
			productKey,		kMPOAuthCredentialConsumerKey,
			productSecret,	kMPOAuthCredentialConsumerSecret,
			nil
		];
		
		NSString* apiUrlString = OFSettings::Instance()->getServerUrl();
		NSURL* apiUrl = [NSURL URLWithString:apiUrlString];

		mOAuthApi = [[MPOAuthAPI alloc] initWithCredentials:credentials	andBaseURL:apiUrl];
		
		mOAuthApi.oauthRequestTokenURL		= [NSURL URLWithString:[NSString stringWithFormat:@"%@oauth/request_token", apiUrlString]];
		mOAuthApi.oauthAuthorizeTokenURL	= [NSURL URLWithString:[NSString stringWithFormat:@"%@oauth/authorize", apiUrlString]];
		mOAuthApi.oauthGetAccessTokenURL	= [NSURL URLWithString:[NSString stringWithFormat:@"%@oauth/access_token", apiUrlString]];

        [self startupRequestThread];
	}
	
	return self;
}

- (void) dealloc
{
	[self destroyAllPendingRequests];
    [self cleanupRequestThread];
	[mOAuthApi release];
	[super dealloc];
}

+ (id) providerWithProductKey:(NSString*)productKey andSecret:(NSString*)productSecret
{
	return [[[OFProvider alloc] initWithProductKey:productKey andSecret:productSecret] autorelease];
}

- (void) destroyAllPendingRequests
{
    [mRequestThreadLock lock];

	for (MPOAuthAPIRequestLoader* loader in mActiveLoaders)
    {
		[loader cancel];
    }

    [mActiveLoaders removeAllObjects];
    [mRequestQueue removeAllObjects];

    [mRequestThreadLock unlockWithCondition:0];
}

- (void) cancelRequest:(id)request
{
    [mRequestThreadLock lock];

	NSUInteger requestIndex = [mActiveLoaders indexOfObjectIdenticalTo:request];
	if (requestIndex != NSNotFound)
	{
		[request cancel];	
		[mActiveLoaders removeObjectAtIndex:requestIndex];
	}
    else
    {
        for (NSUInteger i = 0; i < [mRequestQueue count]; ++i)
        {
            OFActionRequest* req = [mRequestQueue objectAtIndex:i];
            if (req.loader == request)
            {
                [mRequestQueue replaceObjectAtIndex:i withObject:[mRequestQueue lastObject]];
                [mRequestQueue removeLastObject];
                break;
            }
        }
    }

    [mRequestThreadLock unlockWithCondition:([mRequestQueue count] || [mActiveLoaders count]) ? 1 : 0];
}

- (void) destroyLocalCredentials
{
	OFLog(@"destroy local credentials");
	[mOAuthApi removeAllCredentials];
	[[FBSession session] logout];
	[[OFPresenceService sharedInstance] disconnect];
	[OpenFeint notifyAddOnsUserLoggedOut];
}

+ (OFPointer<OFHttpService>)createHttpService
{
	return new OFHttpService(OFSettings::Instance()->getServerUrl());
}

- (bool) isAuthenticated
{
	return [mOAuthApi isAuthenticated];
}

- (void)actionRequestWithLoader:(MPOAuthAPIRequestLoader*)loader withRequestType:(OFActionRequestType)requestType withNotice:(OFNotificationData*)noticeData requiringAuthentication:(bool)requiringAuthentication
{
	OFActionRequest* ofAction = [OFActionRequest actionRequestWithLoader:loader withRequestType:requestType withNotice:noticeData requiringAuthentication:requiringAuthentication];
    [mRequestThreadLock lock];
    [mRequestQueue addObject:ofAction];
    [mRequestThreadLock unlockWithCondition:([mRequestQueue count] || [mActiveLoaders count]) ? 1 : 0];
}

- (void)_loaderFinished:(MPOAuthAPIRequestLoader*)loader nextCall:(OFDelegateChained*)nextCall
{
    loader = [loader retain];

    [mRequestThreadLock lock];
    [mActiveLoaders removeObjectIdenticalTo:loader];
	[OFRequestHandlesForModule completeRequest:loader];
    [mRequestThreadLock unlockWithCondition:([mRequestQueue count] || [mActiveLoaders count]) ? 1 : 0];

	[nextCall invokeWith:loader];

    [loader release];
}

- (void) retrieveAccessToken
{
	MPOAuthAPIRequestLoader* loader = [mOAuthApi createLoaderForAccessToken];	
	[self actionRequestWithLoader:loader withRequestType:OFActionRequestForeground withNotice:[OFNotificationData dataWithText:OFLOCALSTRING(@"Finalizing Authentication") andCategory:kNotificationCategoryLogin] requiringAuthentication:false];
}

- (void) retrieveRequestToken
{
	MPOAuthAPIRequestLoader* loader = [mOAuthApi createLoaderForRequestToken];	
	[self actionRequestWithLoader:loader withRequestType:OFActionRequestForeground withNotice:[OFNotificationData dataWithText:OFLOCALSTRING(@"Starting Authentication") andCategory:kNotificationCategoryLogin] requiringAuthentication:false];
}

- (NSString*) getRequestToken
{
	return [mOAuthApi getRequestToken];
}

- (NSString*) getAccessToken
{
	return [mOAuthApi getAccessToken];
}

- (MPOAuthAPIRequestLoader*)getRequestForAction:(NSString*)action 
		withParameters:(NSArray*)parameters 
		withHttpMethod:(NSString*)method 
		withSuccess:(const OFDelegate&)success 
		withFailure:(const OFDelegate&)failure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)noticeData
		requiringAuthentication:(bool)requiringAuthentication
{
	OFDelegate chainedSuccess(self, @selector(_loaderFinished:nextCall:), success, mRequestThread);
	OFDelegate chainedFailure(self, @selector(_loaderFinished:nextCall:), failure, mRequestThread);

	MPOAuthAPIRequestLoader* loader = 
		[mOAuthApi createLoaderForMethod:action 
									atURL:[NSURL URLWithString:OFSettings::Instance()->getServerUrl()]
						   withParameters:parameters
						   withHttpMethod:method					   
							  withSuccess:chainedSuccess
							  withFailure:chainedFailure];
							  
	return loader;
}

+ (BOOL)willSilentlyDiscardAction
{
	return (![OpenFeint hasUserApprovedFeint] || [OpenFeint isDisabled]);
}

- (OFRequestHandle*)performAction:(NSString*)action 
		withParameters:(NSArray*)parameters 
		withHttpMethod:(NSString*)method 
		withSuccess:(const OFDelegate&)success 
		withFailure:(const OFDelegate&)failure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)noticeData
		requiringAuthentication:(bool)requiringAuthentication
{
	if (requiringAuthentication && [OFProvider willSilentlyDiscardAction])
	{
		return nil;
	}
	MPOAuthAPIRequestLoader* loader = [self 
		getRequestForAction:action
		withParameters:parameters
		withHttpMethod:method
		withSuccess:success
		withFailure:failure
		withRequestType:requestType
		withNotice:noticeData
		requiringAuthentication:requiringAuthentication];
	
	OFRequestHandle* rh = [OFRequestHandle requestHandle:loader];
	[self actionRequestWithLoader:loader withRequestType:requestType withNotice:noticeData requiringAuthentication:requiringAuthentication];
	
	return rh;
}

- (OFRequestHandle*)performAction:(NSString*)action 
		withParameters:(NSArray*)parameters 
		withHttpMethod:(NSString*)method 
		withSuccess:(const OFDelegate&)success 
		withFailure:(const OFDelegate&)failure
		withRequestType:(OFActionRequestType)requestType
		withNotice:(OFNotificationData*)noticeData
{
	return [self performAction:action
			withParameters:parameters
			withHttpMethod:method
			withSuccess:success
			withFailure:failure
			withRequestType:requestType
			withNotice:noticeData
			requiringAuthentication:true];
}

- (void)setAccessToken:(NSString*)token andSecret:(NSString*)secret
{
	[mOAuthApi setAccessToken:token andSecret:secret];
}

- (bool)canReceiveCallbacksNow
{
	return true;
}

@end
