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

#import "OFConversationMessageBoxController.h"
#import "OFForumPost.h"
#import "OFISerializer.h"
#import "OFFormControllerHelper+Submit.h"
#import "OpenFeint+Private.h"

@interface OFConversationMessageBoxController ()
@property (nonatomic, retain) NSString* initialText;
@end

@implementation OFConversationMessageBoxController

@synthesize messageField, conversationId, initialText;

#pragma mark Boilerplate

- (void)dealloc
{
	self.messageField = nil;
	self.conversationId = nil;
	self.initialText = nil;
	OFSafeRelease(sendButton);
	OFSafeRelease(backgroundView);
	[super dealloc];
}

#pragma mark UIViewController Methods

- (void)awakeFromNib
{
	[super awakeFromNib];

    if ([OpenFeint isLargeScreen])
    {
        self.view.frame = CGRectMake(0.0f, 0.0f,[OpenFeint getDashboardBounds].size.width, 43.0f);
    }
    else
    {
        self.view.backgroundColor = [UIColor colorWithRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1.0];
        CGRect frame = messageField.frame;
        frame.size.height = 22.f;
        messageField.frame = frame;
    }
	
	backgroundBoarderView.image = [backgroundBoarderView.image stretchableImageWithLeftCapWidth:(backgroundBoarderView.image.size.width/2) 
																	 topCapHeight:(backgroundBoarderView.image.size.height/2) ];
	
	messageField.maxLines = 5;
	messageField.minLines = 1;
}

- (void)viewWillAppear:(BOOL)animated
{
	if (animated)
	{
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25f];
	}

	messageField.alpha = 1.f;
	sendButton.alpha = 1.f;
	backgroundView.alpha = 1.f;
	
	if (animated)
	{
		[UIView commitAnimations];
	}
	
    [messageField performSelector:@selector(setText:) withObject:self.initialText afterDelay:0.5f];
    
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (animated)
	{
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25f];
	}

	messageField.alpha = 0.f;
	sendButton.alpha = 0.f;
	backgroundView.alpha = 0.f;
	
	if (animated)
	{
		[UIView commitAnimations];
	}
	
	[super viewWillDisappear:animated];
}

#pragma mark OFFormControllerHelper

- (bool)shouldShowLoadingScreenWhileSubmitting
{
	return false;
}

- (NSString*)getLoadingScreenText
{
	return nil;
}

- (void)registerActionsNow
{
}

- (void)addHiddenParameters:(OFISerializer*)parameterStream
{
	parameterStream->io("post[body]", messageField.text);
}

- (void)populateViewDataMap:(OFViewDataMap*)dataMap
{
}

- (NSString*)getFormSubmissionUrl
{
	return [NSString stringWithFormat:@"discussions/%@/posts.xml", conversationId];
}

- (IBAction)onSubmitForm:(UIView*)sender
{
	if ([messageField.text length] > 0)
	{
		[super onSubmitForm:sender];
	}
	else
	{
		[messageField resignFirstResponder];
	}
}

- (void)onBeforeFormSubmitted
{
	messageField.text = @"";
	[messageField resignFirstResponder];
}

- (void)onFormSubmitted:(id)resources
{
}

- (NSString*)singularResourceName
{
	return [OFForumPost getResourceName];
}

- (bool)canReceiveCallbacksNow
{
	return true;
}

- (bool)shouldDismissKeyboardWhenSubmitting
{
	return false;
}

@end
