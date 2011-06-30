//
//  OFWebUIChoiceDelegate.h
//  Spotlight
//
//  Created by Alex Wayne on 2/1/11.
//  Copyright 2011 Beautiful Pixel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OFWebUIController.h"

@interface OFWebUIChoiceDelegate : NSObject<UIActionSheetDelegate> {
    OFWebUIController* webuiController;
	NSArray* callbacks;
}

@property (nonatomic, retain) OFWebUIController* webuiController;
@property (nonatomic, retain) NSArray* callbacks;

+ (OFWebUIChoiceDelegate*)delegateWithNav:(OFWebUIController*)webuiController andCallbacks:(NSArray*)callbacks;

@end
