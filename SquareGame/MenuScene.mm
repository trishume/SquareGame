//
//  MenuScene.m
//  SquareGame
//
//  Created by Tristan Hume on 11-06-26.
//  Copyright 2011 15 Norwich Way. All rights reserved.
//

#import "MenuScene.h"
#import "SquaresLayer.h"
//#import "GameCenterManager.h"
#import "ControlsMenu.h"
#import "OpenFeint.h"

@implementation MenuScene

+(id) scene
{
    CCScene *scene = [CCScene node];
    
    MenuScene *layer = [MenuScene node];
    
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
        
        /*CCMenuItemImage *startButton = [CCMenuItemImage
                                        itemFromNormalImage:@"startButton.png"
                                        selectedImage:@"startButtonSelected.png"
                                        target:self
                                        selector:@selector(startGame:)];
        CCMenu *menu = [CCMenu menuWithItems: startButton, nil];*/
        [CCMenuItemFont setFontSize:90];
        CCMenuItem *start = [CCMenuItemFont itemFromString:@"PLAY" target:self selector:@selector(startGame:)];
        [CCMenuItemFont setFontSize:45];
        CCMenuItem *controls = [CCMenuItemFont itemFromString:@"OPTIONS" target:self selector:@selector(chooseControls)];
        CCMenuItem *of = [CCMenuItemFont itemFromString:@"OpenFeint" target:self selector:@selector(openOpenFeint)];
        
        
        // Creating menu and adding items
        CCMenu *menu = [CCMenu menuWithItems:start,controls,of, nil];
        menu.position = ccp(size.width/2 - 7,size.height/2 - 40);
        // Set menu alignment to vertical
        [menu alignItemsVertically];
        
        [menuLayer addChild: menu];
        
        
    }
    return self;
}

- (void) openOpenFeint {
    [OpenFeint launchDashboard];
}

- (void) startGame: (id) sender
{
    //[[CCDirector sharedDirector] replaceScene:[SquaresLayer scene]];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSplitRows transitionWithDuration:0.6 scene:[SquaresLayer node]]];
}
- (void) chooseControls {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInR transitionWithDuration:0.6 scene:[ControlsMenu node]]];
}

- (void) dealloc
{
    
    [super dealloc];
}
@end