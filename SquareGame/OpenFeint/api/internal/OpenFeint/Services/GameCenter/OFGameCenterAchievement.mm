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

#import "OFGameCenterAchievement.h"
#import "OFAchievementService+Private.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+GameCenter.h"

namespace { 
    NSUInteger STATUS_UNUSED = 0;
    NSUInteger STATUS_PENDING = 1;
    NSUInteger STATUS_SUCCESS = 2;
    NSUInteger STATUS_ERROR = 3;
}


@interface OFGameCenterAchievement ()
@property (nonatomic) OFDelegate successDelegate;
@property (nonatomic) OFDelegate failureDelegate;
@end

@implementation OFGameCenterAchievement
@synthesize achievementIds;
@synthesize openFeintPage;
@synthesize batch;
@synthesize sync;
@synthesize successDelegate;
@synthesize failureDelegate;
@synthesize percentsComplete;

-(void) dealloc {
    self.achievementIds = nil;
    self.openFeintPage = nil;
	self.percentsComplete = nil;
    [super dealloc];
}


-(void)testCompletion {
    //check if the states are done, if so maybe execute completion and then do the delegates
    if(openFeintStatus == STATUS_PENDING || gameCenterStatus == STATUS_PENDING) return;   //still things to be done
    
	if(openFeintStatus == STATUS_SUCCESS) 
	{
        [OFAchievementService finishAchievementsPage:self.openFeintPage duringSync:sync fromBatch:batch];
    }
   
	if(openFeintStatus != STATUS_ERROR && gameCenterStatus != STATUS_ERROR) 
	{
        //update offline sync dates...
        //if we have OpenFeint, then we can use syncOffline, if not...
        if(openFeintStatus == STATUS_SUCCESS)
		{
            [OFAchievementService syncOfflineAchievements:self.openFeintPage];
		}
        else 
		{
            NSString* score = @"";  //where is this seen, anyway?
            NSDate* date = [NSDate date];
            NSString* user = [OpenFeint lastLoggedInUserId];
            for(uint i = 0; i < [achievementIds count] && i < [percentsComplete count]; i++)
            {
				NSString* achievementId = [achievementIds objectAtIndex:i];
				NSNumber* percentComplete = [percentsComplete objectAtIndex:i];
				
                NSString* gcAchievementId = [OpenFeint getGameCenterAchievementId:achievementId];
                if(gcAchievementId) 
				{
                    [OFAchievementService synchUnlockedAchievement:achievementId
                                                           forUser:user
                                                        gamerScore:score
                                                        serverDate:date
												   percentComplete:[percentComplete doubleValue]];
                }
            }
        }
        successDelegate.invoke(self.openFeintPage);
    }
    else 
	{
        failureDelegate.invoke(self.openFeintPage);
    }
}

-(void) onOpenFeintSuccess:(OFPaginatedSeries*) page {
    self.openFeintPage = page;
   
	if(openFeintStatus == STATUS_PENDING)
	{
        openFeintStatus = STATUS_SUCCESS;
	}
    else 
	{
        NSAssert(0, @"Achievement state is invalid");
	}
    
	[self testCompletion];
}


-(void) onOpenFeintFailure:(OFPaginatedSeries*) page {
    self.openFeintPage = page;
    
	if(openFeintStatus == STATUS_PENDING)
	{
        openFeintStatus = STATUS_ERROR;
	}
    else
	{
        NSAssert(0, @"Achievement state is invalid");
	}
	
    [self testCompletion];
}


-(OFRequestHandle*)submitOnSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure {
	[self setSuccessDelegate: onSuccess];
	[self setFailureDelegate: onFailure];
    OFRequestHandle* handle = nil;
    
    NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
    openFeintStatus = STATUS_UNUSED;
    gameCenterStatus = STATUS_UNUSED;
        
    if ([lastLoggedInUser longLongValue] > 0) 
	{
		if(achievementIds.count)
		{
            OFDelegate onSuccess(self, @selector(onOpenFeintSuccess:));
            OFDelegate onFailure(self, @selector(onOpenFeintFailure:));
			handle = [OFAchievementService updateAchievements:achievementIds withPercentCompletes:percentsComplete onSuccess:onSuccess onFailure:onFailure];
            
            openFeintStatus = STATUS_PENDING;
        }
    }

#ifdef __IPHONE_4_1
    if([OpenFeint isLoggedIntoGameCenter]) 
	{
        //send to GameCenter
        gameCenterCount = 0;
		for(uint i = 0; i < [achievementIds count] && i < [percentsComplete count]; i++)
        {
			NSString* achievementId = [achievementIds objectAtIndex:i];
			double percentComplete = [(NSNumber*)[percentsComplete objectAtIndex:i] doubleValue];
			
            NSString* gcAchievementId = [OpenFeint getGameCenterAchievementId:achievementId];
            if(gcAchievementId && percentComplete != 0.0) 
			{
                ++gameCenterCount;
                gameCenterStatus = STATUS_PENDING;
                [OpenFeint submitAchievementToGameCenter:gcAchievementId withPercentComplete:percentComplete withHandler:^(NSError* error) 
				{
                    --gameCenterCount;
                    if(error) 
					{
                        OFLog(@"Failed to submit %@ to GameCenter.  Error %@", gcAchievementId, error);
                        gameCenterStatus = STATUS_ERROR;
                    }
                    else 
					{
                        if(!gameCenterCount && gameCenterStatus == STATUS_PENDING) 
                            gameCenterStatus = STATUS_SUCCESS;
                    }
                    [self testCompletion];
                }];
            }
        }
    }
#endif
    return handle;
}

-(bool)canReceiveCallbacksNow 
{
    return YES;
}

@end









@implementation OFSubmitAchievementToGameCenterOnly

- (void) submitToGameCenterOnlyWithIds:(NSArray*)achievementIds andPercentCompletes:(NSArray*)percentCompletes onSuccess:(OFDelegate const &)onSuccess onFailure:(OFDelegate const &)onFailure
{
#ifdef __IPHONE_4_1        
	if(achievementIds.count != percentCompletes.count)
	{
		//Something bad happend...
		return;
	}
	
	{
		encounteredAnError = NO;
		for(uint i = 0; i < achievementIds.count; i++)
		{
			NSString* achievementId = [achievementIds objectAtIndex:i];
			double percentComplete = [(NSNumber*)[percentCompletes objectAtIndex:i] doubleValue];
			
			//I'm copying off this information for the block.  When I seemed to copy off onSuccess and onFailure directly (as OFDelegates) the copies got deleted when the block was hit with the callback, not sure why...
			//Probably has something to do with the being c++ objects...
			NSObject<OFCallbackable> * successTarget = onSuccess.getTarget();
			SEL successSel = onSuccess.getSelector();
			NSObject<OFCallbackable> * failureTarget = onFailure.getTarget();
			SEL failureSel = onFailure.getSelector();
			
			NSString* gcAchievementId = [OpenFeint getGameCenterAchievementId:achievementId];
			if(gcAchievementId) 
			{
				achievementStillToRecieveCallbackCount++;
				[OpenFeint submitAchievementToGameCenter:gcAchievementId withPercentComplete:percentComplete withHandler:^(NSError* error)
				 {
					 achievementStillToRecieveCallbackCount--;
					 if(error)
					 {
						 OFLog(@"Failed to submit %@ to GameCenter.  Error %@", gcAchievementId, error);
						 encounteredAnError = YES;
					 }
					 
					 if(achievementStillToRecieveCallbackCount == 0)
					 {
						 if(encounteredAnError)
						 {
							 if(!sentFailure && failureTarget != nil && failureSel != nil)
							 {
								 OFDelegate fail(failureTarget, failureSel);
								 fail.invoke();
								 sentFailure = YES;
							 }
						 }
						 else if(successTarget != nil && successSel != nil)
						 {
							 OFDelegate success(successTarget, successSel);
							 success.invoke();
						 }
					 }
				 }];
			}
			else
			{
				//at least 1 was not in the list, send failure delegate here too.  Need it b/c if there is only invalid items in the list, we'll never try to submit to GC
				encounteredAnError = YES;
				if(!sentFailure)
				{
					onFailure.invoke();
					sentFailure = YES;
				}
			}
		}
	}
#endif
}


@end
