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

#import "OFPresenceService.h"
#import "OFCRVStompClient.h"
#import "OFSettings.h"
#import "OFUser.h"
#import "OpenFeint+NSNotification.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Dashboard.h"
#import "OFPresenceQueue.h"
#import "OFReachability.h"

#import "OFXmlDocument.h"
#import "OFPaginatedSeries.h"
#import "OFNotification.h"
#import "OFInboxController.h"
#import "OFForumPost.h"
#import "OFPoller.h"
#import "OFService+Private.h"

#import "OpenFeint+Private.h"
#import "MPOAuthAPI.h"
#import "NSURL+MPURLParameterAdditions.h"
#import "OFConversationController.h"
#import "MPOAuthConnection.h"

#define OFPresenceLog(message, ...)
//#define OFPresenceLog(message, ...) NSLog(@"OF[Presence]: %@", [NSString stringWithFormat:message, ##__VA_ARGS__])

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFPresenceService)

@interface OFPresenceHTTPResponse : NSHTTPURLResponse
{
	NSInteger secretSauceStatusCode;
}
-(id)initWithSecretSauceStatusCode:(NSInteger)theStatusCode;
@end


@implementation OFPresenceHTTPResponse 
-(id)initWithSecretSauceStatusCode:(NSInteger)theStatusCode {
	self = [super init];
	if (self != nil) {
		secretSauceStatusCode = theStatusCode;
	}
	return self;
}
-(NSInteger)statusCode {
	return secretSauceStatusCode;
}
@end

@interface OFPresenceService ()
@property (retain) NSThread* presenceThread;
@property (nonatomic, retain) NSMutableDictionary* httpRequests;
@property (retain) OFCRVStompClient* stompClient;
- (void)_presenceMain:(id)ignored;
- (void)_requestNewPresenceQueue;
- (void)_onPresenceQueueLoaded:(OFPaginatedSeries *)resources;
- (void)_onFailedToLoadPresenceQueue;
- (void)_reconnect;
@end

@implementation OFPresenceService

@synthesize presenceQueue;
@synthesize pipeHttpOverPresence;
@synthesize httpPipeAvailable;
@synthesize presenceThread;
@synthesize httpRequests;
@synthesize stompClient;

#pragma mark -
#pragma mark OFService Boilerplate
#pragma mark -

+ (OFPresenceService*)sharedInstance
{
	return OFPresenceServiceInstance;
}

+ (void)initializeService
{
	if (OFPresenceServiceInstance == nil)
	{
		OFPresenceServiceInstance = [OFPresenceService new];
	}
}

+ (void)shutdownService
{
	[OFPresenceServiceInstance disconnect];
	[OFPresenceServiceInstance release];
	OFPresenceServiceInstance = nil;
}

- (void)populateKnownResources:(OFResourceNameMap*)namedResources
{
	namedResources->addResource([OFUser getResourceName], [OFUser class]);
	namedResources->addResource([OFForumPost getResourceName], [OFForumPost class]);
	namedResources->addResource([OFPresenceQueue getResourceName], [OFPresenceQueue class]);
}

#pragma mark -
#pragma mark Life-cycle
#pragma mark -

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self.httpRequests = [NSMutableDictionary dictionaryWithCapacity:0];
	}
	
	return self;
}

-(void)dealloc
{
	self.presenceQueue = nil;
	self.presenceThread = nil;

	self.stompClient = nil;
	self.httpRequests = nil;

	OFPresenceLog(@"Service deallocated");
	[super dealloc];
}

-(BOOL)isActive
{
	return isPresenceActive;
}

+ (BOOL)isHttpPipeEnabled
{
	return ([self sharedInstance] != nil) && ([[self sharedInstance] isActive]) && ([[self sharedInstance] pipeHttpOverPresence] && [[self sharedInstance] httpPipeAvailable]);
}

#pragma mark -
#pragma mark Connection
#pragma mark -

- (void)connect
{
	httpPipeAvailable = NO;
	
	if (isPresenceActive)
		return;

	if (![[OpenFeint provider] isAuthenticated])
		return;

	if (retriesAttempted++ >= 32)
	{
		OFPresenceLog(@"Failed connecting too many times, bailing out...");
		return;
	}
	
	OFPresenceLog(@"Connection attempt number %d", retriesAttempted);

	if (!presenceQueue)
	{
		OFPresenceLog(@"Requesting new presence queue");
		[self _requestNewPresenceQueue];
		return;
	}
	
	if (!self.presenceThread)
	{
		OFPresenceLog(@"Spawning presence thread...");
		isPresenceActive = YES;
		[NSThread detachNewThreadSelector:@selector(_presenceMain:) toTarget:self withObject:nil];
	}
	else if ([self.presenceThread isCancelled])
	{
		OFPresenceLog(@"Attempting to connect while disconnecting. Retrying in 5 seconds...");
		[self performSelector:_cmd withObject:nil afterDelay:5.f];
	}
}

- (void)disconnect
{
	if (isPresenceActive)
	{
		OFPresenceLog(@"Disconnecting...");
		isPresenceActive = NO;
		[self.presenceThread cancel];
		[self performSelector:@selector(_pingThread) onThread:self.presenceThread withObject:nil waitUntilDone:NO];
	}
}

- (void)_reconnect
{
	if (isPresenceActive)
	{
		[self disconnect];
		[self performSelector:@selector(connect) withObject:nil afterDelay:15.f];
	}
}

#pragma mark -
#pragma mark Presence Thread Main Loop
#pragma mark -

- (void)_presenceMain:(id)ignored
{
	NSAutoreleasePool* threadPool = [[NSAutoreleasePool alloc] init];
	
	OFPresenceLog(@"Presence thread started");

	self.presenceThread = [NSThread currentThread];
	self.stompClient = [[OFCRVStompClient alloc] 
		initWithHost:OFSettings::Instance()->getPresenceHost() 
		port:61613 
		login:[[OpenFeint localUser] resourceId] 
		passcode:[[OpenFeint provider] getAccessToken] 
		delegate:self 
		autoconnect:YES];

	while (isPresenceActive && ![[NSThread currentThread] isCancelled])
	{
		NSAutoreleasePool* perFramePool = [[NSAutoreleasePool alloc] init];
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		[perFramePool release];
	}
	
	OFPresenceLog(@"Disconnecting stomp client");
	[self.stompClient disconnect];

	self.presenceThread = nil;
	self.stompClient = nil;
	
	OFPresenceLog(@"Presence thread is shutting down");
	[threadPool release];
}

- (void)_pingThread
{
}

#pragma mark -
#pragma mark Queue Management
#pragma mark -

- (void)_requestNewPresenceQueue
{
	OFDelegate success = OFDelegate(self, @selector(_onPresenceQueueLoaded:));
	OFDelegate failure = OFDelegate(self, @selector(_onFailedToLoadPresenceQueue));
	
	[self postAction:@"presence/queue.xml"
	  withParameters:nil
		 withSuccess:success
		 withFailure:failure
	 withRequestType:OFActionRequestSilentIgnoreErrors
		  withNotice:nil];
}

- (void)_onPresenceQueueLoaded:(OFPaginatedSeries *)resources
{
	if ([resources count] == 1) 
	{
		if ([[resources objectAtIndex:0] isKindOfClass:[OFPresenceQueue class]]) 
		{
			self.presenceQueue = [[resources objectAtIndex:0] name];
		}
	}

	OFPresenceLog(@"Received presence queue, retrying connection");
	[self connect];
}

- (void)_onFailedToLoadPresenceQueue
{
	OFPresenceLog(@"Failed to load presence queue, retrying in 15 seconds");
	[self performSelector:@selector(connect) withObject:nil afterDelay:15.0];
}

#pragma mark -
#pragma mark Internal Methods
#pragma mark -

-(void)postInMainThread:(id)resource
{
	NSString *notice;

	[[NSNotificationCenter defaultCenter] postNotificationName:[[resource class] getResourceDiscoveredNotification] object:nil userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:resource] forKey:OFPollerNotificationKeyForResources]];	
	if ([resource isKindOfClass:[OFForumPost class]]) {
		
		id tabBarController = [OpenFeint getActiveNavigationController];
		if (tabBarController) {
			id topViewController = [tabBarController topViewController];
			if ([topViewController isKindOfClass:[OFInboxController class]]) {
				[topViewController reloadDataFromServer];
				return;
			} else if ([topViewController isKindOfClass:[OFConversationController class]]) {
				return;
			} else {
				// @BUG this still needs to be improved
				// at the moment, we do not have a unique count of unread ims / conversation
				// so attempting to increment the unread count past 1 could possibly result
				// in bogus counts (the case of receiving two IMs for the same conversation)
				// the unread count is suppose to display the # of conversations with unread
				// messages, not the total # of unread messages though, it might still make
				// sense to the user, but it is less confusing if the badge represents the number
				// of "new" things 1 level deep, so they see 2, they go into conversations
				// and see 2 conversations (each having a different (possibly greater than 1) unread count
				if ([resource isDiscussionConversation]) {
					NSInteger unreadIMCount = [OpenFeint unreadIMCount];
					if (unreadIMCount == 0) {
						[OpenFeint setUnreadIMCount:1];
					}
				} else {
					NSInteger unreadPostCount = [OpenFeint unreadPostCount];
					if (unreadPostCount == 0) {
						[OpenFeint setUnreadPostCount:1];
					}
				}
				return;
			}
		}
		
		OFInboxController *inboxController = [[OFInboxController alloc] initAndBeginConversationWith:[resource author]];
		
		OFNotificationData *notificationData;
		notice = [NSString stringWithFormat:OFLOCALSTRING(@"New message from %@"), [[resource author] name]];
		notificationData = [OFNotificationData dataWithText:notice andCategory:kNotificationCategoryPresence andType:kNotificationTypeNewMessage];
		[[OFNotification sharedInstance] showBackgroundNotice:notificationData andStatus:OFNotificationStatusSuccess];
		[inboxController release];
	} else if ([resource isKindOfClass:[OFUser class]]) {
		OFNotificationData *notificationData;
		OFNotificationType notificationType;
		if ([resource online]) {
			notice = [NSString stringWithFormat:OFLOCALSTRING(@"%@ is online"), [resource name]];
			notificationType = kNotificationTypeUserPresenceOnline;
			OFInboxController *inboxController = [[OFInboxController alloc] initAndBeginConversationWith:resource];
			notificationData = [OFNotificationData dataWithText:notice andCategory:kNotificationCategoryPresence andType:notificationType];
			[[OFNotification sharedInstance] showBackgroundNotice:notificationData andStatus:OFNotificationStatusSuccess];
			[inboxController release];
		}
	}
}

- (void)stompClient:(OFCRVStompClient *)theStompClient messageReceived:(NSString *)body withHeader:(NSDictionary *)messageHeader
{
    static unichar NUL = 0;
    // this is the only reliable way to prune NUL characters without any compiler warnings (can't put \0 in an NSString literal)
    NSString* stringWithNUL = [[NSString alloc] initWithCharactersNoCopy:&NUL length:1 freeWhenDone:NO];

	if ([messageHeader objectForKey:@"X-HTTP-REQUEST"]) {
		NSString *theRequest = [messageHeader objectForKey:@"X-HTTP-REQUEST"];
		NSArray *httpRequest = [httpRequests objectForKey:theRequest];
		if (httpRequest) {
			OFPresenceHTTPResponse *theResponse = [[OFPresenceHTTPResponse alloc] initWithSecretSauceStatusCode:[[messageHeader objectForKey:@"X-HTTP-STATUS"] intValue]];
			NSData *data = [[body stringByReplacingOccurrencesOfString:stringWithNUL withString:@""] dataUsingEncoding:NSUTF8StringEncoding];
			[[httpRequest objectAtIndex:2] connection:[httpRequest objectAtIndex:0] didReceiveResponse:theResponse];
			[[httpRequest objectAtIndex:2] connection:[httpRequest objectAtIndex:0] didReceiveData:data];
			[[httpRequest objectAtIndex:2] connectionDidFinishLoading:[httpRequest objectAtIndex:0]];
			[theResponse release];
			[httpRequests removeObjectForKey:theRequest];
		}
	} else {
		OFXmlDocument *doc = [OFXmlDocument xmlDocumentWithString:[body stringByReplacingOccurrencesOfString:stringWithNUL withString:@""]];
		OFPaginatedSeries *resources = [OFResource resourcesFromXml:doc withMap:[self getKnownResources]];
		for (id resource in [resources objects]) {
			[self performSelectorOnMainThread:@selector(postInMainThread:) withObject:resource waitUntilDone:NO];
		}

	}

    [stringWithNUL release];
	[theStompClient ack: [messageHeader valueForKey:@"message-id"]];
}

- (void)stompClientDidDisconnect:(OFCRVStompClient *)theStompClient
{
	if (isPresenceActive)
	{
		OFPresenceLog(@"Stomp client disconnected prematurely, reconnecting...");
		[self performSelectorOnMainThread:@selector(_reconnect) withObject:nil waitUntilDone:NO];
	}
}

- (void)stompClientDidConnect:(OFCRVStompClient *)theStompClient
{
	OFPresenceLog(@"Stomp client connected");

	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"true", @"auto-delete",
							 @"true", @"exclusive"
							 , nil];
	[theStompClient subscribeToDestination:self.presenceQueue withHeader:headers];
	
	httpPipeAvailable = YES;
}

- (void)serverDidSendReceipt:(OFCRVStompClient *)theStompClient withReceiptId:(NSString *)receiptId
{
//	OFLog(@"didSendReceipt");
}

- (void)serverDidSendError:(OFCRVStompClient *)theStompClient withErrorMessage:(NSString *)description detailedErrorMessage:(NSString *) theMessage
{
	OFPresenceLog(@"Stomp client errored, disconnecting");
	[self performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:NO];
}

-(void)wrapUrlConnection:(id)theUrlConnection andRequest:(id)theRequest andDelegate:(id)theDelegate
{	
	NSString *generatedNonce = nil;
	CFUUIDRef generatedUUID = CFUUIDCreate(kCFAllocatorDefault);
	generatedNonce = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, generatedUUID);
	CFRelease(generatedUUID);
	NSArray *httpRequest = [NSArray arrayWithObjects:theUrlConnection, theRequest, theDelegate, nil];
	[httpRequests setObject:httpRequest forKey:generatedNonce];
	[self performSelector:@selector(sendHttpRequest:) onThread:self.presenceThread withObject:generatedNonce waitUntilDone:NO];
	CFRelease(generatedNonce);
}

- (NSString *)stringFromStreamData:(NSData *)data
{
	
	if (data == nil) return @"";
	
	// optimistically, see if the whole data block is UTF-8
	NSString *streamDataStr = [[[NSString alloc] initWithData:data
													 encoding:NSUTF8StringEncoding] autorelease];
	if (streamDataStr) return streamDataStr;
	
	// Munge a buffer by replacing non-ASCII bytes with underscores,
	// and turn that munged buffer an NSString.  That gives us a string
	// we can use with NSScanner.
	NSMutableData *mutableData = [NSMutableData dataWithData:data];
	unsigned char *bytes = (unsigned char *)[mutableData mutableBytes];
	
	for (NSUInteger idx = 0; idx < [mutableData length]; idx++) {
		if (bytes[idx] > 0x7F || bytes[idx] == 0) {
			bytes[idx] = '_';
		}
	}
	
	NSString *mungedStr = [[[NSString alloc] initWithData:mutableData
												 encoding:NSUTF8StringEncoding] autorelease];
	if (mungedStr != nil) {
		
		// scan for the boundary string
		NSString *boundary = nil;
		NSScanner *scanner = [NSScanner scannerWithString:mungedStr];
		
		if ([scanner scanUpToString:@"\r\n" intoString:&boundary]
			&& [boundary hasPrefix:@"--"]) {
			
			// we found a boundary string; use it to divide the string into parts
			NSArray *mungedParts = [mungedStr componentsSeparatedByString:boundary];
			
			// look at each of the munged parts in the original string, and try to 
			// convert those into UTF-8
			NSMutableArray *origParts = [NSMutableArray array];
			NSUInteger offset = 0;
			for (NSUInteger partIdx = 0; partIdx < [mungedParts count]; partIdx++) {
				
				NSString *mungedPart = [mungedParts objectAtIndex:partIdx];
				NSUInteger partSize = [mungedPart length];
				
				NSRange range = NSMakeRange(offset, partSize);
				NSData *origPartData = [data subdataWithRange:range];
				
				NSString *origPartStr = [[[NSString alloc] initWithData:origPartData
															   encoding:NSUTF8StringEncoding] autorelease];
				if (origPartStr) {
					// we could make this original part into UTF-8; use the string
					[origParts addObject:origPartStr];
				} else {
					// this part can't be made into UTF-8; scan the header, if we can
					NSString *header = nil;
					NSScanner *headerScanner = [NSScanner scannerWithString:mungedPart];
					if (![headerScanner scanUpToString:@"\r\n\r\n" intoString:&header]) {
						// we couldn't find a header
						header = @"";
					}
					
					// make a part string with the header and <<n bytes>>
					NSString *binStr = [NSString stringWithFormat:@"\r%@\r<<%u bytes>>\r",
										header, partSize - [header length]];
					[origParts addObject:binStr];
				}
				offset += partSize + [boundary length];
			}
			
			// rejoin the original parts
			streamDataStr = [origParts componentsJoinedByString:boundary];
		}
	}  
	
	if (!streamDataStr) {
		// give up; just make a string showing the uploaded bytes
		streamDataStr = [NSString stringWithFormat:@"<<%u bytes>>", [data length]];
	}
	return streamDataStr;
}

-(void)sendHttpRequest:(NSString *)theRequest
{
	NSArray *httpRequest = [httpRequests objectForKey:theRequest];	
	NSString *contentType = [[httpRequest objectAtIndex:1] valueForHTTPHeaderField:@"Content-Type"];
	MPOAuthConnection* hobj = [httpRequest objectAtIndex:0];
	if (contentType == nil) {
		NSString *method = [[httpRequest objectAtIndex:1] HTTPMethod];
		NSString *absolute_url = [[[httpRequest objectAtIndex:1] URL] absoluteNormalizedString];
		NSString *body = [self stringFromStreamData:[[httpRequest objectAtIndex:1] HTTPBody]];
		contentType = @"application/x-www-form-urlencoded";
		[hobj cancel];
		[stompClient pipeHttpRequest:theRequest withMethod:method andContentType:contentType andUrl:absolute_url andBody:body];
	} else {
		[hobj scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[hobj start];
		[httpRequests removeObjectForKey:theRequest];
	}
}

@end
