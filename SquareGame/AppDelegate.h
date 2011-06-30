//
//  AppDelegate.h
//  SquareGame
//
//  Created by Tristan Hume on 11-06-25.
//  Copyright 15 Norwich Way 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;
@class SimpleOFDelegate; // Add for OpenFeint


@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
    SimpleOFDelegate *ofDelegate; // Add for OpenFeint

}

@property (nonatomic, retain) UIWindow *window;

@end
