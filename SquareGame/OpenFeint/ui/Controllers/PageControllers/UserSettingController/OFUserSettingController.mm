//  Copyright 2009-2010 Aurora Feint, Inc.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  	http://www.apache.org/licenses/LICENSE-2.0
//  	
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "OFDependencies.h"
#import "OFUserSettingController.h"
#import "OFResourceControllerMap.h"
#import "OFUserSetting.h"
#import "OFUserSettingService.h"
#import "OpenFeint.h"
#import "OFUserSettingPushController.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFAccountSetupBaseController.h"
#import "OFFacebookAccountLoginController.h"
#import "OFTwitterAccountLoginController.h"
#import "OFHttpCredentialsCreateController.h"
#import "OFOpenFeintAccountLoginController.h"
#import "OpenFeint+NSNotification.h"
#import "OFTableSectionDescription.h"
#import "OFUserSetting.h"
#import "OFSession.h"

@implementation OFUserSettingController

- (bool)usePlainTableSectionHeaders
{
	return true;
}

- (void)populateResourceMap:(OFResourceControllerMap*)resourceMap
{
	resourceMap->addResource([OFUserSetting class], @"UserSetting");
	resourceMap->addResource([OFUserSettingPushController class], @"UserSettingAction");
	
}

- (OFService*)getService
{
	return [OFUserSettingService sharedInstance];
}

- (bool)shouldAlwaysRefreshWhenShown
{
	return true;
}

- (NSString*)getNoDataFoundMessage
{
	return OFLOCALSTRING(@"There are no settings available right now");
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFUserSettingPushController class]])
	{
		OFUserSettingPushController* pushControllerResource = (OFUserSettingPushController*)cellResource;
		UIViewController* controllerToPush = [pushControllerResource getController];
		if ([controllerToPush isKindOfClass:[OFFacebookAccountLoginController class]] ||
			[controllerToPush isKindOfClass:[OFTwitterAccountLoginController class]] ||
		    [controllerToPush isKindOfClass:[OFHttpCredentialsCreateController class]])
		{
			[(OFAccountSetupBaseController*)controllerToPush setAddingAdditionalCredential:YES];
		}
        if ([controllerToPush isKindOfClass:[OFOpenFeintAccountLoginController class]]) {
            [(OFOpenFeintAccountLoginController*)controllerToPush setHideIntroFlowSpacer:YES];
        }
		if (controllerToPush)
		{
			[self.navigationController pushViewController:controllerToPush animated:YES];
		}
	}
}

- (void)_logoutNow
{
	[[OpenFeint session] logoutUser];
	[OpenFeint dismissDashboard];
}

-(void)removeSettingNamed:(NSString*)name fromTableSectionDescription:(OFTableSectionDescription*)tableSecDes
{
	for(uint j = 0; j < tableSecDes.page.objects.count; j++)
	{
		OFUserSetting* setting = (OFUserSetting*)[tableSecDes.page.objects objectAtIndex:j];
		if([setting.name isEqualToString:name])
		{
			[tableSecDes.page.objects removeObjectAtIndex:j];
			[tableSecDes.expandedViews removeObjectAtIndex:j];
		}
	}
}

-(void)_onDataLoaded:(OFPaginatedSeries*)resources isIncremental:(BOOL)isIncremental
{
	//Sometimes people make you write code that paves your entrance to hell...
	//We are manually stripping the switches for twitterstream integratoin and facebook posting integration out here since it is too much of a pain to rip them out of the server
	for(uint i = 0; i < resources.objects.count; i++)
	{
		OFTableSectionDescription* tableSecDes = (OFTableSectionDescription*)[resources.objects objectAtIndex:i];
		if([tableSecDes.title isEqualToString:@"Twitter Permissions"])
		{
			[self removeSettingNamed:@"Stream Integration" fromTableSectionDescription:tableSecDes];
		}
		else if([tableSecDes.title isEqualToString:@"Facebook Permissions"])
		{
			[self removeSettingNamed:@"News Feed Integration" fromTableSectionDescription:tableSecDes];
		}
	}
	
	[super _onDataLoaded:resources isIncremental:isIncremental];
}

- (IBAction)logout
{
	OFSafeRelease(logoutSheet);
	
	NSString* message = OFLOCALSTRING(@"Logging out will disable all Feint features.  Are you sure?");
	logoutSheet = [[UIActionSheet alloc] initWithTitle:message delegate:self cancelButtonTitle:OFLOCALSTRING(@"Cancel") destructiveButtonTitle:OFLOCALSTRING(@"Logout") otherButtonTitles:nil];
	[logoutSheet showInView:[OpenFeint getTopLevelView]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.destructiveButtonIndex)
	{
		[self _logoutNow];
	}
	actionSheet.delegate = nil;
	
	if (actionSheet == logoutSheet)
	{
		OFSafeRelease(logoutSheet);
	}
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] 
		addObserver:self 
		selector:@selector(orientationDidChange:) 
		name:OFNSNotificationDashboardOrientationChanged 
		object:nil];

	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] 
		removeObserver:self
		name:OFNSNotificationDashboardOrientationChanged
		object:nil];

	[super viewWillDisappear:animated];
}
	
- (void)orientationDidChange:(NSNotification*)notification
{
	[logoutSheet dismissWithClickedButtonIndex:[logoutSheet cancelButtonIndex] animated:NO];
}

@end
