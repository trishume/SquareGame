////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009 Aurora Feint, Inc.
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

#import "OFWebUIController.h"

#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Settings.h"
#import "OFSettings.h"
#import "OFUser.h"
#import "OFXPRequest.h"
#import "UIScreen+OpenFeint.h"
#import "NSString+URLEscapingAdditions.h"
#import "OFWebUIConfirmationDelegate.h"
#import "OFWebUIChoiceDelegate.h"
#import "OFXPGenericRequestHandler.h"

#import <QuartzCore/QuartzCore.h>

@interface OFWebUIController (Private)
- (void)_loadEnvironment;
- (NSString*)_clientBootJSON;

- (UIImage*)_generateTransitionImage;
- (void)_animateTransition:(BOOL)isPush;

- (void)_accumulateQueryParametersForDictionary:(NSDictionary*)dict withPrefix:(NSString*)prefix intoArray:(NSMutableArray*)accum;
- (void)_accumulateQueryParametersForArray:(NSArray*)array withPrefix:(NSString*)prefix intoArray:(NSMutableArray*)accum;

@end

@implementation OFWebUIController

@synthesize webView, navBar, navBarBackground, loadingView, transitionImage;
@synthesize actionMap, initialPath;

+ (NSString*)dpiName {
	if ([UIScreen mainScreen].safeScale != 1.0) {
		return @"udpi";
	} else {
        return @"mdpi";
    }
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithRootPage:(NSString*)_rootPage andPath:(NSString*)_initialPath {
    if ((self = [super initWithNibName:nil bundle:nil])) {
		rootPage = [_rootPage retain];
        self.initialPath = _initialPath;
        self.actionMap = [NSMutableDictionary dictionary];
        
        [self mapAction:@"batch"            toSelector:@selector(actionBatch:)];
        [self mapAction:@"log"              toSelector:@selector(actionLog:)];
        [self mapAction:@"startLoading"     toSelector:@selector(actionStartLoading:)];
        [self mapAction:@"contentLoaded"    toSelector:@selector(actionContentLoaded:)];
        [self mapAction:@"back"             toSelector:@selector(actionBack:)];
        [self mapAction:@"showLoader"       toSelector:@selector(actionShowLoader:)];
        [self mapAction:@"hideLoader"       toSelector:@selector(actionHideLoader:)];
        [self mapAction:@"addBarButton"     toSelector:@selector(actionAddBarButton:)];
        [self mapAction:@"alert"            toSelector:@selector(actionAlert:)];
        [self mapAction:@"confirm"          toSelector:@selector(actionConfirm:)];
        [self mapAction:@"choose"           toSelector:@selector(actionChoose:)];
        [self mapAction:@"dismiss"          toSelector:@selector(actionDismiss:)];
        [self mapAction:@"reload"           toSelector:@selector(actionReload:)];
        [self mapAction:@"apiRequest"       toSelector:@selector(actionApiRequest:)];
        [self mapAction:@"writeSetting"     toSelector:@selector(actionWriteSetting:)];
        [self mapAction:@"readSetting"      toSelector:@selector(actionReadSetting:)];
    }
    return self;
}

- (id)initWithPath:(NSString*)_initialPath {
	return [self initWithRootPage:@"index.html" andPath:_initialPath];
}

- (id)initForSpecWithPath:(NSString*)_initialPath {
	return [self initWithRootPage:@"spec.html" andPath:_initialPath];
}

- (void)dealloc {
	webView.delegate = nil;
    self.webView = nil;
    self.navBar = nil;
    self.loadingView = nil;
    self.transitionImage = nil;
    
    self.actionMap = nil;
    self.initialPath = nil;
    
	OFSafeRelease(rootPage);
    OFSafeRelease(crashReporter);
    
    [super dealloc];
}

- (UIImage*)navBarBackgroundImage
{
	return nil;
}

- (void)_orderViewDepthsForNavItem:(UINavigationItem*)navItem
{
	if (navBarBackground)
	{
		[navBar sendSubviewToBack:navBarBackground];
		UIView* titleView = navItem.titleView;
		[titleView.superview bringSubviewToFront:titleView];
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.navBar = nil;
	self.navBarBackground = nil;
	webView.delegate = nil;
	self.webView = nil;
	self.transitionImage = nil;
	self.loadingView = nil;	
    envIsLoaded = NO;
    backTriggeredFromCode = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    
    CGRect navBarFrame  = CGRectMake(0, 0, self.view.frame.size.width, 44);
    CGRect contentFrame = CGRectMake(0, navBarFrame.size.height,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height - navBarFrame.size.height);
    
    // Main view
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    
    // Nav Bar
    self.navBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)] autorelease];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    navBar.delegate = self;
    [self.view addSubview:navBar];

	UIImage* navBG = [self navBarBackgroundImage];
	if (navBG)
	{
		self.navBarBackground = [[UIImageView alloc] initWithImage:navBG];
		[navBarBackground release];
		navBarBackground.frame = navBar.bounds;
		navBarBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		navBarBackground.userInteractionEnabled = NO;
		
		[navBar addSubview:navBarBackground];
		[navBar sendSubviewToBack:navBarBackground];
	}
    
    // Web View
    self.webView = [[[UIWebView alloc] initWithFrame:contentFrame] autorelease];
	webView.alpha = 0.f;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.dataDetectorTypes = UIDataDetectorTypeNone;
    webView.delegate = self;
    [webView setBackgroundColor:[UIColor clearColor]];
    [webView setOpaque:NO];
    [self.view addSubview:webView];
    
    // Remove drop shadows from the areas past the rubber band scroll
    // the shadow views should be the only UIImageViews
    for (UIView *subview in [[[webView subviews] objectAtIndex:0] subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            subview.hidden = YES;
        }
    }
    
    // Transition Image
    self.transitionImage = [[[UIImageView alloc] initWithFrame:contentFrame] autorelease];
    transitionImage.hidden = YES;
    [self.view addSubview:transitionImage];
    
    // Loading View
    self.loadingView = [self createLoadingView];
    [self.view addSubview:loadingView];    
    
    // Done with view setup
    
    // Ensure we are synced for the global base assets
    [OFWebViewManifestService trackPath:rootPage forMe:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self executeJavascript:[NSString stringWithFormat:@"OF.setOrientation('%@')",
                             UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? @"portrait" : @"landscape"]];
}

- (BOOL)shouldUnloadViewOnMemoryWarning
{
	return NO;
}

- (void)didReceiveMemoryWarning
{
	// by default, do NOT call super, so we do NOT unload our view and lose all JS context.
	if ([self shouldUnloadViewOnMemoryWarning])
	{
		[super didReceiveMemoryWarning];
	}
}

- (OFWebUILoadingView*)createLoadingView {
    return [[[OFWebUILoadingView alloc] initWithFrame:webView.frame] autorelease];
}

// Load up the base HTML and JS environment of WebUI by loading the root page
- (void)_loadEnvironment {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [OFWebViewManifestService rootPath], rootPage];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:url]]];
}

- (NSString*)_clientBootJSON {
    return [OFJsonCoder encodeObject:[self environmentData]];
}

- (void)_reenableBarButton
{
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)didTapBarButton {
	self.navigationItem.rightBarButtonItem.enabled = NO;
	// Prevent hammering
	[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(_reenableBarButton) userInfo:nil repeats:NO];
    [self executeJavascript:@"if (OF.page.barButtonTouch) OF.page.barButtonTouch()"];
}

- (void)setPageTitle:(NSString*)pageTitle forNavItem:(UINavigationItem*)navItem {
    if ([pageTitle hasSuffix:@".png"]) {
        if (navItem.titleView) return;
        
        navItem.title = nil;
        
        NSString *imagePath = [pageTitle stringByReplacingOccurrencesOfString:@"xdpi" withString:[OFWebUIController dpiName]];
        imagePath = [[OFWebViewManifestService rootPath] stringByAppendingFormat:@"/%@", imagePath];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
		if ([image respondsToSelector:@selector(initWithCGImage:scale:orientation:)])
		{
			image = [[[UIImage alloc] initWithCGImage:image.CGImage scale:[UIScreen mainScreen].safeScale orientation:UIImageOrientationUp] autorelease];
		}
        navItem.titleView = [[[UIImageView alloc] initWithImage:image] autorelease];
    } else {
        navItem.title = pageTitle;
    }
	
	[self performSelector:@selector(_orderViewDepthsForNavItem:) withObject:navItem afterDelay:0.05];
}

#pragma mark -
#pragma mark Environment Dictionaries

- (NSDictionary*)environmentData {
    NSDictionary *supports = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], @"actionJSON",
                              nil];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation) ? @"portrait" : @"landscape", @"orientation",
#ifdef _DEBUG
            [NSNumber numberWithBool:YES],                  @"disableGA",
#endif
            [OFWebUIController dpiName],                    @"dpi",
            OFSettings::Instance()->getServerUrl(),         @"serverUrl",
            @"ios",                                         @"platform",
            [NSNumber numberWithBool:NO],                   @"hasNativeInterface",
            [[NSLocale currentLocale] localeIdentifier],    @"locale",
            [self actions],                                 @"actions",
            [self currentDeviceData],                       @"device",
            [self currentUserData],                         @"user",
            [self currentGameData],                         @"game",
            supports,                                       @"supports",
            nil];    
}

- (NSDictionary*)currentUserData {
    NSDictionary *socialNetworks = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:[OpenFeint loggedInUserHasFbconnectCredential]], @"facebook",
                                    [NSNumber numberWithBool:[OpenFeint loggedInUserHasTwitterCredential]],   @"twitter",
                                    nil];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [[OpenFeint localUser] name],         @"name",
            [[OpenFeint localUser] resourceId],   @"id",
            socialNetworks,                       @"socialNetworks",
            [NSNumber numberWithBool:[OpenFeint loggedInUserHasHttpBasicCredential]], @"unsecured",
            nil];
}

- (NSDictionary*)currentDeviceData {
    UIDevice *currentDevice = [UIDevice currentDevice];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            currentDevice.uniqueIdentifier,  @"identifier",
            currentDevice.model, @"hardware",
            [NSString stringWithFormat:@"%@ %@", currentDevice.systemName, currentDevice.systemVersion], @"os",
            nil];
}

- (NSDictionary*)currentGameData {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [OpenFeint applicationDisplayName], @"name",
            [OpenFeint clientApplicationId], @"id",
            [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], @"version",
            nil];
}

- (NSArray*)actions {
    NSMutableArray *actions = [NSMutableArray array];
    for (NSString *actionName in [actionMap allKeys]) {
        [actions addObject:actionName];
    }
    return actions;
}

#pragma mark -
#pragma mark Utility

- (NSString*)executeJavascript:(NSString*)js {
    return [webView stringByEvaluatingJavaScriptFromString:js];
}

- (NSString*)unescapeUrlEncoding:(NSString*)str {
    return [(NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
																			   (CFStringRef)str,
																			   CFSTR(""),
																			   NSUnicodeStringEncoding)
			autorelease];
}

- (NSString*)escapeUrlEncoding:(NSString*)str {
	
	return [str stringByAddingURIPercentEscapesUsingEncoding:NSUnicodeStringEncoding];
}

- (NSString*)jsonifyPath:(NSString*)path {
    // Get just the filename
    if ([path rangeOfString:@"?"].location != NSNotFound) {
        path = [[path componentsSeparatedByString:@"?"] objectAtIndex:0];
    }
    
    // Ensure it's a json file
    if (![path hasSuffix:@".json"]) {
        path = [path stringByAppendingString:@".json"];
    }
    
    return path;
}

#pragma mark -
#pragma mark Animation

- (UIImage*)_generateTransitionImage {
    UIImage *image;
    
    UIGraphicsBeginImageContext(webView.bounds.size);
    [webView.layer renderInContext:UIGraphicsGetCurrentContext()];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)_animateTransition:(BOOL)isPush {
    
    // Set the image of the transitionView to a copy of the webView
    transitionImage.image = [self _generateTransitionImage];
    
    // Store some common values for our target CGRect's
    float y         = webView.frame.origin.y;
    float width     = webView.frame.size.width;
    float height    = webView.frame.size.height;
    
    // Create our 3 target frames for all positions the views can be in
    CGRect left     = CGRectMake(-width, y, width, height);
    CGRect center   = CGRectMake(0,      y, width, height);
    CGRect right    = CGRectMake(width,  y, width, height);
    
    // set the start and end rects for the transitionImage
    CGRect oldFrom  = center;
    CGRect oldTo    = isPush ? left : right;
    
    // set the start and end rects for the webView
    CGRect newFrom  = isPush ? right : left;
    CGRect newTo    = center;
    
    // Set initial alphas
    transitionImage.hidden = NO;
    webView.alpha = 0.0;
    
    // Set the initial position of the views
    transitionImage.frame = oldFrom;
    webView.frame         = newFrom;
    
    // Animate the views
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.35];
    transitionImage.frame = oldTo;
    webView.frame         = newTo;
    [UIView commitAnimations];
}

- (void)animatePush {
    [self _animateTransition:YES];
}

- (void)animatePop {
    [self _animateTransition:NO];
}


-(void) crashReporterFinished {
    [self webViewCacheItemReady:rootPage];
    OFSafeRelease(crashReporter);
}

#pragma mark -
#pragma mark UIWebViewManifestDelegate

- (void)webViewCacheItemReady:(NSString *)path {
	if (![self isViewLoaded])
	{
		// In the case where we unloaded the view due to a low memory warning,
		// the bootup sequence can be aborted.
		return;
	}
    
    // global base assets load
    if ([path isEqualToString:rootPage]) {
        [self _loadEnvironment];
    }
    
    // page content load
    else {
        NSString *pageJson = [NSString stringWithContentsOfFile:[[OFWebViewManifestService rootPath] stringByAppendingFormat:@"/%@", path] usedEncoding:nil error:NULL];
        if ([pageJson hasPrefix:@"{"] && [pageJson hasSuffix:@"}"]) {
            [self executeJavascript:[NSString stringWithFormat:@"OF.push.ready(%@)", pageJson]];
        } else {
            [self executeJavascript:[NSString stringWithFormat:@"alert('Missing or invalid template! %@')", path]];
        }
    }
}

#pragma mark -
#pragma mark UIWebViewDelegate

// Action passing URL format:
//      openfeint://<instruction>/<name>[?<arg1>=<val1>]
//      openfeint://action/log?message=sampleLogMessage

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *requestURL = [request URL];
    if ([[requestURL absoluteString] isEqualToString:@"about:blank"]) {
        // Allow iframes that start without a src to make themselves ready
        return YES;
    }
    else if ([[requestURL path] rangeOfString:@"webui/analytics"].location != NSNotFound) {
        // Allow Google Analytics to load
        return YES;
    }
    else if (envIsLoaded) {
        // Process action messages
        if ([[requestURL scheme] isEqualToString:@"openfeint"]) {
            if ([[requestURL host] isEqualToString:@"action"]) {
                [self dispatchAction:requestURL];
            }
        }
        
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if(error.code != -999) { //this means the action was canceled, which isn't an error
        [[[[UIAlertView alloc] initWithTitle:OFLOCALSTRING(@"Failed to load")
                                     message:OFLOCALSTRING(@"Sorry, but we had a problem displaying this screen.  Please try again soon.")
                                    delegate:nil
                           cancelButtonTitle:OFLOCALSTRING(@"OK")
                           otherButtonTitles:nil] autorelease] show];
        OFLog(@"OFWebUIController load error: %@", error);
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (envIsLoaded) return;
    envIsLoaded = YES;
    
    NSString* checkForFailure = [self executeJavascript:[NSString stringWithFormat:@"OF.init.clientBoot(%@);", [self _clientBootJSON]]];
    if(![checkForFailure isEqualToString:@"true"]) {
        crashReporter = [[OFWebUICrashReporter alloc] initWithDelegate:self];
    }
    else {
        [self executeJavascript:[NSString stringWithFormat:@"OF.push('%@');", [self initialPath]]];
    }
}
#pragma mark -
#pragma mark UINavigationBarDelegate

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    // abort if we are already loading stuff.
    if (![[self executeJavascript:@"OF.init.isLoaded"] isEqualToString:@"true"]) return NO;
    if (floor(webView.alpha) == 0) return NO;
    
    if (backTriggeredFromCode) {
        backTriggeredFromCode = NO;
        return YES;
    } else {
        [self executeJavascript:@"OF.goBack()"];
        return NO;
    }
}

#pragma mark -
#pragma mark Action Handling

// Maps an action name to a method to handle it.
- (void)mapAction:(NSString*)actionName toSelector:(SEL)selector {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:self];
    [actionMap setObject:invocation forKey:actionName];
}

// Breaks a url encoded URL like:"openfeint://action/actionName?foo=bar&zing=bang"
// into a dictionary like: { "foo":"bar", "zing":"bang" }
- (NSDictionary*)optionsForAction:(NSURL*)actionURL {
    NSString *query = [actionURL query];
    if (query) {
        query = [self unescapeUrlEncoding:query];        
        return [OFJsonCoder decodeJson:query];
    } else {
        return nil;
    }
}

- (void)_accumulateQueryParametersForDictionary:(NSDictionary*)dict withPrefix:(NSString*)prefix intoArray:(NSMutableArray*)accum
{
	
	for (NSString* k in [dict allKeys])
	{
		id v = [dict objectForKey:k];
		NSString* p = prefix ? [NSString stringWithFormat:@"%@[%@]", prefix, k] : k;
		if ([v isKindOfClass:[NSArray class]])
		{
			[self _accumulateQueryParametersForArray:(NSArray*)v withPrefix:p intoArray:accum];
		}
		else if ([v isKindOfClass:[NSDictionary class]])
		{
			[self _accumulateQueryParametersForDictionary:(NSDictionary*)v withPrefix:p intoArray:accum];
		}
		else
		{
			[accum addObject:[NSString stringWithFormat:@"%@=%@", p, [v description]]];
		}
	}
}

- (void)_accumulateQueryParametersForArray:(NSArray*)array withPrefix:(NSString*)prefix intoArray:(NSMutableArray*)accum
{
	NSString* p = [NSString stringWithFormat:@"%@[]", prefix];
	for (NSString* o in array)
	{
		if ([o isKindOfClass:[NSArray class]])
		{
			[self _accumulateQueryParametersForArray:(NSArray*)o withPrefix:p intoArray:accum];
		}
		else if ([o isKindOfClass:[NSDictionary class]])
		{
			[self _accumulateQueryParametersForDictionary:(NSDictionary*)o withPrefix:p intoArray:accum];
		}
		else
		{
			[accum addObject:[NSString stringWithFormat:@"%@=%@", p, [o description]]];
		}
	}
}

- (NSString*)queryStringForOptions:(NSDictionary*)options
{
	NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:[options count]];
	[self _accumulateQueryParametersForDictionary:options withPrefix:nil intoArray:arr];
	NSString* rv = [arr componentsJoinedByString:@"&"];
	[arr release];
	return rv;
}

// Convert a url into an action name and arguments, then invoke it
- (void)dispatchAction:(NSURL*)actionURL {
    NSString *name = [[actionURL path] substringFromIndex:1];
    NSDictionary *options = [self optionsForAction:actionURL];
    [self dispatchAction:name options:options];
}

// Dispatcher for mapping a string action name and it's arguments to action handler methods
- (void)dispatchAction:(NSString*)name options:(NSDictionary*)options {
    
    if (![name isEqualToString:@"log"]) {
        OFLog(@"ACTION: %@ %@", name, options);
    }
    
    NSInvocation *invocation = [actionMap objectForKey:name];
    if (invocation) {
        if ([[invocation methodSignature] numberOfArguments] > 2) { // Always has at least 2 args. 3 means method takes one argument (Our options dictionary)
            [invocation setArgument:&options atIndex:2];
        }
        [invocation invokeWithTarget:self];
    } else {
        OFLog(@"UNHANDLED ACTION: %@ %@", name, options);
    }
}

#pragma mark Specific Action Handlers

// Handle multiple actions at once in a batch
- (void)actionBatch:(NSDictionary *)options {
    NSArray *actions = [options objectForKey:@"actions"];
    OFLog(@"========================================\nACTION BATCH: %d actions", [actions count]);
    
    for (NSDictionary *action in actions) {
        NSString     *name    = [action objectForKey:@"name"];
        NSDictionary *options = [action objectForKey:@"options"];
        [self dispatchAction:name options:options];
    }
}

// Print something to the native log
- (void)actionLog:(NSDictionary*)options {
    OFLog(@"WEBLOG: %@", [options objectForKey:@"message"]);
}

// Start loading a new page.  Verify manifest is up to date for this content.
- (void)actionStartLoading:(NSDictionary*)options {
    UINavigationItem *navItem = [[[UINavigationItem alloc] init] autorelease];
    [self setPageTitle:[options objectForKey:@"title"] forNavItem:navItem];    
    [navBar pushNavigationItem:navItem animated:YES];
    
    // Animate the next page in, unless it's the first page
    if ([navBar.items count] > 1) {
        [self animatePush];
    }
    
    if ([OFWebViewManifestService trackPath:[self jsonifyPath:[options objectForKey:@"path"]] forMe:self]) {
        [loadingView show];
    }
}

// Content loaded and ready for interaction
- (void)actionContentLoaded:(NSDictionary*)options {
    // Fade in
    [UIView beginAnimations:nil context:nil];
    webView.alpha = 1.0;
    [UIView commitAnimations];
    
    // Make sure we dont have more navbar items that WebUI does
    uint webuiStackSize = [[self executeJavascript:@"OF.pages.length"] intValue];
    
    while ([navBar.items count] > webuiStackSize) {
        NSMutableArray *items = [NSMutableArray arrayWithArray:navBar.items];
        [items removeObjectAtIndex:0];
        navBar.items = items;
    }
    
    // Make sure we dont have less navbar items that WebUI does
    while ([navBar.items count] < webuiStackSize) {
        NSMutableArray *items = [NSMutableArray arrayWithArray:navBar.items];
        [items insertObject:[[[UINavigationItem alloc] initWithTitle:@""] autorelease] atIndex:0];
        navBar.items = items;
    }
    
    
    // Ensure loading view is hidden
    [loadingView hide];
    
    // Ensure page title is up to date
    [self setPageTitle:[options objectForKey:@"title"] forNavItem:[navBar topItem]];
}

// Go back
- (void)actionBack:(NSDictionary*)options {
    backTriggeredFromCode = YES;
    [navBar popNavigationItemAnimated:YES];
    [self animatePop];
}

// Not curently used as there is no globally blocking client based loader
- (void)actionShowLoader:(NSDictionary*)options {}
- (void)actionHideLoader:(NSDictionary*)options {}

// Add a bar button to the navbar fo this screen
- (void)actionAddBarButton:(NSDictionary*)options {
    UIBarButtonItem *button;
    if ([options objectForKey:@"title"]) {
        button = [[[UIBarButtonItem alloc] initWithTitle:[options objectForKey:@"title"]
                                                   style:UIBarButtonItemStyleBordered
                                                  target:self
                                                  action:@selector(didTapBarButton)] autorelease];        
    } else {
        NSString *imagePath = [[OFWebViewManifestService rootPath] stringByAppendingFormat:@"/%@", [options objectForKey:@"image"]];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        button = [[[UIBarButtonItem alloc] initWithImage:image
                                                   style:UIBarButtonItemStyleBordered
                                                  target:self
                                                  action:@selector(didTapBarButton)] autorelease];
    }
    
    navBar.topItem.rightBarButtonItem = button;
}

// Show a native alert
- (void)actionAlert:(NSDictionary*)options {
    [[[[UIAlertView alloc] initWithTitle:[options objectForKey:@"title"]
                                 message:[options objectForKey:@"message"]
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil] autorelease] show];
}

// Show a native confirmation dialog
- (void)actionConfirm:(NSDictionary*)options {
    [[[[UIAlertView alloc] initWithTitle:[options objectForKey:@"title"]
                                 message:[options objectForKey:@"message"]
                                delegate:[OFWebUIConfirmationDelegate delegateWithNav:self andCb:[options objectForKey:@"callback"]]
                       cancelButtonTitle:[options objectForKey:@"negative"]
                       otherButtonTitles:[options objectForKey:@"positive"], nil] autorelease] show];
}

// Show a multiple choice action sheet
- (void)actionChoose:(NSDictionary*)options {
    UIActionSheet *sheet = [[[UIActionSheet alloc] init] autorelease];
    sheet.title = [options objectForKey:@"title"];
    
    NSArray *buttons = [options objectForKey:@"options"];
    NSMutableArray *callbacks = [NSMutableArray arrayWithCapacity:[buttons count]];
    
    for (NSDictionary *button in buttons) {
        // Set button title
        [sheet addButtonWithTitle:[button objectForKey:@"title"]];
        
        // Save the calback
        id callback = [button objectForKey:@"callback"];
        [callbacks addObject:callback ? callback : [NSNull null]];
        
        // Set button type
        if ([[button objectForKey:@"cancel"]      boolValue]) sheet.cancelButtonIndex      = sheet.numberOfButtons - 1;
        if ([[button objectForKey:@"destructive"] boolValue]) sheet.destructiveButtonIndex = sheet.numberOfButtons - 1;
    }
    
    sheet.delegate = [OFWebUIChoiceDelegate delegateWithNav:self andCallbacks:callbacks];
    
    [sheet showInView:self.view];
}

// Reload this flow from scratch
- (void)actionReload:(NSDictionary*)options {
    envIsLoaded = false;
    navBar.items = [NSArray array];
    [webView reload];
}


// Make this controller go away
- (void)actionDismiss:(NSDictionary*)options {
    [self dismissModalViewControllerAnimated:YES];
}

// Perform an XP API request
- (void)actionApiRequest:(NSDictionary*)options {
    OFXPRequest *req = [OFXPRequest requestWithPath:[options objectForKey:@"path"]
                                          andMethod:[options objectForKey:@"method"]
                                       andArgString:[options objectForKey:@"params"]];
    
    // WebUI flows need to work without OFUser login non-authenticated
    req.requiresUserSession = NO;
    
    [req onRespondText:[OFXPGenericRequestHandler handlerWithWebView:self andRequestId:[options objectForKey:@"request_id"]]];
    [req execute];
}

// Write a key and value to NSUserDefaults
- (void)actionWriteSetting:(NSDictionary*)options {
    NSString *key = [@"OF_" stringByAppendingString:[options objectForKey:@"key"]];
    NSString *val = [options objectForKey:@"value"];
    [[NSUserDefaults standardUserDefaults] setObject:val forKey:key];
}

// Read a setting from NSUserDefaults, and return its value to the webui flow
- (void)actionReadSetting:(NSDictionary*)options {
    NSString *key       = [@"OF_" stringByAppendingString:[options objectForKey:@"key"]];
    NSString *callback  = [options objectForKey:@"callback"];
    NSString *val       = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    [self executeJavascript:[NSString stringWithFormat:@"%@(%@)", callback, (val ? val : @"null")]];
}

- (void)replaceFlow:(NSString*)templatePath
{
	navBar.items = [NSArray array];
	[self executeJavascript:[NSString stringWithFormat:@"OF.pages.replace('%@');", templatePath]];
}

- (void)showLoadingScreen
{
	[loadingView show];
	webView.alpha = 0.0f;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame]; 
    self.view = view; 
    [view release]; 
}

@end
