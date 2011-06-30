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

#import "OFFBDialog.h"
#import "OpenFeint+Private.h"

@interface FBDialog ()
- (void)keyboardWillShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;
@end

@implementation OFFBDialog

- (void)showInView:(UIView*)containerView
{
    [self show];
    if ([OpenFeint isLargeScreen])
    {
        if ([OpenFeint isInLandscapeModeOniPad])
        {
            CGRect fbFrame = self.frame;
            fbFrame.size.width = 400;
            
            if ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationLandscapeRight)
            {
                fbFrame.origin.x += 50;
            }
            
            self.frame = fbFrame;
        }
    }
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    if ([OpenFeint isLargeScreen])
    {
        [self moveUp:YES];
    }
    else
    {
        [super keyboardWillShow:notification];
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    if ([OpenFeint isLargeScreen])
    {
        [self moveUp:NO];
    }
    else
    {
        [super keyboardWillHide:notification];
    }
}

- (void)moveUp:(BOOL)directionIsUp
{
    if (![OpenFeint isLargeScreen]) return;
	
	if((directionIsUp && isSlidUp) || (!directionIsUp && !isSlidUp))
	{
		//Don't double slide up or down.  Double sliding down acutally happened because of some bug in the uiwebview/facebook stuff, keyboardWillHide is called twice when pressing the "connect" button on the fbdialog.
		return;
	}
    
    NSInteger direction;
	if(directionIsUp)
	{
		direction = 1;
		isSlidUp = true;
	}
	else
	{
		direction = -1;
		isSlidUp = false;
	}
	
    CGRect fbFrame = self.frame;
    
    switch ([OpenFeint getDashboardOrientation]) {
        case UIInterfaceOrientationPortrait:
            fbFrame.origin.y -= 150 * direction;
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            fbFrame.origin.y += 150 * direction;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            fbFrame.origin.x -= 150 * direction;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            fbFrame.origin.x += 150 * direction;
            break;            
    }
    
    [UIView beginAnimations:nil context:nil];
    self.frame = fbFrame;
    [UIView commitAnimations];
    
}


@end
