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

#import "OFSendSocialNotificationSubmitTextCell.h"
#import "OFSocialNotificationService.h"
#import "OFImageLoader.h"
#import "OFGameProfilePageInfo.h"
#import "OpenFeint+UserOptions.h"
#import "OFPaginatedSeries.h"
#import "OFImageUrl.h"
#import "OFImageView.h"
#import "OpenFeint+UserOptions.h"
#import "OFGameProfilePageInfo.h"
#import "OFSendSocialNotificationController.h"

@interface OFSendSocialNotificationSubmitTextCell (Private)
- (void)_getSocialNotificationImageSuccess:(OFPaginatedSeries*)resources;
- (void)_getSocialNotificationImageFailure;
@end

@implementation OFSendSocialNotificationSubmitTextCell

@synthesize gameIcon, prePopulatedText, message, maxMessageCharacters, sendSocialNotificationController;

-(void)awakeFromNib
{
	[super awakeFromNib];
	maxMessageCharacters = 20;
	
	message.delegate = self;
	message.returnKeyType = UIReturnKeySend;
}

-(void)setIconUrl:(NSString*)url;
{
	[gameIcon setImageUrl:url];
}

-(void)setDefaultImageName:(NSString*)name
{
	[gameIcon setDefaultImage:[OFImageLoader loadImage:name]];
}

-(void)setSocialNotificationImageName:(NSString*)name
{
	[OFSocialNotificationService getImageUrlForNotificationImageNamed:name 
															onSuccess:OFDelegate(self, @selector(_getSocialNotificationImageSuccess:))
															onFailure:OFDelegate(self, @selector(_getSocialNotificationImageFailure))];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	return (range.location + range.length < maxMessageCharacters || [string isEqualToString:@""]);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if(sendSocialNotificationController)
	{
		[sendSocialNotificationController send];
	}
	
	//Make the keyboard disappear when "return" is pressed.
	[textField resignFirstResponder];
	return NO;
}

- (void)_getSocialNotificationImageSuccess:(OFPaginatedSeries*)resources
{
	if([resources.objects count] > 0)
	{
		OFImageUrl* imageUrl = [resources.objects objectAtIndex:0];
		if(![imageUrl.url isEqualToString:@""] && imageUrl.url != nil)
		{
			[self setIconUrl:imageUrl.url];
			return;
		}
	}
	
	[self _getSocialNotificationImageFailure];
}

- (void)_getSocialNotificationImageFailure
{
	OFLog(@"Image requested to put in social notification does not exist.  Defaulting to game image");
	[self setIconUrl:[OpenFeint localGameProfileInfo].iconUrl];
}

- (bool)canReceiveCallbacksNow
{
	return true;
}

- (void)dealloc
{
	self.sendSocialNotificationController = nil;
	[super dealloc];
}

@end
