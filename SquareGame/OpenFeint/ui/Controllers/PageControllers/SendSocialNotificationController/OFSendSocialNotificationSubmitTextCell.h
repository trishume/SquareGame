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

#import "OFTableCellHelper.h"
#import "OFCallbackable.h"
@class OFImageView;
@class OFSendSocialNotificationController;

static const uint SocialNotification_MAX_TOTAL_CHARACTERS = 140;
static const uint SocialNotification_MAX_LINK_CHARACTERS = 20;
static const uint SocialNotification_MAX_PREPOPULATED_CHARACTERS = 100;

@interface OFSendSocialNotificationSubmitTextCell : OFTableCellHelper<UITextFieldDelegate, OFCallbackable>
{
	OFImageView* gameIcon;
	UILabel* prePopulatedText;
	UITextField* message;
	uint maxMessageCharacters;
	OFSendSocialNotificationController* sendSocialNotificationController;
}

@property(nonatomic,retain) IBOutlet OFImageView* gameIcon;
@property(nonatomic,retain) IBOutlet UILabel* prePopulatedText;
@property(nonatomic,retain) IBOutlet UITextField* message;
@property(nonatomic,retain) OFSendSocialNotificationController* sendSocialNotificationController;
@property(nonatomic,assign) uint maxMessageCharacters;

-(void)setIconUrl:(NSString*)url;
-(void)setDefaultImageName:(NSString*)name;
-(void)setSocialNotificationImageName:(NSString*)name;
-(void)setMaxMessageCharacters:(uint)max;

@end
