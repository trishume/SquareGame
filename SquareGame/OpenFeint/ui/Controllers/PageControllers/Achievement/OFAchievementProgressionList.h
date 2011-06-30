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
@class OFImageView;

@interface OFAchievementProgressionList : OFTableCellHelper 
{
	UILabel* titleLabel;
	UILabel* descriptionLabel;
	OFImageView* unlockedIcon;
	UILabel* gamerScoreLabel;
	OFImageView* progressBackground;
	OFImageView* progressBar;
	UIView* progressionBubbleContainer;
	UILabel* progressAmountBubbleLabel;
	UIView* gamerScoreContainer;
	UIImageView* disclosureIcon;
	
	BOOL textNeedsRearrangement;
	
	double percentComplete;
}

@property (nonatomic, retain) IBOutlet UILabel* titleLabel;
@property (nonatomic, retain) IBOutlet UILabel* descriptionLabel;
@property (nonatomic, retain) IBOutlet OFImageView* unlockedIcon;
@property (nonatomic, retain) IBOutlet UILabel* gamerScoreLabel;
@property (nonatomic, retain) IBOutlet OFImageView* progressBackground;
@property (nonatomic, retain) IBOutlet OFImageView* progressBar;
@property (nonatomic, retain) IBOutlet UIView* progressionBubbleContainer;
@property (nonatomic, retain) IBOutlet UILabel* progressAmountBubbleLabel;
@property (nonatomic, retain) IBOutlet UIView* gamerScoreContainer;
@property (nonatomic, retain) IBOutlet UIImageView* disclosureIcon;

- (void)onResourceChanged:(OFResource*)resource;

@end
