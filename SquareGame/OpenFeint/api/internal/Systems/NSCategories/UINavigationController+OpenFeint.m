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

#import "UINavigationController+OpenFeint.h"
#import "UIKit/UINavigationController.h"

@implementation UINavigationController (OpenFeint)

- (UIViewController*)previousViewController:(UIViewController*)childViewController
{
	NSArray* controllers = self.viewControllers;
	UIViewController* lastController = nil;
	for (UIViewController* walk in controllers)
	{
		if (walk == childViewController)
		{
			return lastController;
		}
		lastController = walk;
	}
	return nil;
}

@end
