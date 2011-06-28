//
//  HelloWorldLayer.m
//  SquareGame
//
//  Created by Tristan Hume on 11-06-25.
//  Copyright 15 Norwich Way 2011. All rights reserved.
//


// Import the interfaces
#import "SquaresLayer.h"

// HelloWorldLayer implementation
@implementation SquaresLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	SquaresLayer *layer = [SquaresLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

/*-(void) drawSquareAtPoint: (CGPoint) {
    [self drawRectForPoints: ccp(center.x - s, center.y - s) andPoint: ccp(center.x + s, center.y + s)];
}*/

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// create and initialize a Label
		label = [CCLabelAtlas labelAtlasWithString:@"Hello World" charMapFile:@"charmap.png" itemWidth:24 itemHeight:32 startCharMap:' '];
        [label setAnchorPoint: ccp(1, 0.5f)];

		// ask director the the window size
		size = [[CCDirector sharedDirector] winSize];
	
		// position the label on the center of the screen
		label.position =  ccp( size.width - 5 , 25 );
		
		// add the label as a child to this Layer
		[self addChild: label];
        
        //schedule frame method
        [self schedule:@selector(movement:)];
        [self schedule:@selector(faster) interval:1];
        
        square = [CCSprite spriteWithFile:@"Square_Red.png" 
                                               rect:CGRectMake(0, 0, 25, 25)];
        [self addChild:square];
        [self resetSquare];
        
        upGesture = [self watchForSwipe:@selector(moveUp) forDir:UISwipeGestureRecognizerDirectionUp];
        downGesture = [self watchForSwipe:@selector(moveDown) forDir:UISwipeGestureRecognizerDirectionDown];
        leftGesture = [self watchForSwipe:@selector(moveLeft) forDir:UISwipeGestureRecognizerDirectionLeft];
        rightGesture = [self watchForSwipe:@selector(moveRight) forDir:UISwipeGestureRecognizerDirectionRight];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        maxScore = [prefs integerForKey:@"highscore"];
        
        
        
	}
	return self;
}

- (UISwipeGestureRecognizer *)watchForSwipe:(SEL)selector forDir:(UISwipeGestureRecognizerDirection)direction {
    UISwipeGestureRecognizer *recognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:selector] autorelease];
    recognizer.direction = direction;
    [[[CCDirector sharedDirector] openGLView] addGestureRecognizer:recognizer];
    return recognizer;
}

- (void)unwatch:(UIGestureRecognizer *)gr {
    [[[CCDirector sharedDirector] openGLView] removeGestureRecognizer:gr];
}

- (void) faster {
    speed += 2;
}

- (void) movement:(ccTime) dt {
    float tf = (CACurrentMediaTime() - lastFrame) * 10;
    square.position = ccp(tf*speed*xDir + square.position.x,tf*speed*yDir + square.position.y);
    
    
    
    NSUInteger score = (CACurrentMediaTime() - sTime) * 50;
    //Canvas edge
    if (square.position.x > size.width - 12 || square.position.x < 0 || square.position.y > size.height - 12 || square.position.y < 0) {
        [self resetSquare];
        if (score > maxScore) {
            maxScore = score;
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setInteger:score forKey:@"highscore"];
        }
    }
    
    [label setString:[NSString stringWithFormat:@"%d/%d", score,maxScore]];
    lastFrame = CACurrentMediaTime();
    
}

- (void) resetSquare {
    square.position = ccp(12, size.height - 12);
    xDir = 1; yDir = -1;
    speed = 1;
    sTime = CACurrentMediaTime(); 
    lastFrame = CACurrentMediaTime(); 
}

#pragma mark movement

-(void)moveUp {
    yDir = 1;
}
-(void)moveDown {
    yDir = -1;
}
-(void)moveLeft {
    xDir = -1;
}
-(void)moveRight {
    xDir = 1;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
    [self unwatch:upGesture];
    [self unwatch:downGesture];
    [self unwatch:leftGesture];
    [self unwatch:rightGesture];
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
