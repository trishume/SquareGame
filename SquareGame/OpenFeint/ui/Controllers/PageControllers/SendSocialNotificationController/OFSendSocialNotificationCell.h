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
#import "OFSendSocialNotificationController.h"
@class OFImageView;

@interface OFSendSocialNotificationCell : OFTableCellHelper 
{
	UIView* connetedView;
	UIView* notConnetedView;
	
	UILabel* connectToNeworkLabel;
	UIImageView* connectToNetworkImageView;
	
	UILabel* postToNetworkLabel;
	UIImageView* connectedNetworkIconView;
	UIImageView* sendToNetworkCheckBoxView;
	
	BOOL connectedToNetwork;
	BOOL checked;
	
	ESocialNetworkCellType networkType;
}

@property (nonatomic, retain) IBOutlet UIView* connetedView;
@property (nonatomic, retain) IBOutlet UIView* notConnetedView;
@property (nonatomic, retain) IBOutlet UILabel* connectToNeworkLabel;
@property (nonatomic, retain) IBOutlet UIImageView* connectToNetworkImage;
@property (nonatomic, retain) IBOutlet UILabel* postToNetworkLabel;
@property (nonatomic, retain) IBOutlet UIImageView* connectedNetworkIcon;
@property (nonatomic, retain) IBOutlet UIImageView* sendToNetworkCheckBoxView;
@property (nonatomic, assign) BOOL connectedToNetwork;
@property (nonatomic, assign) BOOL checked;
@property (nonatomic, assign) ESocialNetworkCellType networkType;

- (void)onResourceChanged:(OFResource*)resource;

@end
