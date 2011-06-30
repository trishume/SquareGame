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

#import "OFWebNavIntroFlowController.h"

#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"

#import "OFIntroNavigationController.h"

#import "OFBootstrapService.h"
#import "OFUserService.h"
#import "OFUser.h"
#import "OFControllerLoader.h"
#import "OFSettings.h"

@interface OFFramedNavigationController ()
- (OFFramedNavigationControllerVisibilityFlags)_visibilityFlagsForController:(UIViewController*)viewController;
@end

@implementation OFWebNavIntroFlowController

+ (id)controller
{
    return [self controllerWithTitle:@"OFWebNavIntroFlowController" htmlPath:@"testing.html" useContentFrame:YES];
}

- (id)initWithTitle:(NSString *)aTitle htmlPath:(NSString*)htmlPath useContentFrame:(BOOL)_useContentFrame
{
    if ((self = [super initWithTitle:aTitle htmlPath:htmlPath useContentFrame:_useContentFrame]))
    {
        [self mapAction:@"approve" toSelector:@selector(actionApprove:)];
        [self mapAction:@"navigateToURLWithUDID" toSelector:@selector(actionNavigateToURLWithUDID:)];
        [self mapAction:@"bootstrap" toSelector:@selector(actionBootstrap:)];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{   
    [super viewDidAppear:animated];
//    [self performSelector:@selector(serverDidTimeout) withObject:nil afterDelay:loadWaitTime];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
//    viewController.navigationItem.hidesBackButton = YES;
    [super pushViewController:viewController animated:animated];
    [self setNavbarVisibility];
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *vc = [super popViewControllerAnimated:animated];
    [self setNavbarVisibility];
    return vc;
}

- (void)setNavbarVisibility
{
    [self setNavigationBarHidden:YES animated:YES];
//    [self setNavigationBarHidden:([self.viewControllers count] <= 1) animated:YES];
}

- (void)setApprovedDelegate:(const OFDelegate&)_approvedDelegate andDeniedDelegate:(const OFDelegate&)_deniedDelegate
{
    approvedDelegate = _approvedDelegate;
	deniedDelegate   = _deniedDelegate;
}

- (void)webView:(UIWebView *)_webView didFailLoadWithError:(NSError *)error
{
    // Ignore errors resulting from a [webView stopLoading];
    if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled)
        return;
    
    OFLog(@"ERROR LOADING PAGE: %@", error);
    [self showOfflinePage:@"index"];
}

- (void)serverDidTimeout
{
    if ([webView isLoading] && ![[[[webView request] URL] scheme] isEqualToString:@"file"])
    {
        //self.viewControllers = [NSArray arrayWithObject:OFControllerLoader::load(@"UserFeintApproval")];
        [self showOfflinePage:@"index"];
    }
}

- (void)showOfflinePage:(NSString*)pageName
{
    OFAssert(false, "Offline support disbaled for now...");
    NSString *bundlePath = [[OpenFeint getResourceBundle] pathForResource:@"OFIntroFlow" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *htmlPath = [bundle pathForResource:pageName ofType:@"html"];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]];
    
    [webView loadRequest:req];
}

#pragma mark OFFramedNavigationController

- (OFFramedNavigationControllerVisibilityFlags)_visibilityFlagsForController:(UIViewController*)viewController
{
    OFFramedNavigationControllerVisibilityFlags v = [super _visibilityFlagsForController:viewController];
//    v.showNavBar = NO;
    return v;
}

#pragma mark Bootstrap Callbacks

- (void)bootstrapSuccess
{
    OFLog(@"Bootstrap Success!");
    
    // Find the session cookie
    NSArray *allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[[webView request] URL]];
    NSHTTPCookie *sessionCookie = nil;
    for (NSHTTPCookie *cookie in allCookies)
    {
        if ([[cookie name] isEqualToString:@"_of_session"])
        {
            sessionCookie = cookie;
        }
    }
    
    // It's very important we have one of these...
    OFAssert(sessionCookie, @"Must have a session cookie!");
    
    // convert the session cookie back into a javascript settable string
    NSDictionary *headerFieldsForCookies = [NSHTTPCookie requestHeaderFieldsWithCookies:[NSArray arrayWithObject:sessionCookie]];
    NSString *sessionCookieString = [headerFieldsForCookies objectForKey:@"Cookie"];
    
    // Tell the webview we bootstrapped and set the new session cookie
    NSString *js = [NSString stringWithFormat:@"onBootstrap({ newAccount:%@, cookies:\"%@\" })",
                    (createdNewAccount ? @"true" : @"false"),
                    sessionCookieString];
    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)bootstrapFailed
{
    OFLog(@"Bootstrap Failure!");
}

#pragma mark -
#pragma mark Actions

- (void)actionApprove:(NSDictionary*)options
{
    [OpenFeint setUserApprovedFeint];
    if ([options objectForKey:@"url"])
    {
        // Approve, then navigate to a URL
        [self performSelector:@selector(pushURLString:) withObject:[options objectForKey:@"url"] afterDelay:0.5];
    }
    else
    {
        // Approve then show the offline approval confirmation form
        [self showOfflinePage:@"confirm"];
    }
}

- (void)actionNavigateToURLWithUDID:(NSDictionary*)options
{
    // Getting to this step means the user approved Open Feint
    [OpenFeint setUserApprovedFeint];
    
    // Redirect to the URL, with the udid appended to it
    NSString *targetURL = [options objectForKey:@"url"];
    targetURL = [targetURL stringByAppendingFormat:@"?udid=%@", [UIDevice currentDevice].uniqueIdentifier];
    [self performSelector:@selector(pushURLString:) withObject:targetURL afterDelay:0.5];
}

- (void)actionDismissNavController
{
    // If has not yet enabled/denied OF, and we are dismissing, then that means they have denied it.
    if (![OpenFeint hasUserSetFeintAccess])
    {
        [OpenFeint setUserDeniedFeint];
        deniedDelegate.invoke();
    }
    
    [OpenFeint allowErrorScreens:YES];
    [OpenFeint dismissRootControllerOrItsModal];
}

- (void)actionBootstrap:(NSDictionary*)options
{
    NSString *userId = [options objectForKey:@"user_id"];
    createdNewAccount = userId ? NO : YES;
    
    [self showLoadingIndicator];

	if (createdNewAccount)
	{
		[OpenFeint 
			doBootstrapAsNewUserOnSuccess:OFDelegate(self, @selector(bootstrapSuccess))
			onFailure:OFDelegate(self, @selector(bootstrapFailed))];
	}
	else
	{
		[OpenFeint 
			doBootstrapAsUserId:userId
			onSuccess:OFDelegate(self, @selector(bootstrapSuccess))
			onFailure:OFDelegate(self, @selector(bootstrapFailed))];        
	}
}

@end
