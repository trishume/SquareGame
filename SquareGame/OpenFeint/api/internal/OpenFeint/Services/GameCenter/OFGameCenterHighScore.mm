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

#import "OFGameCenterHighScore.h"
#import "OpenFeint+GameCenter.h"
#import "OFNotification.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFHighScoreService+Private.h"
#import "OFPaginatedSeries.h"

namespace { 
    NSUInteger STATUS_UNUSED = 0;
    NSUInteger STATUS_PENDING = 1;
    NSUInteger STATUS_SUCCESS = 2;
    NSUInteger STATUS_ERROR = 3;
}



@interface OFGameCenterHighScore ()

-(void) openFeintSuccess:(OFPaginatedSeries*)resources; 
-(void) openFeintFailure;
-(void)testCompletion:(OFPaginatedSeries*)resources;
-(void)testCompletion;

@end



@implementation OFGameCenterHighScore
@synthesize silently;
@synthesize message;

-(id)initWithSeries:(OFHighScoreBatchEntrySeries&) _scores {
    if((self = [super init])) {
        scores = _scores;
    }
    return self;
}

-(void)dealloc {
    [super dealloc];
}

-(OFRequestHandle*)submitOnSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure onUploadBlob:(const OFDelegate&)onUploadBlobDelegate {
    successDelegate = onSuccess;
    failureDelegate = onFailure;
	uploadBlobDelegate = onUploadBlobDelegate;
    OFRequestHandle* handle = nil;

    
    if(scores.size() == 0) {
        onSuccess.invoke();
		if (!self.silently && self.message)
		{
			OFNotificationData* notice = [OFNotificationData dataWithText:self.message andCategory:kNotificationCategoryHighScore andType:kNotificationTypeSuccess];
			[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
		}
        return nil;
    }
    
    
    openFeintStatus = STATUS_UNUSED;
    gameCenterStatus = STATUS_UNUSED;
    gameCenterCount = 0;

    NSMutableDictionary* datesPerScore = [NSMutableDictionary dictionaryWithCapacity:scores.size()];
    
#ifdef __IPHONE_4_1    
    if([OpenFeint isLoggedIntoGameCenter]) {
        //send each of them to the GameCenter processor, maybe they'll set a date
        OFHighScoreBatchEntrySeries::iterator it = scores.begin();
        while(it != scores.end())
        {
            OFHighScoreBatchEntry* entry = *it;
            NSString*categoryId = [OpenFeint getGameCenterLeaderboardCategory:entry->leaderboardId];
            if(categoryId) {
                ++gameCenterCount;
                gameCenterStatus = STATUS_PENDING;
#ifdef _DEBUG
				//#ifdef to avoid warnings.
                NSString* idCopy = entry->leaderboardId;
#endif
                NSDate* date = [OpenFeint submitScoreToGameCenter:entry->score category:categoryId withHandler:^(NSError* error) {
                    --gameCenterCount;
                    if(error) {
                        OFLog(@"Failed to submit leaderboard %@ to GameCenter. Error %@", idCopy, error);
                        gameCenterStatus = STATUS_ERROR;
                    }
                    else {
                        if(!gameCenterCount && gameCenterStatus == STATUS_PENDING)
                            gameCenterStatus = STATUS_SUCCESS;
						OFLog(@"Leaderboard successful");
                    }
                    [self testCompletion];
                }]; 
                if(date) [datesPerScore setObject:date forKey:entry->leaderboardId];
            }
            ++it;
        }
    }
#endif    
    openFeintStatus = STATUS_PENDING;
    OFDelegate success(self, @selector(openFeintSuccess:));
    OFDelegate failure(self, @selector(openFeintFailure));
    handle = [OFHighScoreService submitHighScoreBatch:scores withGameCenterDates:datesPerScore
                                       message:self.message ? self.message : @"Submitted High Scores" silently:self.silently
                                     onSuccess:success onFailure:failure];    
    
    return handle;
}
-(void) openFeintSuccess:(OFPaginatedSeries*)resources
{
    if(openFeintStatus == STATUS_PENDING) openFeintStatus = STATUS_SUCCESS;
    else NSAssert(0, @"High score state is invalid");
	uploadBlobDelegate.invoke(resources);
    [self testCompletion:resources];
}

-(void) openFeintFailure {
    if(openFeintStatus == STATUS_PENDING) openFeintStatus = STATUS_ERROR;
    else NSAssert(0, @"High score state is invalid");
    [self testCompletion];
}

-(void) testCompletion 
{
	[self testCompletion:nil];
}

-(void) testCompletion:(OFPaginatedSeries*)resources;
{
	//if(openFeintStatus == STATUS_SUCCESS && resources)
	//{
	//	uploadBlobDelegate.invoke(resources);
//		uploadBlobDelegate = OFDelegate(); //Clear it out, only upload once.
//	}
	
    if(openFeintStatus == STATUS_PENDING ||gameCenterStatus == STATUS_PENDING) return;  //still in progress
    if(openFeintStatus != STATUS_ERROR && gameCenterStatus != STATUS_ERROR) 
	{
        successDelegate.invoke(resources);
    }
    else {
        failureDelegate.invoke();
    }
}

-(bool) canReceiveCallbacksNow {
    return YES;
}
@end
