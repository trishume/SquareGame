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

#import "OFGameCenterIntegrationController.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+Settings.h"

@implementation OFGameCenterIntegrationController

@synthesize nowPlayingLabel;

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSString* name = [OpenFeint applicationDisplayName];
	
	self.nowPlayingLabel.text = @"";
	if(name && ![name isEqualToString:@""])
	{
		self.nowPlayingLabel.text = [NSString stringWithFormat:@"Now Playing %@", name];
	}
	
	self.navigationItem.hidesBackButton = YES;
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

#pragma mark IBActions

- (IBAction) onContinue {
    [OpenFeint startLocationManagerIfAllowed];
    [OpenFeint allowErrorScreens:YES];
    [OpenFeint dismissRootControllerOrItsModal];
}

#pragma mark Boilerplate

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self != nil)
	{
	}
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

@end

