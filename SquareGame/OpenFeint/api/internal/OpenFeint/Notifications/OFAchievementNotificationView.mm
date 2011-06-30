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

#import "OFDependencies.h"
#import "OFAchievementNotificationView.h"
#import "OFControllerLoader.h"
#import "OFAchievement.h"
#import "OFImageView.h"
#import "OFImageLoader.h"
#import "OpenFeint+Private.h"

@implementation OFAchievementNotificationView

@synthesize achievementValueText;

+ (NSString*)notificationViewName
{
	return @"AchievementNotificationView";
}

+ (void)showAchievementNotice:(OFUnlockedAchievementNotificationData*)notificationData inView:(UIView*)containerView
{
	OFAchievementNotificationView* view = (OFAchievementNotificationView*)OFControllerLoader::loadView([self notificationViewName]);

	// ensuring thread-safety by firing the notice on the main thread
	SEL selector = @selector(configureWithNotificationData:inView:);
	NSMethodSignature* methodSig = [view methodSignatureForSelector:selector];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSig];
	[invocation setTarget:view];
	[invocation setSelector:selector];
	[invocation setArgument:&notificationData atIndex:2];
	[invocation setArgument:&containerView atIndex:3];
	[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:0.f invocation:invocation repeats:NO] forMode:NSDefaultRunLoopMode];
}

- (void)_iconFinishedDownloading
{
	[self _presentForDuration:4.f];
	[notificationImage setImageDownloadFinishedDelegate:OFDelegate()];
}

- (void)configureWithNotificationData:(OFUnlockedAchievementNotificationData*)notificationData 
							   inView:(UIView*)containerView 
{	
	[self _setPresentationView:containerView];

	notice.text = notificationData.notificationText;
	
	[self setupDefaultImages];
	
	[notificationImage setDefaultImage:[OFImageLoader loadImage:@"OFUnlockedAchievementIcon.png"]];
	notificationImage.unframed = YES;
	

	OFDelegate showAndDismissDelegate(self, @selector(_iconFinishedDownloading));

	if (notificationData.unlockedAchievement)
	{
		achievement = [notificationData.unlockedAchievement retain];
		notice.text = [NSString stringWithFormat:@"'%@'", achievement.title];
		UIImage* statusDefaultImage = nil;
		
		NSString* statusIndicatorImage;
		if(notificationData.percentComplete == 100.0)
		{
			achievementValueText.text = [NSString stringWithFormat:@"%d", achievement.gamerscore];
			statusIndicatorImage = @"OFFeintPointsWhite.png";
			statusDefaultImage = [OFImageLoader loadImage:statusIndicatorImage];
		}
		else if(notificationData.percentComplete >= 0.0)
		{
			achievementValueText.text = [NSString stringWithFormat:@"%d%%", (int)(notificationData.percentComplete)];
			statusIndicatorImage = @"OFeintPercentLockWhite.png";
			statusDefaultImage = [OFImageLoader loadImage:statusIndicatorImage];
		}
		else
		{
			achievementValueText.hidden = YES;
			statusDefaultImage = nil;
		}
		
		[statusIndicator setDefaultImage:statusDefaultImage];
		statusIndicator.unframed = YES;


		UIImage* localImage = [OFImageLoader loadImage:[NSString stringWithFormat:@"AchievementIcon_%@.jpg", notificationData.unlockedAchievement.resourceId]];
		if (localImage)
		{
			[notificationImage setDefaultImage:localImage];
			showAndDismissDelegate.invoke();
		}
        else if (!achievement.iconUrl || [achievement.iconUrl isEqualToString:@""])
        {
            showAndDismissDelegate.invoke();
        }
		else
		{
            [notificationImage setImageDownloadFinishedDelegate:showAndDismissDelegate];
			notificationImage.imageUrl = achievement.iconUrl;
		}
	}
	else
	{
		statusIndicator.hidden = YES;
		achievementValueText.hidden = YES;

		achievement = nil;
		showAndDismissDelegate.invoke();
	}
}

- (void)dealloc 
{
	OFSafeRelease(achievement);
	OFSafeRelease(achievementValueText);
    [super dealloc];
}

@end
