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

#import "OFWebViewCacheLoader.h"
#import "OFWebViewManifestData.h"
#import "OFSettings.h"
#import "OpenFeint+Private.h"
#import "OFWebUIController.h"
#import "OFWebViewManifestService.h"
#import "OFRunLoopThread.h"
#import "IPhoneOSIntrospection.h"

@interface OFWebViewLoaderHelper : NSObject {
@private
    OFWebViewCacheLoader *loader;    
    NSUInteger httpStatus;
    NSMutableData* httpData;
    NSString* path;
}

-(id)initWithPath:(NSString*) url loader:(OFWebViewCacheLoader*) loader;
@property (nonatomic, retain) OFWebViewCacheLoader *loader;
@property (nonatomic) NSUInteger httpStatus;
@property (nonatomic, retain) NSMutableData* httpData;
@property (nonatomic, retain) NSString* path;
@end

@interface OFWebViewCacheLoader ()
-(NSString*)documentsPath;
-(void)copyDefaultManifest;
-(void)didSucceedDataForHelper:(OFWebViewLoaderHelper*)helper;
-(void)didFailDataForHelper:(OFWebViewLoaderHelper*)helper;
-(void)loadNextItem;
-(void)_getServerManifest;
-(void)loaderIsFinished;

@property (nonatomic, retain, readwrite) NSString* rootPath;   
@property (nonatomic, retain) OFWebViewManifestData* serverManifest;
@property (nonatomic, retain) NSMutableDictionary* localManifest;
@property (nonatomic, retain) NSString* manifestApplication;

@property (nonatomic, retain) NSMutableSet* pathsToLoad;
@property (nonatomic, retain) NSMutableDictionary* tracked;
@property (nonatomic, retain) NSMutableSet* globals;
@property (nonatomic, retain) NSMutableSet* priority;

@property (nonatomic) BOOL abortedByReset;
@property (nonatomic, retain) NSMutableDictionary* observers;
@property (nonatomic) BOOL defaultCopied;
@property (nonatomic, retain) NSLock *trackingLock;
@property (nonatomic, retain) OFRunLoopThread* thread;
@end


@implementation OFWebViewLoaderHelper 
@synthesize loader, httpStatus, httpData, path;
-(id)initWithPath:(NSString*) _path loader:(OFWebViewCacheLoader*) _loader{
    if((self = [super init])) {
        self.path = _path;
        self.loader = _loader;
        NSString* url = [NSString stringWithFormat:@"%@webui/%@", OFSettings::Instance()->getServerUrl(), _path];
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:5.0];
        NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
        if(connection) {
            self.httpData = [NSMutableData data];
            self.httpStatus = 0;
            //            OFLog(@"WebView Cache loading %@", _path);
        }
        else {
            OFLog(@"WebView Cache: Failed to create connection for %@", path);
            [self.loader didFailDataForHelper:self];
        }
    }
    return self;
}

-(void) dealloc {
    self.loader = nil;
    self.httpData = nil;
    [super dealloc];
}
#pragma mark NSUrlConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
    
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    
    // receivedData is an instance variable declared elsewhere.
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    self.httpStatus = httpResponse.statusCode;
    [self.httpData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)_data
{
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [self.httpData appendData:_data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{    
    // inform the user
	NSString* failingURL = @"(unknown URL)";
	if (is4PointOhSystemVersion())
	{
		failingURL = [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey];
	}
    NSLog(@"WebView Cache Load Connection failed! Error - %@ %@",
          [error localizedDescription], failingURL);
    [self.loader didFailDataForHelper:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //    NSLog(@"WebView Cache Load Succeeded! Status %d Received %d bytes of data", self.httpStatus, [self.httpData length]);    
    //any kind of response is considered success for this purpose
    [self.loader didSucceedDataForHelper:self];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

@end



@implementation OFWebViewCacheLoader
@synthesize delegate, rootPath;
@synthesize pathsToLoad, tracked, globals, priority;
@synthesize serverManifest, localManifest, manifestApplication;
@synthesize abortedByReset, observers, defaultCopied, trackingLock, thread;

#pragma mark Public interface
-(id)initForApplication:(NSString*) _manifestApplication {
    if((self = [super init])) {
        self.thread = [OFRunLoopThread runLoop];
        self.manifestApplication = _manifestApplication;
        self.observers = [NSMutableDictionary dictionaryWithCapacity:5];
        self.trackingLock = [[NSLock new] autorelease];
        self.tracked = [NSMutableDictionary dictionaryWithCapacity:5];
        self.priority = [NSMutableSet setWithCapacity:10];
        self.rootPath = [[self documentsPath] stringByAppendingPathComponent:@"webui"];
        [self performSelector:@selector(copyDefaultManifest) onThread:self.thread withObject:nil waitUntilDone:NO];
    }
    return self;
}


-(void) dealloc {
    self.manifestApplication = nil;
    self.observers = nil;
    self.trackingLock = nil;
    self.rootPath = nil;
    self.localManifest = nil;
    self.serverManifest = nil;
    self.pathsToLoad = nil;
    self.tracked = nil;
    self.priority = nil;
    self.globals = nil;
    self.thread = nil;
    [super dealloc];
}

-(BOOL)trackPath:(NSString*)path forMe:(id<OFWebViewManifestDelegate>)caller {
    [self.trackingLock lock];
    BOOL needsTracking = ![self isPathLoaded:path];
    
    if(needsTracking) {
		NSMutableSet* existingCallers = (NSMutableSet*)[self.tracked objectForKey:path];
		if (existingCallers)
		{
			[existingCallers addObject:caller];
		}
		else
		{
			[self.tracked setObject:[NSMutableSet setWithObject:caller] forKey:path];
		}

        [self prioritizePath:path];
    }
    else {
        [(NSObject*)caller performSelectorOnMainThread:@selector(webViewCacheItemReady:) withObject:path waitUntilDone:NO];            
    }
    [self.trackingLock unlock];
    return needsTracking;
}
-(void)prioritizePath:(NSString*)path {
    NSMutableSet *priorityAdds = [[NSMutableSet alloc] initWithObjects:path, nil];
    if(self.pathsToLoad) {
        OFWebViewManifestItem*item = [self.serverManifest.objects objectForKey:path];
        [priorityAdds unionSet:item.dependentObjects];
        [priorityAdds intersectSet:self.pathsToLoad];
    }
    [self.priority unionSet:priorityAdds];
    [priorityAdds release];
}

-(BOOL)isPathLoaded:(NSString*)path {
    if(self.pathsToLoad) {
        if(self.globals.count) return NO;
        if([self.pathsToLoad containsObject:path]) return NO;
        OFWebViewManifestItem*item = [self.serverManifest.objects objectForKey:path];

        [item.dependentObjects intersectSet:self.pathsToLoad];
        return item.dependentObjects.count == 0;
        
    }
    else {
        return NO;
    }
}

-(BOOL)isPathValid:(NSString*)path {
    if(self.pathsToLoad) {
        return [self isPathLoaded:path];
    }
    else {        
        return YES;  //the cache isn't yet ready, this is potentially a race condition, but it shouldn't cause issues
    }
}

-(void)enable {
}
-(void)disable {
}
-(void)resetToSeed {
    self.abortedByReset = YES;
    self.pathsToLoad = [NSMutableSet set];
    NSString* userDocumentsPath = [self documentsPath];
    NSString* manifestPath = [userDocumentsPath stringByAppendingPathComponent:@"webui/manifest.plist"];
    [[NSFileManager defaultManager] removeItemAtPath:manifestPath error:nil];
    [self copyDefaultManifest];
    
    //can't call loaderIsFinished if there's still stuff waiting on that thread
    if([self.observers count] == 0) {
        [self loaderIsFinished];
    }
    //else the observer callback will take care of calling the finish
}

#pragma mark Private Methods (background thread)
-(NSString*)documentsPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}
-(void)copyDefaultManifest {
    NSString* userDocumentsPath = [self documentsPath];
    NSString* manifestPath = [userDocumentsPath stringByAppendingPathComponent:@"webui/manifest.plist"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:manifestPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.rootPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        // Look in the main bundle first, then fall back to the SDK bundle
        NSString* openFeintResourceBundleLocation = [[NSBundle mainBundle] bundlePath];
        NSString* bundlePath = [openFeintResourceBundleLocation stringByAppendingPathComponent:@"webui.bundle"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
            openFeintResourceBundleLocation = [[OpenFeint getResourceBundle] bundlePath];
            bundlePath = [openFeintResourceBundleLocation stringByAppendingPathComponent:@"webui.bundle"];
        }
        
        //copy everything from the bundle, which will include the starting manifest
        
        NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:bundlePath];
        NSString* file;
        while((file = [dirEnum nextObject])) {
            if([[dirEnum fileAttributes] fileType] == NSFileTypeDirectory) {
                [[NSFileManager defaultManager] createDirectoryAtPath:[rootPath stringByAppendingPathComponent:file] withIntermediateDirectories:YES attributes:nil error:nil];                
            }
            else if([[dirEnum fileAttributes] fileType] == NSFileTypeRegular) {
                NSString* source = [bundlePath stringByAppendingPathComponent:file];
                NSString* destination = [rootPath stringByAppendingPathComponent:file];
                
                NSData* fileData = [NSData dataWithContentsOfFile:source];
                [fileData writeToFile:destination atomically:YES];
            }
        }
        OFLog(@"WebView Cache loaded default bundle");    
    }
    self.defaultCopied = YES;
}

-(void) getServerManifest {
    [self performSelector:@selector(_getServerManifest) onThread:self.thread withObject:nil waitUntilDone:NO];
}

-(void)_notifyItemReady:(NSString*)trackedPath
{
	NSMutableSet* callers = (NSMutableSet*)[self.tracked objectForKey:trackedPath];
	for (id caller in callers)
	{
		[caller performSelectorOnMainThread:@selector(webViewCacheItemReady:) withObject:trackedPath waitUntilDone:NO];
	}
}							 

-(void)_getServerManifest {
	
	//do nothing for now, we don't need a manifest for the base sdk
	if(!(self.manifestApplication))
	{
		return;
	}
	NSString* applicationName = self.manifestApplication;
	
	//Use this later when the base SDK needs a manifest
    /*NSString* applicationName = @"embed";
    if(self.manifestApplication) {
        applicationName = self.manifestApplication;
    }*/
	
    
    NSString *url = [NSString stringWithFormat:@"%@webui/manifest/ios.%@.%@", OFSettings::Instance()->getServerUrl(), applicationName, [OFWebUIController dpiName]];
    //we load this async, thereby blocking the other performSelectors
#ifdef _DEBUG
    //when debugging, the manifest is built on the fly, which takes a long time
    const float timeOut = 100.0f;
#else
    const float timeOut = 10.f;
#endif
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                                     timeoutInterval:timeOut];
    NSHTTPURLResponse* response;
    NSError* error = nil;
    NSData* manifestData = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    if(error || response.statusCode < 200 || response.statusCode > 299) {
        //send ready to everything in the tracked list
        for(NSString* trackedPath in [self.tracked allKeys]) {
			[self _notifyItemReady:trackedPath];
        }
        self.pathsToLoad = [NSMutableSet set];  //this signals that the server manifest was loaded for purposes of tracking 
        //tell the system is it finished loading, since we can't really do anything else at this point
        [self performSelectorOnMainThread:@selector(loaderIsFinished) withObject:nil waitUntilDone:NO];        
    }
    else {
        //build itemsToLoad, strip deps
        //for everything in priority, add deps, screen by itemsToLoad
        //perform loadNextItem
        
        
        self.serverManifest = [[OFWebViewManifestData new] autorelease];
        [self.serverManifest populateWithData:manifestData];        
        self.localManifest = [NSMutableDictionary dictionaryWithContentsOfFile:[self.rootPath stringByAppendingPathComponent:@"manifest.plist"]];
        if(!self.localManifest) self.localManifest = [NSMutableDictionary dictionaryWithCapacity:10];

        //build list of items to load
        [self.trackingLock lock];
        self.pathsToLoad = [NSMutableSet setWithCapacity:10];
        for(NSString* itemPath in self.serverManifest.objects) {
            OFWebViewManifestItem* item = [self.serverManifest.objects objectForKey:itemPath];
            if (![item.serverHash isEqualToString:[self.localManifest objectForKey:itemPath]]) {
                [self.pathsToLoad addObject:item.path];
            }
        }        
        
        //filter the serverManifest dependencies down to these items
        
        for(NSString* itemPath in self.pathsToLoad) { //!all objects
            OFWebViewManifestItem* item = [self.serverManifest.objects objectForKey:itemPath];
            [item.dependentObjects intersectSet:self.pathsToLoad];
        }

        //find globals
        self.globals = [NSMutableSet setWithSet:self.serverManifest.globalObjects];
        [self.globals intersectSet:self.pathsToLoad];
        
        //maybe nuke items that don't need loading? (not in ITL and deps = empty set)//!no dependency
        //since the serverManifest is never iterated, this is likely of no use

        //find priority dependencies
        NSMutableSet *priorityAdds = [[NSMutableSet alloc] initWithCapacity:10];
        for(NSString* itemPath in self.priority) {
            OFWebViewManifestItem* item = [self.serverManifest.objects objectForKey:itemPath];
            [priorityAdds unionSet:item.dependentObjects];
        }
        [self.priority unionSet:priorityAdds];
        [priorityAdds release];
        [self.trackingLock unlock];
        
        //start the process
        //this "delay" is so that the run loop has a chance to perform any added selectors first
        [self performSelector:@selector(loadNextItem) withObject:nil afterDelay:0];
    }
}

-(void) finishItem:(NSString*) path success:(BOOL) loadingSuccess {
    OFLog(@"Finishing up %@ (success:%@)", path, loadingSuccess ? @"YES" : @"NO");
    [self.pathsToLoad removeObject:path];
    
    //update client manifest
    OFWebViewManifestItem*item = [self.serverManifest.objects objectForKey:path];
    NSString* objectHash = loadingSuccess ? item.serverHash : @"FAILED" ;  //if if failed to load, put bogus hash so it will try again next time
    [self.localManifest setObject:objectHash forKey:path];
    [self.localManifest writeToFile:[self.rootPath stringByAppendingPathComponent:@"manifest.plist"] atomically:YES];
    
    //do the next item
    [self performSelector:@selector(loadNextItem) withObject:nil afterDelay:0];
    [self.observers removeObjectForKey:path];
}


-(void)didSucceedDataForHelper:(OFWebViewLoaderHelper*)helper{
    if(self.abortedByReset) {
        [self performSelectorOnMainThread:@selector(loaderIsFinished) withObject:nil waitUntilDone:NO];        
        return;
    }
    
    if(helper.httpStatus == 200) {
        NSString* location = [self.rootPath stringByAppendingPathComponent:helper.path];
        //now need to clip last item from path, so I can get the directory path
        //wrteToFile doesn't have a "make dir" option
        NSString* lastPiece = [location lastPathComponent];
        NSString* locationDirectory = [location substringToIndex:[location length] - [lastPiece length] - 1];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:locationDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        [helper.httpData writeToFile:location atomically:YES];        
    }
    [self finishItem:helper.path success:YES];
}
-(void)didFailDataForHelper:(OFWebViewLoaderHelper*)helper{
    if(self.abortedByReset) {
        [self performSelectorOnMainThread:@selector(loaderIsFinished) withObject:nil waitUntilDone:NO];        
        return;
    }
    
    [self finishItem:helper.path success:NO];
}
-(void)loadNextItem {
    if(self.abortedByReset) {
        [self performSelectorOnMainThread:@selector(loaderIsFinished) withObject:nil waitUntilDone:NO];        
        return;
    }
	
	NSMutableSet* pathsToClear = nil;
	
    //scan each tracked to see if it is finished
    [self.globals intersectSet:self.pathsToLoad];
    if(self.globals.count == 0) {
        for(NSString* trackedPath in [self.tracked allKeys]) {
            BOOL loading = NO;
            if([self.pathsToLoad containsObject:trackedPath]) {
                loading = YES;
            }
            else {
                OFWebViewManifestItem*item = [self.serverManifest.objects objectForKey:trackedPath];
                NSMutableSet* testSet = [NSMutableSet setWithSet:item.dependentObjects];
                [testSet intersectSet:self.pathsToLoad];
                if(testSet.count) loading = YES;
            }
            if(!loading) {
				[self _notifyItemReady:trackedPath];
				
				// don't mutate a hash while iterating over it
				if (!pathsToClear) pathsToClear = [NSMutableSet setWithCapacity:1];
				[pathsToClear addObject:trackedPath];
            }
        }
    }
	
	if (pathsToClear)
	{
		for (NSString* path in pathsToClear)
		{
			[self.tracked removeObjectForKey:path];
		}
	}
	
    //are we done done?
    if(!self.pathsToLoad.count) {
        [self performSelectorOnMainThread:@selector(loaderIsFinished) withObject:nil waitUntilDone:NO];        
    }
    else {
        //find next item to load
        [self.trackingLock lock];
        NSString* nextItem = nil;
        [self.globals intersectSet:self.pathsToLoad];
        nextItem = [self.globals anyObject];
        if(!nextItem) {
            [self.priority intersectSet:self.pathsToLoad];
            nextItem = [self.priority anyObject];            
        }
        if(!nextItem) nextItem = [self.pathsToLoad anyObject];
        [self.trackingLock unlock];
        
        //create the HTTP load helper
        OFWebViewLoaderHelper* helper = [[OFWebViewLoaderHelper alloc] initWithPath:nextItem loader:self];
        [self.observers setObject:helper forKey:nextItem];
        [helper release];
    }
    
}

-(void) loaderIsFinished {
    [self.thread terminateRunLoop];
    self.thread = nil;  //close down the background thread
}
@end
