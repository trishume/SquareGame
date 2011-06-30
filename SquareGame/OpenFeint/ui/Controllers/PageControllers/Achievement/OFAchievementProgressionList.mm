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

#import "OFAchievementProgressionList.h"
#import "OFAchievement.h"
#import "OFImageView.h"
#import "OFImageLoader.h"


@implementation OFAchievementProgressionList

@synthesize titleLabel, descriptionLabel, unlockedIcon, gamerScoreLabel, progressBackground, progressBar, progressionBubbleContainer, progressAmountBubbleLabel, gamerScoreContainer, disclosureIcon;

- (void)layoutSubviews
{	
	[super layoutSubviews];
	
	//All this has to be done AFTER the resize of the views.  During _onResourceChanged, the views are not yet resized.
	static const float Left_Right_Text_Padding = 15.0f;
	static const float maxDescHeight = 27.0f;
	static const float maxTitleHeight = 19.0f;
	
	float textWidth = (gamerScoreContainer.frame.origin.x - Left_Right_Text_Padding) - (unlockedIcon.frame.origin.x + unlockedIcon.frame.size.width + Left_Right_Text_Padding);

	CGSize descriptionLabelSize = [descriptionLabel.text sizeWithFont:descriptionLabel.font constrainedToSize:CGSizeMake(textWidth, maxDescHeight)];
	descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabelSize.width, descriptionLabelSize.height);
	
	CGSize titleLabelSize = [titleLabel.text sizeWithFont:titleLabel.font constrainedToSize:CGSizeMake(textWidth, maxTitleHeight)];
	titleLabel.frame = CGRectMake(titleLabel.frame.origin.x, titleLabel.frame.origin.y, titleLabelSize.width, titleLabelSize.height);
	
	if(textNeedsRearrangement)
	{
		CGRect titleLabelFrame = titleLabel.frame;
		titleLabelFrame.origin.y = unlockedIcon.frame.origin.y;
		titleLabel.frame = titleLabelFrame;
		
		CGRect descriptionLabelFrame = descriptionLabel.frame;
		descriptionLabelFrame.origin.y = titleLabel.frame.origin.y + titleLabel.frame.size.height;
		descriptionLabel.frame = descriptionLabelFrame;
	}
	
	if(progressBar.hidden == NO)
	{
		CGRect barFrame = progressBackground.frame;
		barFrame.size.width *= (percentComplete/100.0f);
		progressBar.frame = barFrame;
	}
	
	
	if(progressionBubbleContainer.hidden == NO)
	{
		CGRect bubbleFrame = CGRectMake((progressBar.frame.origin.x + progressBar.frame.size.width) - (progressionBubbleContainer.frame.size.width * 0.5f),
										progressBar.frame.origin.y + (progressBar.frame.size.height * 0.5f) - (progressionBubbleContainer.frame.size.height),
										progressionBubbleContainer.frame.size.width,
										progressionBubbleContainer.frame.size.height);
		
		progressionBubbleContainer.frame = bubbleFrame;
	}

	gamerScoreContainer.hidden = self.userInteractionEnabled;
	disclosureIcon.hidden = !self.userInteractionEnabled;
}

- (void)onResourceChanged:(OFResource*)resource
{
	OFAchievement* achievement = (OFAchievement*)resource;
	
	if (achievement.isUnlocked)
	{
		[unlockedIcon setDefaultImage:[OFImageLoader loadImage:@"OFUnlockedAchievementIcon.png"]];
		unlockedIcon.imageUrl = achievement.iconUrl;
	}
	else
	{
		[unlockedIcon setImage:[OFImageLoader loadImage:@"OFLockedAchievementIcon.png"]];
	}
	
	if (achievement.isSecret && achievement.percentComplete == 0.0f)
	{
		titleLabel.text = OFLOCALSTRING(@"Secret");
		descriptionLabel.text = OFLOCALSTRING(@"You must unlock this achievement to view its description.");
	}
	else
	{
		titleLabel.text = achievement.title;
		descriptionLabel.text = achievement.description;
	}
	
	descriptionLabel.frame = CGRectMake(65.0f, 50.0f, 200.0f, 27.0f);
	titleLabel.frame = CGRectMake(65.0f, 5.0f, 200.0f, 19.0f);
	
	gamerScoreLabel.text = [NSString stringWithFormat:@"%d", achievement.gamerscore];
	
	if(achievement.percentComplete < 1.0 || achievement.percentComplete == 100.0)
	{
		progressBackground.hidden = YES;
		progressBar.hidden = YES;
		progressionBubbleContainer.hidden = YES;
		
		textNeedsRearrangement = YES;
	}
	else
	{
		textNeedsRearrangement = NO;
		progressBackground.hidden = NO;
		progressBar.hidden = NO;
		progressionBubbleContainer.hidden = NO;
	
		UIImage* backgroundProgressImage = [OFImageLoader loadImage:@"OFAchievementProgressBackground.png"];
		[progressBackground setDefaultImage:[backgroundProgressImage stretchableImageWithLeftCapWidth:10 topCapHeight:0]];
		[progressBackground setContentMode:UIViewContentModeScaleToFill];
		progressBackground.unframed = YES;
		progressBackground.useSharpCorners = YES;
		
		UIImage* barImage = [OFImageLoader loadImage:@"OFAchievementProgressBar.png"];
		[progressBar setDefaultImage:[barImage stretchableImageWithLeftCapWidth:10 topCapHeight:0]];
		[progressBar setContentMode:UIViewContentModeScaleToFill];
		progressBar.unframed = YES;
		progressBar.useSharpCorners = YES;
		
		progressAmountBubbleLabel.text  = [NSString stringWithFormat:@"%d%%", (int)achievement.percentComplete];
		
		percentComplete = achievement.percentComplete;
	}
}

@end
