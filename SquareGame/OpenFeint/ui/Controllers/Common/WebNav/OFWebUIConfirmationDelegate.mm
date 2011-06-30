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

#import "OFWebUIConfirmationDelegate.h"
#import "OFWebUIController.h"

@implementation OFWebUIConfirmationDelegate

@synthesize webNav, cb;

+ (OFWebUIConfirmationDelegate*)delegateWithNav:(OFWebUIController*)nav andCb:(NSString*)cb
{
	OFWebUIConfirmationDelegate* rv = [[self alloc] init];
	rv.webNav = nav;
	rv.cb = cb;
	return rv;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (self.webNav && self.cb)
	{
		[self.webNav executeJavascript:[NSString stringWithFormat:@"%@(%@);", self.cb, (alertView.cancelButtonIndex == buttonIndex ? @"false" : @"true")]];
	}
	[self release];
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
	if (self.webNav && self.cb)
	{
		[self.webNav executeJavascript:[NSString stringWithFormat:@"%@(false);", self.cb]];
	}
	[self release];
}

- (void)dealloc
{
	self.webNav = nil;
	self.cb = nil;
	[super dealloc];
}

@end
