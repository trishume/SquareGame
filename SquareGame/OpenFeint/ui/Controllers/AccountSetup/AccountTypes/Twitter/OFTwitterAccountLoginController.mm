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
#import "OFTwitterAccountLoginController.h"
#import "OFViewDataMap.h"
#import "OFISerializer.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OFProvider.h"
#import "OFShowMessageAndReturnController.h"
#import "OFControllerLoader.h"
#import "OFIntroNavigationController.h"

@implementation OFTwitterAccountLoginController

@synthesize submitButton, contentView, integrationInfoLabel, controllerToPopTo;

- (void)setupForConnectTwitter
{
	self.addingAdditionalCredential = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	if (!self.addingAdditionalCredential)
	{
		if(![OpenFeint isInLandscapeMode])
		{
			CGRect objectRect = self.privacyDisclosure.frame;
			self.privacyDisclosure.frame = objectRect;
			
			objectRect = self.submitButton.frame;
			objectRect.origin.y = self.privacyDisclosure.frame.origin.y + self.privacyDisclosure.frame.size.height - 5.f;
			self.submitButton.frame = objectRect;
		}
		
		integrationInfoLabel.text = OFLOCALSTRING(@"Enter the Twitter credentials you used to secure your OpenFeint account.");
	}
	else
	{
		integrationInfoLabel.text = OFLOCALSTRING(@"Connect Twitter to find friends with OpenFeint and import your profile picture.");
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OFNSNotificationFullscreenFrameOn" object:nil];
    
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OFNSNotificationFullscreenFrameOff" object:nil];
}

- (bool)shouldUseOAuth
{
	return self.addingAdditionalCredential;
}

- (void)populateViewDataMap:(OFViewDataMap*)dataMap
{
	dataMap->addFieldReference(@"username",	1);
	dataMap->addFieldReference(@"password", 2);
}

- (void)addHiddenParameters:(OFISerializer*)parameterStream
{
	[super addHiddenParameters:parameterStream];
	
	OFRetainedPtr <NSString> credentialsType = @"twitter"; 
	parameterStream->io("credential_type", credentialsType);
	
	if (self.addingAdditionalCredential)
	{
		//The user now must send every message manually, there is no more need for this.
		parameterStream->io("enable_stream_integration", @"true");
	}
}

- (void)registerActionsNow
{
}

- (NSString*)singularResourceName
{
	return @"credential";
}

- (NSString*)getFormSubmissionUrl
{
	return self.addingAdditionalCredential ? @"users_credentials.xml" : @"session.xml";
}

- (NSString*)getLoadingScreenText
{
	return self.addingAdditionalCredential ? OFLOCALSTRING(@"Connecting To Twitter") : OFLOCALSTRING(@"Logging In To OpenFeint");
}

- (OFShowMessageAndReturnController*)controllerToPushOnCompletion
{
	// Can assume that twitter authorization was successful.
	[OpenFeint setLoggedInUserHasTwitterCredential:YES];  // Update the local option flag to reflect success.  [Joe]
	 
	if (self.addingAdditionalCredential)
	{
		OFShowMessageAndReturnController* nextController =  (OFShowMessageAndReturnController*)OFControllerLoader::load(@"ShowMessageAndReturn");
		nextController.messageTitleLabel.text = OFLOCALSTRING(@"Connected to Twitter");
		nextController.messageLabel.text = OFLOCALSTRING(@"Your OpenFeint and Twitter accounts are now connected! Everyone you're following who has an OpenFeint account will be added to your My Friends list.");
		nextController.title = OFLOCALSTRING(@"Finding Friends");
		return nextController;
	}
	else
	{
		return [self getStandardLoggedInController];
	}	
}

- (UIViewController*)getControllerToPopTo
{
	return self.controllerToPopTo ? self.controllerToPopTo : [super getControllerToPopTo];
}

- (void)dealloc
{
	self.submitButton = nil;
	self.contentView = nil;
	self.integrationInfoLabel = nil;
	self.controllerToPopTo = nil;
	[super dealloc];
}

@end
