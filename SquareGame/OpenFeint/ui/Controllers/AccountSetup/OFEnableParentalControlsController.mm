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

#import "OFEnableParentalControlsController.h"
#import "OpenFeint+UserOptions.h"
#import "OFResourceRequest.h"
#import "OFParentalControls.h"
#import "OFDevice.h"
#import "OpenFeint+Private.h"
#import "OFSession.h"


@implementation OFEnableParentalControlsController

@synthesize password, passwordConfirmation;

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

}

-(BOOL)usesXP
{
	return YES;
}

- (OFResourceRequest*)getResourceRequest
{
	NSString* call = [NSString stringWithFormat:@"/xp/devices/%@/parental_control", [UIDevice currentDevice].uniqueIdentifier];
	NSDictionary* params = [NSDictionary dictionaryWithObject:
															[NSDictionary dictionaryWithObjectsAndKeys:
																password.text, @"password",
																passwordConfirmation.text, @"password_confirmation",
																nil]
													   forKey:@"parental_control"];
	OFResourceRequest* request = [OFResourceRequest postRequestWithPath:call
																andBody:params];
	request.requiresUserSession = NO;
	return request; 
}

- (void)onBeforeFormSubmitted
{

}

- (void)onAfterFormSubmitted
{
	
}

- (void)onFormSubmitted:(id)resources
{
	if([resources isKindOfClass:[OFParentalControls class]])
	{
		[OpenFeint session].currentDevice.parentalControls = resources;
	}
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc
{
	self.password = nil;
	self.passwordConfirmation = nil;
	[super dealloc];
}

@end
