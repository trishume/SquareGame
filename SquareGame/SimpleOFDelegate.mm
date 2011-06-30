//
//  SimpleOFDelegate.m
//  SquareGame
//
//  Created by Tristan Hume on 11-06-29.
//  Copyright 2011 15 Norwich Way. All rights reserved.
//
#import "OpenFeint.h"
#import "SimpleOFDelegate.h"
#import "cocos2d.h"
@implementation SimpleOFDelegate

- (void)dashboardWillAppear
{
}

- (void)dashboardDidAppear
{
    [[CCDirector sharedDirector] pause];
    [[CCDirector sharedDirector] stopAnimation];
}

- (void)dashboardWillDisappear
{
}

- (void)dashboardDidDisappear
{
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] startAnimation];
}

- (void)userLoggedIn:(NSString*)userId
{
    OFLog(@"New user logged in! Hello %@", [OpenFeint lastLoggedInUserName]);
}

- (BOOL)showCustomOpenFeintApprovalScreen
{
    return NO;
}

@end

