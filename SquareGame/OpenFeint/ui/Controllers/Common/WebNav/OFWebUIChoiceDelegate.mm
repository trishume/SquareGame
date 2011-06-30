//
//  OFWebUIChoiceDelegate.mm
//  Spotlight
//
//  Created by Alex Wayne on 2/1/11.
//  Copyright 2011 Beautiful Pixel. All rights reserved.
//

#import "OFWebUIChoiceDelegate.h"


@implementation OFWebUIChoiceDelegate

@synthesize webuiController, callbacks;

+ (OFWebUIChoiceDelegate*)delegateWithNav:(OFWebUIController*)_webuiController andCallbacks:(NSArray*)_callbacks {
	OFWebUIChoiceDelegate* instance = [[self alloc] init];
	instance.webuiController = _webuiController;
	instance.callbacks = _callbacks;
	return instance;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *callback = [self.callbacks objectAtIndex:buttonIndex];
    if ([callback isKindOfClass:[NSString class]]) {
		[self.webuiController executeJavascript:[NSString stringWithFormat:@"%@();", callback]];
	}
	[self release];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    NSString *callback = [self.callbacks objectAtIndex:actionSheet.cancelButtonIndex];
    if ([callback isKindOfClass:[NSString class]]) {
		[self.webuiController executeJavascript:[NSString stringWithFormat:@"%@();", callback]];
	}
	[self release];
}

- (void)dealloc {
    self.webuiController = nil;
    self.callbacks = nil;
    [super dealloc];
}


@end
