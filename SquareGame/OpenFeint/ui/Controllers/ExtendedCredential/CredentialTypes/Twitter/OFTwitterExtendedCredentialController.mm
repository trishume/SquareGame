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

#import "OFTwitterExtendedCredentialController.h"
#import "OFViewDataMap.h"
#import "OFISerializer.h"
#import "OFFormControllerHelper+Overridables.h"
#import "OFFormControllerHelper+Submit.h"
#import "OFControllerLoader.h"
#import "OFActionRequest.h"
#import "OFSocialNotification.h"
#import "OFImageView.h"
#import "OpenFeint+Private.h"
#import "OFRootController.h"
#import "OFNavigationController.h"

@implementation OFTwitterExtendedCredentialController

static NSTimeInterval waitTime = 0.35f;

- (void)awakeFromNib
{
	[super awakeFromNib];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
}

- (void)getExtendedCredentials:(OFDelegate const&)_onSuccess onFailure:(OFDelegate const&)_onFailure onCancel:(OFDelegate const&)_onCancel
{
	onSuccess = _onSuccess;
	onFailure = _onFailure;
	onCancel = _onCancel;
	if([OpenFeint getRootController])
	{
		self.title = @"Settings";
		OFNavigationController* navController = [[[OFNavigationController alloc] initWithRootViewController:self] autorelease];
		[[OpenFeint getRootController] presentModalViewController:navController animated:YES];
	}
}

- (void)whenDismissedSuccessfullyAnimate:(BOOL)animated
{
	
}

- (NSString*)getFormSubmissionUrl 
{
	return @"extended_credentials.xml";
}
																													

- (NSString*)singularResourceName
{
	return @"credential";
}

-(void)populateViewDataMap:(OFViewDataMap*)dataMap
{
	dataMap -> addFieldReference(@"password", 1);
}

-(void)addHiddenParameters:(OFISerializer*)parameterStream
{
	[super addHiddenParameters:parameterStream];
	OFRetainedPtr <NSString> credential_type = @"twitter";
	parameterStream->io("credential_type", credential_type);
}

- (void)dismiss
{
	[[OpenFeint getRootController] dismissModalViewControllerAnimated:YES];
}

- (void)onPresentingErrorDialog
{
	onFailure.invoke();
}

-(void)onFormSubmitted:(id)resources
{
	[self dismiss];

	onSuccess.invoke(NULL, waitTime);
}

- (void)cancel
{
	[self dismiss];
	
	onCancel.invoke(NULL, waitTime);
}

- (void)registerActionsNow
{
}

- (bool)canReceiveCallbacksNow
{
	return true;
}

- (void)dealloc 
{
	[super dealloc];
}

@end
