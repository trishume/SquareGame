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

#import "OFSession.h"
#import "OFResourceRequest.h"
#import "OFServerException+Session.h"
#import "ASIHTTPRequest.h"

#import "OFPaginatedSeries.h"
#import "OFBootstrap.h"
#import "OFUser.h"
#import "OFSettings.h"
#import "OFBootstrapService.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+NSNotification.h"
#import "NSInvocation+OpenFeint.h"
#import "IPhoneOSIntrospection.h"
#import "OFParentalControls.h"
#import "OFDevice.h"
#import "OpenFeint+Private.h"

@interface OFSession ()
@property (nonatomic, retain, readwrite) NSMutableSet* priorityObservers;
@property (nonatomic, retain, readwrite) NSMutableSet* observers;
@property (nonatomic, retain, readwrite) NSString* key;
@property (nonatomic, retain, readwrite) NSString* secret;
@property (nonatomic, retain, readwrite) NSInvocation* postDeviceInvocation;
@property (nonatomic, retain, readwrite) NSMutableArray* queuedRequests;
@property (nonatomic, retain, readwrite) OFUser* currentUser;
@property (nonatomic, retain, readwrite) OFDevice* currentDevice;
+ (NSString*)protocolVersion;
- (void)establishDeviceSession;
- (void)deviceSessionResponse:(OFResourceRequest*)request;
- (void)establishUserSessionForId:(NSString*)userId password:(NSString*)password;
- (void)failWithException:(OFServerException*)exception;
- (void)processQueuedRequests;
@end

@implementation OFSession

@synthesize priorityObservers;
@synthesize observers;
@synthesize key;
@synthesize secret;
@synthesize postDeviceInvocation;
@synthesize queuedRequests;
@synthesize currentUser;
@synthesize currentDevice;

+ (NSString*)protocolVersion
{
	return @"1.0";
}

#pragma mark -
#pragma mark Life-cycle
#pragma mark -

- (id)initWithProductKey:(NSString*)_key secret:(NSString*)_secret;
{
	self = [super init];
	if (self != nil)
	{
        self.priorityObservers = [NSMutableSet setWithCapacity:2];
        self.observers = [NSMutableSet setWithCapacity:2];

        self.key = _key;
        self.secret = _secret;

		self.queuedRequests = [NSMutableArray arrayWithCapacity:2];
		
		self.currentUser = [OFUser invalidUser];
	}
	
	return self;
}

- (void)dealloc
{
    self.priorityObservers = nil;
    self.observers = nil;
    self.key = nil;
    self.secret = nil;
	self.queuedRequests = nil;
    self.postDeviceInvocation = nil;
	self.currentUser = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Observer Management
#pragma mark -

- (void)addObserver:(id<OFSessionObserver>)observer
{
    [observers addObject:observer];
}

- (void)addPriorityObserver:(id<OFSessionObserver>)observer
{
    [priorityObservers addObject:observer];
}

- (void)removeObserver:(id<OFSessionObserver>)observer
{
    [priorityObservers removeObject:observer];
    [observers removeObject:observer];
}

- (void)failWithException:(OFServerException*)exception
{
    for (id observer in priorityObservers)
    {
        if ([observer respondsToSelector:@selector(session:failureWithException:)])
            [observer session:self failureWithException:exception];
    }
    for (id observer in observers)
    {
        if ([observer respondsToSelector:@selector(session:failureWithException:)])
            [observer session:self failureWithException:exception];
    }
}

#pragma mark -
#pragma mark Request Management
#pragma mark -

- (void)performRequest:(OFXPRequest*)request
{
	// sign it if we need to
	[request signWithKey:key secret:secret];
    
	// establish device session if we need to
	if (request.requiresDeviceSession)
		[self establishDeviceSession];

	// fail if we require a user and don't have one
	if (request.requiresUserSession && !stateFlags.createdUserSession)
	{
		[request forceFailure:0];
		return;
	}

	// queue if we're busy doing something important
	if (stateFlags.sessionChangeInProgress)
	{
		[queuedRequests addObject:request];
	}
	// ... or finally just execute!
	else
	{
		[request.request startAsynchronous];
	}
}

- (void)processQueuedRequests
{
    if (!stateFlags.sessionChangeInProgress)
    {
        for (OFXPRequest* request in queuedRequests)
			[self performRequest:request];
        
        [queuedRequests removeAllObjects];
    }
}

#pragma mark -
#pragma mark Device Session Management
#pragma mark -

- (void)establishDeviceSession
{
    if (stateFlags.sessionChangeInProgress || stateFlags.createdDeviceSession)
        return;

	CGSize s = [[UIScreen mainScreen] bounds].size;
	NSString* screenSize = [NSString stringWithFormat:@"%dx%d", (int)s.width, (int)s.height];

    OFResourceRequest* request = [OFResourceRequest 
        postRequestWithPath:@"/xp/devices" 
        andBody:[NSDictionary dictionaryWithObjectsAndKeys:
            @"iOS", @"platform",
            [NSDictionary dictionaryWithObjectsAndKeys:
                [[UIDevice currentDevice] uniqueIdentifier], @"identifier",
                [[UIDevice currentDevice] name], @"name",
                getHardwareVersion(), @"hardware",
                [[UIDevice currentDevice] systemVersion], @"os",
                screenSize, @"screen_resolution",
                @"dunno", @"processor",
                nil], @"device",
			[OFSession protocolVersion], @"protocol_version",
            nil]];
    request.retryIfNotLoggedIn = NO;
    request.requiresUserSession = NO;
    request.requiresDeviceSession = NO;
    
    [[request onRespondTarget:self selector:@selector(deviceSessionResponse:)] execute];
    stateFlags.sessionChangeInProgress = YES;
}

- (void)deviceSessionResponse:(OFResourceRequest*)request
{
    stateFlags.sessionChangeInProgress = NO;

    if (request.httpResponseCode >= 200 && request.httpResponseCode < 300)
    {
        stateFlags.createdDeviceSession = YES;
        [postDeviceInvocation invoke];
        self.postDeviceInvocation = nil;
		
		if([request.resources isKindOfClass:[OFDevice class]])
		{
			self.currentDevice = request.resources;
		}
    }
    else
    {
		for (unsigned int i = 0; i < [queuedRequests count]; ++i)
		{
			OFXPRequest* request = [queuedRequests objectAtIndex:i];
			if (request.requiresDeviceSession)
			{
				[request forceFailure:0];
				[queuedRequests exchangeObjectAtIndex:i withObjectAtIndex:[queuedRequests count] - 1];
				[queuedRequests removeLastObject];
				i--;
			}
		}

		OFServerException* exception = nil;
		if ([request.resources isKindOfClass:[OFServerException class]])
			exception = request.resources;

        stateFlags.createdDeviceSession = NO;
        [self failWithException:exception];
    }
    
    [self processQueuedRequests];
}

#pragma mark -
#pragma mark Utility Methods
#pragma mark - 

- (BOOL)sessionChangeAllowed
{
	return !stateFlags.sessionChangeInProgress;
}

#pragma mark -
#pragma mark User Session Management
#pragma mark - 

- (void)loginNewUser
{
    if (!stateFlags.createdDeviceSession)
    {
        if (!postDeviceInvocation)
            self.postDeviceInvocation = [NSInvocation invocationWithTarget:self andSelector:_cmd];

        [self establishDeviceSession];
		return;
    }

	if (stateFlags.sessionChangeInProgress)
		return;

	stateFlags.sessionChangeInProgress = YES;
	
	[OFBootstrapService
		doBootstrapWithNewAccount:YES
		userId:nil
		onSucceededLoggingIn:OFDelegate(self, @selector(bootstrapSuccess:)) 
		onFailedLoggingIn:OFDelegate(self, @selector(bootstrapFailure:))];
}

- (void)loginUserId:(NSString*)userId password:(NSString*)password
{
    if (!stateFlags.createdDeviceSession)
    {
        if (!postDeviceInvocation)
        {
            self.postDeviceInvocation = [NSInvocation invocationWithTarget:self andSelector:_cmd andArguments:&userId, &password];
            [postDeviceInvocation retainArguments];
        }

        [self establishDeviceSession];
		return;
    }

	if (stateFlags.sessionChangeInProgress)
		return;

	stateFlags.sessionChangeInProgress = YES;
	
	[OFBootstrapService
		doBootstrapWithNewAccount:NO
		userId:userId
		onSucceededLoggingIn:OFDelegate(self, @selector(bootstrapSuccess:)) 
		onFailedLoggingIn:OFDelegate(self, @selector(bootstrapFailure:))];
}

- (void)establishUserSessionForId:(NSString*)userId password:(NSString*)password
{
	NSMutableDictionary* body = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        @"iOS", @"platform",
        [OpenFeint releaseVersionString], @"of-version",
        OFSettings::Instance()->getClientBundleVersion(), @"app-version",
        nil];

    [body setObject:userId forKey:@"user_id"];
    
    if (password)
        [body setObject:password forKey:@"password"];

    OFResourceRequest* request = [OFResourceRequest postRequestWithPath:@"/xp/sessions" andBody:body];
    request.retryIfNotLoggedIn = NO;
    request.requiresUserSession = NO;
    request.requiresDeviceSession = YES;
    
	stateFlags.sessionChangeInProgress = NO;
    [[request onRespondTarget:self selector:@selector(userSessionResponse:)] execute];
	stateFlags.sessionChangeInProgress = YES;
}

- (void)userSessionResponse:(OFResourceRequest*)request
{
    stateFlags.sessionChangeInProgress = NO;

    if (request.httpResponseCode >= 200 && request.httpResponseCode < 300)
    {
        stateFlags.createdUserSession = YES;

		OFUser* previousUser = [currentUser retain];
		self.currentUser = [OpenFeint localUser];

        for (id observer in priorityObservers)
        {
            if ([observer respondsToSelector:@selector(session:didLoginUser:previousUser:)])
                [observer session:self didLoginUser:currentUser previousUser:previousUser];
        }
        
        for (id observer in observers)
        {
            if ([observer respondsToSelector:@selector(session:didLoginUser:previousUser:)])
                [observer session:self didLoginUser:currentUser previousUser:previousUser];
        }
		
		[previousUser release];
    }
    else
    {
		OFServerException* exception = nil;
		if ([request.resources isKindOfClass:[OFServerException class]])
			exception = request.resources;

        stateFlags.createdUserSession = NO;
        [self failWithException:exception];
    }

    [self processQueuedRequests];
}

- (void)logoutUser
{
	if (stateFlags.sessionChangeInProgress)
		return;
    
    OFResourceRequest* request = [OFResourceRequest deleteRequestWithPath:@"/xp/sessions"];
    request.retryIfNotLoggedIn = NO;
    request.requiresDeviceSession = YES;
    request.requiresUserSession = YES;
    
    [[request onRespondTarget:self selector:@selector(logoutResponse:)] execute];
    stateFlags.sessionChangeInProgress = YES;
}

- (void)logoutResponse:(OFResourceRequest*)request
{
    stateFlags.sessionChangeInProgress = NO;
    stateFlags.createdUserSession = NO;
	
	// if logout fails for any reason
	if (request.httpResponseCode < 200 || request.httpResponseCode >= 300)
	{
		// ... pretend we don't have a device session
		stateFlags.createdDeviceSession = NO;
		
		// ... because we're going to delete the session cookie to "fake" logout
		for (NSHTTPCookie* cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
		{
			if ([cookie.name isEqualToString:@"_of_session"])
			{
				[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
			}
		}
	}

	OFUser* previousUser = [[currentUser retain] autorelease];
	self.currentUser = nil;
	
    for (id observer in priorityObservers)
    {
        if ([observer respondsToSelector:@selector(session:didLogoutUser:)])
            [observer session:self didLogoutUser:previousUser];
    }
    for (id observer in observers)
    {
        if ([observer respondsToSelector:@selector(session:didLogoutUser:)])
            [observer session:self didLogoutUser:previousUser];
    }

    [self processQueuedRequests];
}

#pragma mark -
#pragma mark Legacy Session Management (Bootstrap)
#pragma mark -

- (void)bootstrapSuccess:(OFPaginatedSeries*)responseObjects
{
	OFBootstrap* bootstrapData = nil;
	for (id obj in responseObjects.objects)
	{
		if ([obj isKindOfClass:[OFBootstrap class]])
		{
			bootstrapData = obj;
			break;			
		}
	}

	[self establishUserSessionForId:bootstrapData.user.userId password:nil];
}

- (void)bootstrapFailure:(MPOAuthAPIRequestLoader*)loader
{
	OFServerException* exception = nil;
	
	NSInteger errorCode = [[loader error] code];	
	if (errorCode == NSURLErrorSecureConnectionFailed ||
		errorCode == NSURLErrorServerCertificateHasBadDate ||
		errorCode == NSURLErrorServerCertificateUntrusted)
	{
		exception = [OFServerException sslFailureException];
	}

	stateFlags.sessionChangeInProgress = NO;
	[self failWithException:exception];
}

- (bool)canReceiveCallbacksNow
{
	return true;
}

- (void)setCurrentDevice:(OFDevice*)value
{
	if(currentDevice != value)
	{
		[currentDevice release];
		currentDevice = [value retain];
		//If the paretnal controls change, we will have to reload tabs b/c features may be removed.
		//The roots of each tab section have speical code to reload themselves, but this pops us to the root of each inactive tab.
		[OpenFeint reloadInactiveTabBars];
	}
}

@end
