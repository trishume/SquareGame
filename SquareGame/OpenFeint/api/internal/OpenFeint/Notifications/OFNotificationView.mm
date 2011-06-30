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
#import "OFNotificationView.h"
#import "OFDelegate.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OFDelegateChained.h"
#import "OpenFeint+Private.h"
#import "OFControllerLoader.h"
#import "OFImageLoader.h"
#import "OFImageView.h"
#import <QuartzCore/QuartzCore.h>

static const float gNotificationWaitSeconds = 2.f; 

@interface OFNotificationView()

- (void)_calcFrameAndTransform;
- (CGPoint)_calcOffScreenPosition:(CGPoint)onScreenPosition;
- (NSString*)_getBackgroundImageName;

@end

@implementation OFNotificationView

@synthesize notice;
@synthesize statusIndicator;
@synthesize backgroundImage;
@synthesize notificationImage;
@synthesize viewToMove;

- (void)animationDidStop:(CABasicAnimation *)theAnimation finished:(BOOL)flag
{
	if (mPresenting)
	{
		mPresenting = NO;
		[self performSelector:@selector(_dismiss) withObject:nil afterDelay:mNotificationDuration];
	}
	else
	{
		[[self layer] removeAnimationForKey:[theAnimation keyPath]];
		[self removeFromSuperview];
	}
}

- (void)_animateKeypath:(NSString*)keyPath 
			  fromValue:(float)startValue 
				toValue:(float)endValue 
			   overTime:(float)duration
	  animationDelegate:(UIView*)animDelegate
	 removeOnCompletion:(BOOL)removeOnCompletion
			   fillMode:(NSString*)fillMode
{
	CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:keyPath];
	animation.fromValue = [NSNumber numberWithFloat:startValue];
	animation.toValue = [NSNumber numberWithFloat:endValue];
	animation.duration = duration;
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	animation.delegate = animDelegate;
	animation.removedOnCompletion = removeOnCompletion;
	animation.fillMode = fillMode;
	[[self layer] addAnimation:animation forKey:keyPath];
}

- (void)_animateFromPosition:(CGPoint)startPos 
				  toPosition:(CGPoint)endPos 
					overTime:(float)duration
		   animationDelegate:(UIView*)animDelegate
		  removeOnCompletion:(BOOL)removeOnCompletion
					fillMode:(NSString*)fillMode

{
	if (startPos.x != endPos.x)
	{
		[self _animateKeypath:@"position.x" 
					fromValue:startPos.x 
					  toValue:endPos.x
					 overTime:duration 
			animationDelegate:animDelegate 
		   removeOnCompletion:removeOnCompletion 
					 fillMode:fillMode];
	}
	if (startPos.y != endPos.y)
	{
		[self _animateKeypath:@"position.y" 
					fromValue:startPos.y
					  toValue:endPos.y 
					 overTime:duration 
			animationDelegate:animDelegate 
		   removeOnCompletion:removeOnCompletion 
					 fillMode:fillMode];
	}
}

- (void)_dismiss
{
	CGPoint onScreenPosition = self.layer.position;
	[self _animateFromPosition:onScreenPosition
					toPosition:[self _calcOffScreenPosition:onScreenPosition]
					  overTime:0.5f
			 animationDelegate:self
			removeOnCompletion:NO
					  fillMode:kCAFillModeForwards];
}

- (void)_presentForDuration:(float)duration
{
	mPresenting = YES;
	mNotificationDuration = duration;
	
	CGPoint onScreenPosition = self.layer.position;
	[self _animateFromPosition:[self _calcOffScreenPosition:onScreenPosition]
					toPosition:onScreenPosition
					  overTime:0.25f
			 animationDelegate:self
			removeOnCompletion:YES
					  fillMode:kCAFillModeRemoved];

	[presentationView addSubview:self];
	
	OFSafeRelease(presentationView);
}

- (void)_makeStatusIconActiveAndDismiss:(OFNotificationStatus*)status
{
	[self _presentForDuration:gNotificationWaitSeconds];

	if (status == nil)
	{
		statusIndicator.hidden = YES;

		if(notificationImage.image == nil)
		{
			//The notification image is also around this same area, don't change the position and size if we have one.
			CGRect noticeFrame = notice.frame;
			noticeFrame.origin.x -= notificationImage.frame.size.width;
			noticeFrame.size.width += notificationImage.frame.size.width;
			notice.frame = noticeFrame;
		}
	}
	else
	{	
		statusIndicator.image = [OFImageLoader loadImage:status];
		statusIndicator.hidden = NO;
	}
}

- (void)_requestSucceeded:(MPOAuthAPIRequestLoader*)request nextCall:(OFDelegateChained*)nextCall
{
	[self _makeStatusIconActiveAndDismiss:OFNotificationStatusSuccess];					
	[nextCall invokeWith:request];
}

- (void)_requestFailed:(MPOAuthAPIRequestLoader*)request nextCall:(OFDelegateChained*)nextCall
{
	[self _makeStatusIconActiveAndDismiss:OFNotificationStatusFailure];
	[nextCall invokeWith:request];
}

+ (NSString*)notificationViewName
{
	return @"NotificationView";
}

+ (void)showNotificationWithText:(NSString*)noticeText andImageNamed:(NSString*)imageName andStatus:(OFNotificationStatus*)status inView:(UIView*)containerView
{
	OFNotificationView* view = (OFNotificationView*)OFControllerLoader::loadView([self notificationViewName]);

	// ensuring thread-safety by firing the notice on the main thread
	SEL selector = @selector(configureWithText:andImageNamed:andStatus:inView:);
	NSMethodSignature* methodSig = [view methodSignatureForSelector:selector];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSig];
	[invocation setTarget:view];
	[invocation setSelector:selector];
	[invocation setArgument:&noticeText atIndex:2];
	[invocation setArgument:&imageName atIndex:3];
	[invocation setArgument:&status atIndex:4];
	[invocation setArgument:&containerView atIndex:5];
	[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:0.f invocation:invocation repeats:NO] forMode:NSDefaultRunLoopMode];
}

+ (void)showNotificationWithRequest:(MPOAuthAPIRequestLoader*)request andNotice:(NSString*)noticeText inView:(UIView*)containerView
{
	OFNotificationView* view = (OFNotificationView*)OFControllerLoader::loadView([self notificationViewName]);

	// ensuring thread-safety by firing the notice on the main thread
	SEL selector = @selector(configureWithRequest:andNotice:inView:);
	NSMethodSignature* methodSig = [view methodSignatureForSelector:selector];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:methodSig];
	[invocation setTarget:view];
	[invocation setSelector:selector];
	[invocation setArgument:&request atIndex:2];
	[invocation setArgument:&noticeText atIndex:3];
	[invocation setArgument:&containerView atIndex:4];
	[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:0.f invocation:invocation repeats:NO] forMode:NSDefaultRunLoopMode];
}

- (BOOL)isParentViewRotatedInternally:(UIView*)parentView
{
	//There are some assumptions here that go against the way notificatoin is written.  This *tries* to figure out if the orientation OpenFeint is initialized with
	//Does not match the actual orientation of the device.  This is true for games that have a internal "portrait" view for the iPhone, but tip the camera in the gl
	//world to make the world look landscape.  In this case OpenFeint is initialized with a landscape view.
	CGRect parentBounds = parentView.bounds;
	BOOL parentIsPortrait = parentBounds.size.width <= ([UIScreen mainScreen].bounds.size.height + [UIScreen mainScreen].bounds.size.width) * 0.5f;
	return UIInterfaceOrientationIsLandscape(([OpenFeint getDashboardOrientation])) && parentIsPortrait;
}

- (CGPoint)_calcOffScreenPosition:(CGPoint)onScreenPosition
{
	CGSize notificationSize = self.bounds.size;
	if (mParentViewIsRotatedInternally)
	{
		UIInterfaceOrientation dashboardOrientation = [OpenFeint getDashboardOrientation];
		float offScreenOffsetX = 0.f;
		float offScreenOffsetY = 0.f;
		
		switch (dashboardOrientation)
		{
			case UIInterfaceOrientationLandscapeRight:		offScreenOffsetX = -notificationSize.height;	break;
			case UIInterfaceOrientationLandscapeLeft:		offScreenOffsetX = notificationSize.height;		break;
			case UIInterfaceOrientationPortraitUpsideDown:	offScreenOffsetY = -notificationSize.height;	break;
			case UIInterfaceOrientationPortrait:			offScreenOffsetY = notificationSize.height;		break;
		}
		
		if ([OpenFeint invertNotifications])
		{
			// We're off the other side, basically.
			offScreenOffsetX *= -1.0f;
			offScreenOffsetY *= -1.0f;
		}
		
		return CGPointMake(onScreenPosition.x + offScreenOffsetX, onScreenPosition.y + offScreenOffsetY);
	}
	else
	{
		if ([OpenFeint invertNotifications] ^ ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown))
		{
			return CGPointMake(onScreenPosition.x, onScreenPosition.y - notificationSize.height);
		}
		else
		{
			return CGPointMake(onScreenPosition.x, onScreenPosition.y + notificationSize.height);
		}

	}
}

- (void)_calcFrameAndTransform
{
	OFAssert(presentationView != nil, "You must have called [self _setPresentationView:] before this!");
	
	CGRect parentBounds = presentationView.bounds;
	const float kNotificationHeight = self.frame.size.height;
	CGRect notificationRect = CGRectZero;
	
	ENotificationPosition notificationPos = [OpenFeint notificationPosition];
	
	// If we are doing inverted notifications, we may need to come in past the UIStatusBar.
	CGSize statusBarOffsetSize = CGSizeZero;
	if (![UIApplication sharedApplication].statusBarHidden) {
		statusBarOffsetSize = [UIApplication sharedApplication].statusBarFrame.size;
	}
	
	static float const kfMaxNotificationWidth = 480.f;
	
	float deltaViewToMoveX = 0.0f;
	float deltaViewToMoveY = 0.0f;
	static const float DELTA_MOVE = 2.0f;
	
	UIInterfaceOrientation dashboardOrientation = [OpenFeint getDashboardOrientation];
	mParentViewIsRotatedInternally = [self isParentViewRotatedInternally:presentationView];
	if (mParentViewIsRotatedInternally) 
	{	
		//If here, the orientation passed into openfeint, and the orientation of the iphone don't match.  This implies that the dev is using some openGL world which
		//the phone still "thinks" is in portrait, but the dev has tipped, or flipped the camera to make the world appear in a different orientation.  In this case
		//we have to move notifications apporiately to the orientation they want openfeint to appear in (because the default cooridinat system will give us incorrect positions).
		
		CGSize notificationSize = CGSizeMake(parentBounds.size.height, kNotificationHeight);
		notificationSize.width = MIN(kfMaxNotificationWidth, notificationSize.width);
        
		notificationRect = CGRectMake(-notificationSize.width * 0.5f,
									  -notificationSize.height * 0.5f, 
									  notificationSize.width, 
									  notificationSize.height
									  );
		
		CGAffineTransform newTransform = CGAffineTransformIdentity;
		
		//Here (unlike the "normal" case) we deal with rotations and center points of the object to position the frame.
		if(![OpenFeint isLargeScreen])
		{	
			//iPhone
			if (notificationPos == ENotificationPosition_TOP)
			{
				switch (dashboardOrientation)
				{
						//Rotate 90 (clockwise?)
					case UIInterfaceOrientationLandscapeRight:
						newTransform = CGAffineTransformMake(0, 1, -1, 0, 
															 parentBounds.size.width - notificationSize.height * 0.5f - statusBarOffsetSize.width,
															 parentBounds.size.height * 0.5f);
						deltaViewToMoveX = -DELTA_MOVE;
						break;
						//Rotate 270
					case UIInterfaceOrientationLandscapeLeft:
						newTransform = CGAffineTransformMake(0, -1, 1, 0, 
															 notificationSize.height * 0.5f + statusBarOffsetSize.width,
															 parentBounds.size.height * 0.5f);
						deltaViewToMoveX = DELTA_MOVE;
						break;
					default:
						break;
				}
			}
			else if(notificationPos == ENotificationPosition_BOTTOM)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
						// Rotate 90
						newTransform = CGAffineTransformMake(0, 1, -1, 0, 
															 notificationSize.height * 0.5f, 
															 parentBounds.size.height * 0.5f);
						deltaViewToMoveX = DELTA_MOVE;
						break;
						//Rotate 270
					case UIInterfaceOrientationLandscapeLeft:
						newTransform = CGAffineTransformMake(0, -1, 1, 0, 
															 parentBounds.size.width - notificationSize.height * 0.5f, 
															 parentBounds.size.height * 0.5f);
						deltaViewToMoveX = -DELTA_MOVE;
						break;
					default:
						break;
				}			
			}
		}
		else
		{
			if(notificationPos == ENotificationPosition_TOP_LEFT)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
					{
						newTransform = CGAffineTransformMake(0, 1, -1, 0, 
															 parentBounds.size.width - (notificationSize.height * 0.5f) - statusBarOffsetSize.width,
															 notificationSize.width * 0.5f);
						deltaViewToMoveX = -DELTA_MOVE;
						
					}
					break;
					
					case UIInterfaceOrientationLandscapeLeft:
					{
						newTransform = CGAffineTransformMake(0, -1, 1, 0, 
															(notificationSize.height * 0.5f) + statusBarOffsetSize.width,
															parentBounds.size.height - (notificationSize.width * 0.5f));
						deltaViewToMoveX = DELTA_MOVE;
					}
					break;
					default:
						break;
				}
			}
			else if(notificationPos == ENotificationPosition_BOTTOM_LEFT)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
					{
						newTransform = CGAffineTransformMake(0, 1, -1, 0, 
															 notificationSize.height * 0.5f,
															 notificationSize.width * 0.5f);
						deltaViewToMoveX = DELTA_MOVE;
					}
					break;
						
					case UIInterfaceOrientationLandscapeLeft:
					{
						newTransform = CGAffineTransformMake(0, -1, 1, 0, 
															 parentBounds.size.width - (notificationSize.height * 0.5f),
															 parentBounds.size.height - (notificationSize.width * 0.5f));
						deltaViewToMoveX = -DELTA_MOVE;
					}
					break;
					
					default:
						break;
				}
			}
			else if(notificationPos == ENotificationPosition_TOP_RIGHT)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
					{
						newTransform = CGAffineTransformMake(0, 1, -1, 0, 
															 parentBounds.size.width - (notificationSize.height * 0.5f) - statusBarOffsetSize.width,
															 parentBounds.size.height - (notificationSize.width * 0.5f));
						deltaViewToMoveX = -DELTA_MOVE;
					}
					break;
						
					case UIInterfaceOrientationLandscapeLeft:
					{
						newTransform = CGAffineTransformMake(0, -1, 1, 0, 
															 notificationSize.height * 0.5f + statusBarOffsetSize.width,
															 notificationSize.width * 0.5f);
						deltaViewToMoveX = DELTA_MOVE;
					}
					break;
						
					default:
					break;
				}
			}
			else if(notificationPos == ENotificationPosition_BOTTOM_RIGHT)
			{
				switch (dashboardOrientation)
				{
					case UIInterfaceOrientationLandscapeRight:
					{
						newTransform = CGAffineTransformMake(0, 1, -1, 0, 
															 notificationSize.height * 0.5f,
															 parentBounds.size.height - (notificationSize.width * 0.5f));
						deltaViewToMoveX = DELTA_MOVE;
					}
					break;
						
					case UIInterfaceOrientationLandscapeLeft:
					{
						newTransform = CGAffineTransformMake(0, -1, 1, 0, 
															 parentBounds.size.width - (notificationSize.height * 0.5f),
															 notificationSize.width * 0.5f);
						deltaViewToMoveX = -DELTA_MOVE;
					}
					break;
					
					default:
					break;
				}
			}
		}

		
		self.frame = notificationRect;
		[self setTransform:newTransform];
	}
	else
	{
		//Here we deal with building the frame in the upper left corner of the frame.  Since we only have a case that rotates the object 180 degrees (when upsidedown)
		//this is the easiest method for "normal" cases.
		CGSize notificationSize = CGSizeMake(parentBounds.size.width, kNotificationHeight);
		notificationSize.width = MIN(kfMaxNotificationWidth, notificationSize.width);
		
		CGFloat frameX, frameY;
		frameX = frameY = 0.0f;
		
		if(![OpenFeint isLargeScreen])
		{
			//iPhone
			//If we're Portrait upside down, we have to switch which side you think it would pop up on rotate it around 180 (after this if else).
			BOOL topNotUpsideDown = ((ENotificationPosition_TOP == notificationPos) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomNotUpsideDown = ((ENotificationPosition_BOTTOM == notificationPos) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topUpsideDown = ((ENotificationPosition_TOP == notificationPos) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomUpsideDown = ((ENotificationPosition_BOTTOM == notificationPos) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			
			if (topNotUpsideDown || bottomUpsideDown)
			{
				//Come in from the top and center the notification
				frameX = (parentBounds.size.width - notificationSize.width) * 0.5f;
				frameY = 0.0f;
				
				if(topNotUpsideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY += statusBarOffsetSize.height;
				}
				
				deltaViewToMoveY = -DELTA_MOVE;
			}
			else if(bottomNotUpsideDown || topUpsideDown) //This must be the case if we hit the else, unless the dev put in something invalid for orientation on the iphone.
			{
				//Come in from the bottom and center the notification.
				frameX = (parentBounds.size.width - notificationSize.width) * 0.5f;
				frameY = parentBounds.size.height - notificationSize.height;
				
				if(topUpsideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY -= statusBarOffsetSize.height;
				}
				
				deltaViewToMoveY = DELTA_MOVE;
			}
		}
		else
		{
			//iPad
			//Come in on the corner specified by the dev.  Note taht if our dashboard orientation is interface orientation portrait upsidedown
			//Then the notification will come in from its "opposite" side since the ui coor system doesn't flip 180 with the device (for some reason).
			//Therefore when upside down, we pop in the notification from its "opposite notification position" and then flip it 180 degrees about itself (after this if/else).
			BOOL bottomLeftNotUpsideDown =	((ENotificationPosition_BOTTOM_LEFT == notificationPos) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomRightNotUpsideDown =	((ENotificationPosition_BOTTOM_RIGHT == notificationPos) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topLeftNotUpsideDown =		((ENotificationPosition_TOP_LEFT == notificationPos) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topRightNotUpsideDown =	((ENotificationPosition_TOP_RIGHT == notificationPos) && !([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topRightUpSideDown =		((ENotificationPosition_TOP_RIGHT == notificationPos) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL topLeftUpSideDown =		((ENotificationPosition_TOP_LEFT == notificationPos) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomRightUpSideDown =	((ENotificationPosition_BOTTOM_RIGHT == notificationPos) && ([OpenFeint getDashboardOrientation] == UIInterfaceOrientationPortraitUpsideDown));
			BOOL bottomLeftUpSideDown =		((ENotificationPosition_BOTTOM_LEFT == notificationPos) && ([OpenFeint getDashboardOrientation]  == UIInterfaceOrientationPortraitUpsideDown));
			
			if(bottomLeftNotUpsideDown || topRightUpSideDown)
			{
				frameX = 0.0f;
				frameY = parentBounds.size.height - notificationSize.height;
				
				if(topRightUpSideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY -= statusBarOffsetSize.height;
				}
				deltaViewToMoveY = DELTA_MOVE;
			}
			else if(bottomRightNotUpsideDown || topLeftUpSideDown)
			{
				frameX = parentBounds.size.width - notificationSize.width;
				frameY = parentBounds.size.height - notificationSize.height;
				
				if(topLeftUpSideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY -= statusBarOffsetSize.height;
				}
				deltaViewToMoveY = DELTA_MOVE;
			}
			else if(topLeftNotUpsideDown || bottomRightUpSideDown)
					
			{
				frameX = 0.0f;
				frameY = 0.0f;
				
				if(topLeftNotUpsideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY += statusBarOffsetSize.height;
				}
				deltaViewToMoveY = -DELTA_MOVE;
			}
			else if(topRightNotUpsideDown || bottomLeftUpSideDown)
					
			{
				frameX = parentBounds.size.width - notificationSize.width;
				frameY = 0.0f;
				
				if(topRightNotUpsideDown)
				{
					//respect the status bar, and make sure to rotate it 180 degrees since we're upsidedown
					frameY = statusBarOffsetSize.height;
				}
				deltaViewToMoveY = -DELTA_MOVE;
			}
		}
		
		//Make the rect.
		notificationRect = CGRectMake(frameX, frameY, notificationSize.width, notificationSize.height);

		//If the dashboard is upside down, the corridinate system still things its right side up, so
		//the notification will appear upside down unless we flip it.
		if([OpenFeint getDashboardOrientation]  == UIInterfaceOrientationPortraitUpsideDown)
		{
			self.transform = CGAffineTransformRotate(self.transform, M_PI);
		}
        
		self.frame = notificationRect;			
	}
	
	viewToMove.frame = CGRectMake(viewToMove.frame.origin.x + deltaViewToMoveX, viewToMove.frame.origin.y + deltaViewToMoveY, viewToMove.frame.size.width, viewToMove.frame.size.height);
}

- (NSString*)_getBackgroundImageName
{
	ENotificationPosition notificationPos = [OpenFeint notificationPosition];
	if([OpenFeint isLargeScreen])
	{
		switch (notificationPos)
		{
			case ENotificationPosition_BOTTOM_LEFT:		return @"OFNotificationBackgroundIPadBottomLeft.png";
			case ENotificationPosition_TOP_LEFT:		return @"OFNotificationBackgroundIPadTopLeft.png";
			case ENotificationPosition_BOTTOM_RIGHT:	return @"OFNotificationBackgroundIPadBottomRight.png";
			case ENotificationPosition_TOP_RIGHT:		return @"OFNotificationBackgroundIPadTopRight.png";
			default:									return @"OFNotificationBackgroundIPadBottomLeft.png"; //This should never happen unless the dev put in something invalid.
		}
	}
	else
	{
		switch (notificationPos)
		{
			case ENotificationPosition_BOTTOM_LEFT:
			case ENotificationPosition_BOTTOM_RIGHT:	return @"OFNotificationBackgroundIPhoneBottom.png";
			case ENotificationPosition_TOP_LEFT:
			case ENotificationPosition_TOP_RIGHT:		return @"OFNotificationBackgroundIPhoneTop.png";
			default:									return @"OFNotificationBackgroundIPhoneBottom.png"; //This should never happen unless the dev put in something invalid
		}
	}
}

- (void)_setPresentationView:(UIView*)_presentationView
{
	OFSafeRelease(presentationView);
	presentationView = [_presentationView retain];	
	[self _calcFrameAndTransform];
}

- (void)_buildViewWithText:(NSString*)noticeText
{
	statusIndicator.hidden = YES;
	notice.text = noticeText;
	[backgroundImage setContentMode:UIViewContentModeScaleToFill];
    
    CGFloat capFromRight = 50.f;
	[backgroundImage setImage:[backgroundImage.image stretchableImageWithLeftCapWidth:(backgroundImage.image.size.width - capFromRight) topCapHeight:0]];
}

- (void)setupDefaultImages
{
	NSString* backgroundImageName = [self _getBackgroundImageName];
	UIImage* backgroundDefaultImage = [OFImageLoader loadImage:backgroundImageName];
	[backgroundImage setDefaultImage:backgroundDefaultImage];
	
	backgroundImage.unframed = YES;
	backgroundImage.useSharpCorners = YES;
	statusIndicator.unframed = YES;
	
}

- (void)configureWithText:(NSString*)noticeText andImageNamed:(NSString*)imageName andStatus:(OFNotificationStatus*)status inView:(UIView*)containerView
{
	[self setupDefaultImages];
	
	
	if(imageName && ![imageName isEqualToString:@""])
	{
		[notificationImage setDefaultImage:[OFImageLoader loadImage:imageName]];
		notificationImage.unframed = YES;
		notificationImage.useSharpCorners = YES;
		notificationImage.shouldScaleImageToFillRect = NO;
	}
	
	[self _setPresentationView:containerView];
	[self _buildViewWithText:noticeText];
	[self _makeStatusIconActiveAndDismiss:status];
}

- (void)configureWithRequest:(MPOAuthAPIRequestLoader*)request andNotice:(NSString*)noticeText inView:(UIView*)containerView
{
	[self setupDefaultImages];
	
	[self _setPresentationView:containerView];
	[self _buildViewWithText:noticeText];
	
	[request setOnSuccess:OFDelegate(self, @selector(_requestSucceeded:nextCall:), [request getOnSuccess])]; 
	[request setOnFailure:OFDelegate(self, @selector(_requestFailed:nextCall:), [request getOnFailure])]; 		
	[request loadSynchronously:NO];
}

- (bool)canReceiveCallbacksNow
{
	return true;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView* hitView = [super hitTest:point withEvent:event];
	return hitView;
}

- (void)dealloc 
{
	self.statusIndicator = nil;
	self.backgroundImage = nil;
	self.notice = nil;
	OFSafeRelease(presentationView);
    [super dealloc];
}

@end
