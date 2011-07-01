//
//  HelloWorldLayer.m
//  SquareGame
//
//  Created by Tristan Hume on 11-06-25.
//  Copyright 15 Norwich Way 2011. All rights reserved.
//


// Import the interfaces
#import "SquaresLayer.h"
#import "MenuScene.h"
#import "OpenFeint.h"
#import "OFHighScoreService.h"

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
        
        size = [[CCDirector sharedDirector] winSize];
        controlMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"controlType"];
        
        CCSprite *gameBG;
        if(controlMode == 1) {
            gameBG = [CCSprite spriteWithFile:@"GameBGSwipe.png"];
        } else {
            gameBG = [CCSprite spriteWithFile:@"GameBGTouch.png"];
        }
        gameBG.position = ccp(size.width/2,size.height/2);
        [self addChild:gameBG];
		
		// create and initialize a Label
		label = [CCLabelAtlas labelAtlasWithString:@"Hello World" charMapFile:@"charmap.png" itemWidth:24 itemHeight:32 startCharMap:' '];
        [label setAnchorPoint: ccp(1, 0.5f)];

		// ask director the the window size
		
	
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
        
        
        if(controlMode == 1) {
            upGesture = [self watchForSwipe:@selector(moveUp) forDir:UISwipeGestureRecognizerDirectionUp];
            downGesture = [self watchForSwipe:@selector(moveDown) forDir:UISwipeGestureRecognizerDirectionDown];
            leftGesture = [self watchForSwipe:@selector(moveLeft) forDir:UISwipeGestureRecognizerDirectionLeft];
            rightGesture = [self watchForSwipe:@selector(moveRight) forDir:UISwipeGestureRecognizerDirectionRight];
        } else {
            self.isTouchEnabled = YES;
        }
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        maxScore = [prefs integerForKey:@"highscore"];
        
        
        
        // died menu
        
        menuLayer = [[CCLayer alloc] init];
        
        CCSprite *menuBG = [CCSprite spriteWithFile:@"DiedMenuBG.png"];
        menuBG.position = ccp(size.width/2,size.height/2);
        [menuLayer addChild:menuBG];
        
        [CCMenuItemFont setFontSize:30];
        CCMenuItem *again = [CCMenuItemFont itemFromString:@"Play Again!" target:self 
                                                  selector:@selector(playAgain)];
        CCMenuItem *main = [CCMenuItemFont itemFromString:@"Menu" target:self 
                                                 selector:@selector(goBack)];
        
        
        // Creating menu and adding items
        CCMenu *menu = [CCMenu menuWithItems:again,main, nil];
        menu.position = ccp(size.width/2 - 7,size.height/2);
        // Set menu alignment to vertical
        [menu alignItemsVertically];
        
        [menuLayer addChild: menu];
        
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
    speed += 1;
}

- (void) movement:(ccTime) dt {
    if(playing) {
        float tf = (CACurrentMediaTime() - lastFrame) * 10;
        square.position = ccp(tf*speed*xDir + square.position.x,tf*speed*yDir + square.position.y);
        
        
        
        NSUInteger score = (CACurrentMediaTime() - sTime) * 50;
        //Canvas edge
        if (square.position.x > size.width - 12 || square.position.x < 0 || square.position.y > size.height - 12 || square.position.y < 0) {        
            [self submitScore:score];
            [self died];
        }
        
        [label setString:[NSString stringWithFormat:@"%d/%d", score,maxScore]];
        lastFrame = CACurrentMediaTime();
    }    
}

- (void) submitScore:(NSUInteger)score {
    if (score > maxScore) {
        maxScore = score;
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setInteger:score forKey:@"highscore"];
    }
    NSString *leaderboard;
    if(controlMode == 1) {
        leaderboard = @"802966";
    } else {
        leaderboard = @"802976";
    }
    [OFHighScoreService setHighScore:score forLeaderboard:leaderboard 
                           onSuccess:OFDelegate() onFailure:OFDelegate()];
}

- (void) died {  
    //[self unschedule:@selector(movement:)];
    playing = NO;
    [self addChild:menuLayer];
}
- (void) playAgain {
    [self removeChild:menuLayer cleanup:NO];
    //[self schedule:@selector(movement:)];
    [self resetSquare];
}
- (void) goBack {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInL transitionWithDuration:0.6 scene:[MenuScene node]]];
}

- (void) resetSquare {
    square.position = ccp(12, size.height - 12);
    xDir = 1; yDir = -1;
    speed = 3;
    sTime = CACurrentMediaTime(); 
    lastFrame = CACurrentMediaTime(); 
    playing = YES;
}

#pragma mark movement
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{    
    if(controlMode == 2 || controlMode == 0) {
        UITouch *touch = [touches anyObject];
        
        CGPoint location = [[CCDirector sharedDirector] convertToGL: 
                            [touch locationInView:touch.view]];
        
        NSUInteger halfx = size.width / 2;
        NSUInteger halfy = size.height / 2;
        if(location.x > halfx && location.y > halfy && xDir != yDir) { // up right
            xDir = 1;
            yDir = 1;
        } else if(location.x < halfx && location.y < halfy && xDir != yDir) { // bottom left
            xDir = -1;
            yDir = -1;
        } else if(location.x > halfx && location.y < halfy && xDir == yDir) { // bottom right
            xDir = 1;
            yDir = -1;
        } else if(location.x < halfx && location.y > halfy && xDir == yDir) { // top left
            xDir = -1;
            yDir = 1;
        }
        //yDir = location.y > halfy ? 1 : -1;
        //NSLog(@"touch!");
    }
}


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
    if(controlMode == 1) {
        [self unwatch:upGesture];
        [self unwatch:downGesture];
        [self unwatch:leftGesture];
        [self unwatch:rightGesture];
    }
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
