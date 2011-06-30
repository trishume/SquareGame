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

#import "OFImageLoader.h"
#import "OFDeviceContact.h"
#import "OFImageView.h"
#import "OFContactCell.h"

@implementation OFContactCell

@synthesize profilePictureView, nameLabel, numberOrEmail, phoneOrEmailIcon;

- (BOOL)hasConstantHeight
{
	return YES;
}

- (void)onResourceChanged:(OFResource*)resource
{
	OFDeviceContact* contact = (OFDeviceContact*)resource;
	
	nameLabel.text = contact.name;
	if(contact.number)
	{
		numberOrEmail.text = contact.number;
		[phoneOrEmailIcon setImage:[OFImageLoader loadImage:@"OFSelectInviteContactPhoneSmall.png"]];
	}
	else if(contact.email)
	{
		numberOrEmail.text = contact.email;
		[phoneOrEmailIcon setImage:[OFImageLoader loadImage:@"OFSelectInviteContactMailSmall.png"]];
	}
	
	if(contact.imageData)
	{
		[profilePictureView setDefaultImage:[[[UIImage alloc] initWithData:contact.imageData] autorelease]];
	}
	else
	{
		[profilePictureView useOtherPlayerProfilePictureDefault];
	}
}

- (void)dealloc
{
	OFSafeRelease(profilePictureView);
	OFSafeRelease(nameLabel);
	OFSafeRelease(numberOrEmail);
	OFSafeRelease(phoneOrEmailIcon);
	[super dealloc];
}

@end
