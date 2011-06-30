//
//  HelloWorldLayer.h
//  SquareGame
//
//  Created by Tristan Hume on 11-06-25.
//  Copyright 15 Norwich Way 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldLayer
@interface SquaresLayer : CCLayer
{
    CCSprite *square;
    CGSize size;
    CCLabelAtlas *label;
    
    NSInteger speed;
    NSInteger xDir;
    NSInteger yDir;
    
    UIGestureRecognizer *upGesture;
    UIGestureRecognizer *downGesture;
    UIGestureRecognizer *rightGesture;
    UIGestureRecognizer *leftGesture;
    
    double sTime;
    NSUInteger maxScore;
    double lastFrame;
    
    CCLayer *menuLayer;
    
    BOOL playing;
    
    NSUInteger controlMode;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;
//-(void) drawSquareAtPoint: (CGPoint) center ofSize:(NSUInteger)s;
- (void) resetSquare;

- (UISwipeGestureRecognizer *)watchForSwipe:(SEL)selector forDir:(UISwipeGestureRecognizerDirection)direction;
- (void)unwatch:(UIGestureRecognizer *)gr;
- (void) died;
- (void) submitScore:(NSUInteger)score;

@end
