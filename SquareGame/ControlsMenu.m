//
//  ControlsMenu.m
//  SquareGame
//
//  Created by Tristan Hume on 11-06-28.
//  Copyright 2011 15 Norwich Way. All rights reserved.
//
#import "ControlsMenu.h"
#import "MenuScene.h"

@implementation ControlsMenu

+(id) scene
{
    CCScene *scene = [CCScene node];
    
    ControlsMenu *layer = [ControlsMenu node];
    
    [scene addChild: layer];
    
    return scene;
}

-(id) init
{
    
    if( (self=[super init] )) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        CCSprite *menuBG = [CCSprite spriteWithFile:@"MenuBG.png"];
        menuBG.position = ccp(size.width/2,size.height/2);
        [self addChild:menuBG];
        
        CCLayer *menuLayer = [[CCLayer alloc] init];
        [self addChild:menuLayer];
        [CCMenuItemFont setFontSize:40];
        CCMenuItem *swipe = [CCMenuItemFont itemFromString:@"Swipe Controls" target:self selector:@selector(swipeMode)];
        CCMenuItem *touch = [CCMenuItemFont itemFromString:@"Touch Controls" target:self selector:@selector(touchMode)];
        CCMenuItem *score = [CCMenuItemFont itemFromString:@"Reset High Score" target:self selector:@selector(resetScore)];
        CCMenuItem *back = [CCMenuItemFont itemFromString:@"BACK" target:self selector:@selector(goBack)];
        
        
        // Creating menu and adding items
        CCMenu *menu = [CCMenu menuWithItems:touch,swipe,score,back, nil];
        menu.position = ccp(size.width/2 - 7,size.height/2 - 20);
        // Set menu alignment to vertical
        [menu alignItemsVertically];
        
        [menuLayer addChild: menu];        
    }
    return self;
}
- (void) swipeMode {
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"controlType"];
    [self goBack];
}
- (void) touchMode {
    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"controlType"];
    [self goBack];
}
- (void) resetScore {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"highscore"];
    [self goBack];
}
- (void) goBack {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInL transitionWithDuration:0.6 scene:[MenuScene node]]];
}

- (void) dealloc
{
    
    [super dealloc];
}
@end