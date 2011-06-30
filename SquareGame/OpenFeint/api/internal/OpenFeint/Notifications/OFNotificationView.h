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

#import "OFCallbackable.h"
#import "OFNotificationStatus.h"

@class MPOAuthAPIRequestLoader;
@class OFImageView;

@interface OFNotificationView : UIView<OFCallbackable>
{
@package
	UILabel* notice;
	OFImageView* statusIndicator;
	OFImageView* backgroundImage;
	OFImageView* notificationImage;
	
	BOOL mParentViewIsRotatedInternally;
	BOOL mPresenting;
	float mNotificationDuration;

	UIView* presentationView;
	UIView* viewToMove; //
}

+ (void)showNotificationWithText:(NSString*)noticeText andImageNamed:(NSString*)imageName andStatus:(OFNotificationStatus*)status inView:(UIView*)containerView;
+ (void)showNotificationWithRequest:(MPOAuthAPIRequestLoader*)request andNotice:(NSString*)noticeText inView:(UIView*)containerView;


- (void)configureWithRequest:(MPOAuthAPIRequestLoader*)request andNotice:(NSString*)noticeText inView:(UIView*)containerView;
- (void)configureWithText:(NSString*)noticeText andImageNamed:(NSString*)imageName andStatus:(OFNotificationStatus*)status inView:(UIView*)containerView;



- (bool)canReceiveCallbacksNow;

@property (nonatomic, retain) IBOutlet UILabel* notice;
@property (nonatomic, retain) IBOutlet OFImageView* statusIndicator;
@property (nonatomic, retain) IBOutlet OFImageView* backgroundImage;
@property (nonatomic, retain) IBOutlet OFImageView* notificationImage;
@property (nonatomic, retain) IBOutlet UIView* viewToMove;

- (void)_setPresentationView:(UIView*)_presentationView;
- (void)_presentForDuration:(float)duration;
- (void)setupDefaultImages;

@end
