//
//  SimpleOFDelegate.h
//  SquareGame
//
//  Created by Tristan Hume on 11-06-29.
//  Copyright 2011 15 Norwich Way. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenFeintDelegate.h"
@interface SimpleOFDelegate : NSObject< OpenFeintDelegate >
- (void)dashboardWillAppear;
- (void)dashboardDidAppear;
- (void)dashboardWillDisappear;
- (void)dashboardDidDisappear;
- (void)userLoggedIn:(NSString*)userId;
- (BOOL)showCustomOpenFeintApprovalScreen;
@end

