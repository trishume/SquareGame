//
//  MenuScene.m
//  SquareGame
//
//  Created by Tristan Hume on 11-06-26.
//  Copyright 2011 15 Norwich Way. All rights reserved.
//

#import "MenuScene.h"
#import "SquaresLayer.h"
#import "GameCenterManager.h"

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
        CCSprite *menuBG = [CCSprite spriteWithFile:@"MenuBG.png" 
                                     rect:CGRectMake(0, 0, 480, 320)];
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
        
        
        // Creating menu and adding items
        CCMenu *menu = [CCMenu menuWithItems:start, nil];
        menu.position = ccp(size.width/2 - 7,size.height/2);
        // Set menu alignment to vertical
        [menu alignItemsVertically];
        
        [menuLayer addChild: menu];
        
        
    }
    return self;
}

- (void) authenticateLocalPlayer
{
    [GameCenterManager authenticateLocalUser];
}

- (void) startGame: (id) sender
{
    //[[CCDirector sharedDirector] replaceScene:[SquaresLayer scene]];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionSplitRows transitionWithDuration:0.6 scene:[SquaresLayer node]]];
}

- (void) dealloc
{
    
    [super dealloc];
}
@end