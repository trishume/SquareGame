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

#import "OFFacebookExtendedCredentialController.h"
#import "FBConnect.h"
#import "OFSettings.h"
#import "OFFormControllerHelper+Overridables.h"
#import "OFFormControllerHelper+Submit.h"
#import "OFISerializer.h"
#import "OFNavigationController.h"
#import "OFFacebookAccountController.h"
#import "OFControllerLoader.h"
#import "OFActionRequest.h"
#import "OFSocialNotification.h"
#import "OFImageView.h"
#import "OFImageLoader.h"
#import "OpenFeint+Private.h"
#import "OFRootController.h"
#import "OFSendSocialNotificationController.h"

@implementation OFFacebookExtendedCredentialController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}



- (void)dialogDidCancel:(FBDialog*)dialog
{
	[super closeLoginDialog];
	

	onCancel.invoke();

}

- (void)onFormSubmitted:(id)resources
{
	onSuccess.invoke();
}


- (void)displayError:(NSString*)errorString
{
	[[[[UIAlertView alloc] 
	   initWithTitle:OFLOCALSTRING(@"Facebook Connect Error")
	   message:errorString
	   delegate:nil
	   cancelButtonTitle:OFLOCALSTRING(@"Ok")
	   otherButtonTitles:nil] autorelease] show];

	onFailure.invoke();

}

- (NSString*)singularResourceName
{
	return @"credential";
}

-(void)populateViewDataMap:(OFViewDataMap*)dataMap
{
}

- (bool)canReceiveCallbacksNow
{
	return YES;
}

- (void)getExtendedCredentials:(OFDelegate const&)_onSuccess onFailure:(OFDelegate const&)_onFailure onCancel:(OFDelegate const&)_onCancel;
{
	onSuccess = _onSuccess;
	onFailure = _onFailure;
	onCancel = _onCancel;
	skipLoginOnAppear = YES;
	self.getPostingPermission = YES;
	[super promptToLogin];
}

- (void)registerActionsNow
{
}

- (void)dealloc 
{
	[super dealloc];
}

@end
