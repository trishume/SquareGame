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
#import "OFHighScoreService.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFService+Private.h"
#import "OFHighScore.h"
#import "OFAbridgedHighScore.h"
#import "OFLeaderboard.h"
#import "OFNotificationData.h"
#import "OFHighScoreService+Private.h"
#import "OFDelegateChained.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Private.h"
#import "OFReachability.h"
#import "OFUser.h"
#import "OFNotification.h"
#import "OFS3Response.h"
#import "OFS3UploadParameters.h"
#import "OFCloudStorageService.h"
#import "OFGameCenterHighScore.h"
#import "OFPaginatedSeries.h"
#import "OpenFeint+GameCenter.h"

#define kMaxHighScoreBlobSize (1024*50)

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFHighScoreService);

@interface OFSubmitHighScoreToGameCenterOnly : NSObject
{

}

- (void) submitToGameCenterOnlyWithScores:(OFHighScoreBatchEntrySeries&)entries;

@end

@implementation OFSubmitHighScoreToGameCenterOnly

- (void) submitToGameCenterOnlyWithScores:(OFHighScoreBatchEntrySeries&)entries
{	
#ifdef __IPHONE_4_1        
	for(OFHighScoreBatchEntrySeries::iterator it = entries.begin(); it != entries.end(); it++) 
	{
		OFHighScoreBatchEntry* entry = *it;
		
		NSString* categoryId = [OpenFeint getGameCenterLeaderboardCategory:entry->leaderboardId];
		if(categoryId) 
		{
#ifdef _DEBUG
			//#ifdef to avoid warnings.
			NSString* idCopy = entry->leaderboardId;
#endif
			[OpenFeint submitScoreToGameCenter:entry->score category:categoryId withHandler:^(NSError* error)
			 {
				 if(error)
				 {
					 OFLog(@"Failed to submit leaderboard %@ to GameCenter. Error %@", idCopy, error);
				 }
			
			 }];
		}
	}
#endif
}
@end


@interface OFHighScoreService ()
+ (OFRequestHandle*)submitHighScoreBatch:(OFHighScoreBatchEntrySeries&)highScoreBatchEntrySeries silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage;
@end

@implementation OFHighScoreService

OPENFEINT_DEFINE_SERVICE(OFHighScoreService);

- (void) populateKnownResources:(OFResourceNameMap*)namedResources
{
	namedResources->addResource([OFHighScore getResourceName], [OFHighScore class]);
	namedResources->addResource([OFAbridgedHighScore getResourceName], [OFAbridgedHighScore class]);
	namedResources->addResource([OFS3UploadParameters getResourceName], [OFS3UploadParameters class]);
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	return [OFHighScoreService getPage:pageIndex forLeaderboard:leaderboardId friendsOnly:friendsOnly silently:NO onSuccess:onSuccess onFailure:onFailure];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	return [OFHighScoreService getPage:pageIndex
				 forLeaderboard:leaderboardId
			   comparedToUserId:nil
					friendsOnly:friendsOnly
					   silently:silently
					  onSuccess:onSuccess
					  onFailure:onFailure];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex 
  forLeaderboard:(NSString*)leaderboardId 
comparedToUserId:(NSString*)comparedToUserId 
	 friendsOnly:(BOOL)friendsOnly
		silently:(BOOL)silently
	   onSuccess:(const OFDelegate&)onSuccess 
	   onFailure:(const OFDelegate&)onFailure
{
	return [OFHighScoreService 
		getPage:pageIndex 
		pageSize:HIGH_SCORE_PAGE_SIZE 
		forLeaderboard:leaderboardId 
		comparedToUserId:comparedToUserId
		friendsOnly:friendsOnly 
		silently:silently
        timeScope:0
		onSuccess:onSuccess 
		onFailure:onFailure];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex 
              forLeaderboard:(NSString*)leaderboardId 
            comparedToUserId:(NSString*)comparedToUserId 
                 friendsOnly:(BOOL)friendsOnly
                    silently:(BOOL)silently
                   timeScope:(NSUInteger) timeScope
                   onSuccess:(const OFDelegate&)onSuccess 
                   onFailure:(const OFDelegate&)onFailure
{
	return [OFHighScoreService 
            getPage:pageIndex 
            pageSize:HIGH_SCORE_PAGE_SIZE 
            forLeaderboard:leaderboardId 
            comparedToUserId:comparedToUserId
            friendsOnly:friendsOnly 
            silently:silently
            timeScope:timeScope
            onSuccess:onSuccess 
            onFailure:onFailure];
}

+ (OFRequestHandle*) getPage:(NSInteger)pageIndex pageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId 
            comparedToUserId:(NSString*)comparedToUserId friendsOnly:(BOOL)friendsOnly silently:(BOOL)silently 
                   timeScope:(NSUInteger) timeScope
            onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
	params->io("leaderboard_id", leaderboardId);
	params->io("page", pageIndex);
	params->io("page_size", pageSize);
    if(timeScope > 0) params->io("interval", timeScope);
	
	if (friendsOnly)
	{
		bool friendsLeaderboard = true;
		OFRetainedPtr<NSString> followerId = @"me";
		params->io("friends_leaderboard", friendsLeaderboard);
		params->io("follower_id", followerId);
	}
	
	if (comparedToUserId && [comparedToUserId length] > 0)
	{
		params->io("compared_user_id", comparedToUserId);
	}
	
	//For optimization on the server
	params->io("uses_gc", [OpenFeint isLoggedIntoGameCenter] ? @"1" : @"0");
	
	OFActionRequestType requestType = silently ? OFActionRequestSilent : OFActionRequestForeground;
	
	return [[self sharedInstance] 
	 getAction:@"client_applications/@me/high_scores.xml"
	 withParameters:params
	 withSuccess:onSuccess
	 withFailure:onFailure
	 withRequestType:requestType
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded High Scores")]];
}

+ (void) getLocalHighScores:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	[OFHighScoreService getHighScoresLocal:leaderboardId onSuccess:onSuccess onFailure:onFailure];
}

+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure;
{
	OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
	params->io("leaderboard_id", leaderboardId);	
	params->io("near_user_id", @"me");
	params->io("page_size", pageSize);
	
	return [[self sharedInstance]
	 getAction:@"client_applications/@me/high_scores.xml"
	 withParameters:params
	 withSuccess:onSuccess
	 withFailure:onFailure
     withRequestType:silently ? OFActionRequestSilent : OFActionRequestForeground
	 withNotice:[OFNotificationData foreGroundDataWithText:OFLOCALSTRING(@"Downloaded High Scores")]];
}

+ (OFRequestHandle*) getPageWithLoggedInUserWithPageSize:(NSInteger)pageSize forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
    return [OFHighScoreService getPageWithLoggedInUserWithPageSize:pageSize forLeaderboard:leaderboardId silently:NO onSuccess:onSuccess onFailure:onFailure];
}

+ (OFRequestHandle*) getPageWithLoggedInUserForLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	return [OFHighScoreService getPageWithLoggedInUserWithPageSize:HIGH_SCORE_PAGE_SIZE forLeaderboard:leaderboardId onSuccess:onSuccess onFailure:onFailure];
}

+ (OFRequestHandle*) getHighScoreNearCurrentUserForLeaderboard:(NSString*)leaderboardId andBetterCount:(uint)betterCount andWorseCount:(uint)worseCount onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
	params->io("leaderboard_id", leaderboardId);	
	params->io("near_user_id", @"me");
	params->io("better_count", betterCount);
	params->io("worse_count", worseCount);
	
	return [[self sharedInstance]
			getAction:@"client_applications/@me/high_scores.xml"
			withParameters:params
			withSuccess:onSuccess
			withFailure:onFailure
			withRequestType:OFActionRequestSilent
			withNotice:nil];
}

- (void)_uploadBlobs:(OFPaginatedSeries*)resources
{
	unsigned int highScoreCnt = [resources.objects count];
	for (unsigned int i = 0; i < highScoreCnt; i++ )
	{
		OFHighScore* highScore = [resources.objects objectAtIndex:i];
		NSData* blob = [OFHighScoreService getPendingBlobForLeaderboard:highScore.leaderboardId andScore:highScore.score];
		
		// When there is a blob to upload we don't store the score locally until the blob is done uploading. This means it doesn't get marked as synced and if 
		// something goes wrong or the game closes before uploading the blob then next time the entire highscore will get synced again and if it's still the best
		// the blob will get uploaded again.
		if (blob && highScore.blobUploadParameters)
		{
			[OFHighScoreService uploadBlob:blob forHighScore:highScore];
		}
		else
		{
			if (blob)
			{
				OFLog(@"Failed to upload blob for high score");
			}
			[OFHighScoreService 
			 localSetHighScore:highScore.score
			 forLeaderboard:highScore.leaderboardId
			 forUser:highScore.user.resourceId
			 displayText:highScore.displayText
			 customData:highScore.customData
			 blob:blob
			 serverDate:[NSDate date]
			 addToExisting:NO
			 shouldSubmit:nil
			 overrideExisting:YES];
		}
		
		[OFHighScoreService removePendingBlobForLeaderboard:highScore.leaderboardId];
	}
}

- (void)_onSetHighScore:(OFPaginatedSeries*)resources nextCall:(OFDelegateChained*)nextCall
{
	[nextCall invoke];
}

+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:nil forLeaderboard:leaderboardId silently:NO onSuccess:onSuccess onFailure:onFailure];
}

+ (void) setHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{	
	[OFHighScoreService setHighScore:score withDisplayText:nil forLeaderboard:leaderboardId silently:silently onSuccess:onSuccess onFailure:onFailure];
}

+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:displayText forLeaderboard:leaderboardId silently:NO onSuccess:onSuccess onFailure:onFailure];
}

+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:displayText withCustomData:nil forLeaderboard:leaderboardId silently:silently onSuccess:onSuccess onFailure:onFailure];
}

+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:displayText withCustomData:customData withBlob:nil forLeaderboard:leaderboardId silently:silently deferred:NO onSuccess:onSuccess onFailure:onFailure];	
}

+ (void) setHighScore:(int64_t)score withDisplayText:(NSString*)displayText withCustomData:(NSString*)customData forLeaderboard:(NSString*)leaderboardId silently:(BOOL)silently deferred:(BOOL)deferred onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	[OFHighScoreService setHighScore:score withDisplayText:displayText withCustomData:customData withBlob:nil forLeaderboard:leaderboardId silently:silently deferred:deferred onSuccess:onSuccess onFailure:onFailure];
}

+ (void) setHighScore:(int64_t)score 
	  withDisplayText:(NSString*)displayText 
	   withCustomData:(NSString*)customData 
			 withBlob:(NSData*)blob
	   forLeaderboard:(NSString*)leaderboardId 
			 silently:(BOOL)silently 
			deferred:(BOOL)deferred
			onSuccess:(const OFDelegate&)onSuccess 
			onFailure:(const OFDelegate&)onFailure
{
	bool submittedToGameCenterBecauseOFUnapproved = NO;
	
	if(![OpenFeint hasUserApprovedFeint] && [OpenFeint isLoggedIntoGameCenter])
	{
		//HACK - to make less change to the code, this hack only submits to gamecenter if we are unapproved.
		OFHighScoreBatchEntry* entry = new OFHighScoreBatchEntry(leaderboardId, score, nil, nil, nil);
		OFHighScoreBatchEntrySeries onlySendToGameCenterEntries;
		onlySendToGameCenterEntries.push_back(entry);
		OFSubmitHighScoreToGameCenterOnly* submitObject = [[[OFSubmitHighScoreToGameCenterOnly alloc] init] autorelease];
		[submitObject submitToGameCenterOnlyWithScores:onlySendToGameCenterEntries];
		
		submittedToGameCenterBecauseOFUnapproved = YES;
	}
	
	NSString* notificationText = nil;
	
	NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
	BOOL shouldSubmit = YES;
	BOOL succeeded = [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:lastLoggedInUser displayText:displayText customData:customData blob:blob serverDate:nil addToExisting:NO shouldSubmit:&shouldSubmit overrideExisting:YES];
	if (shouldSubmit)
	{
		if (!deferred && [OpenFeint isOnline])
		{
			bool hasBlob = (blob && ([blob length] <= kMaxHighScoreBlobSize));
			if (hasBlob)
			{
				[OFHighScoreService setPendingBlob:blob forLeaderboard:leaderboardId andScore:score];
			}
			else
			{
				[OFHighScoreService removePendingBlobForLeaderboard:leaderboardId];
				if (blob)
				{
					OFLog(@"High score blob is too big (%d bytes) and will not be uploaded. Maximum size is %d bytes.", [blob length], kMaxHighScoreBlobSize);
				}
			}
			
			OFHighScoreBatchEntry* entry = new OFHighScoreBatchEntry(leaderboardId, score, displayText, customData, blob);
			OFAssert([self sharedInstance], "This method won't work until you initialize the service");
			[NSObject cancelPreviousPerformRequestsWithTarget:[self sharedInstance] selector:@selector(dispatchPendingScores) object:nil];
			[[self sharedInstance] performSelector:@selector(dispatchPendingScores) withObject:nil afterDelay:0.05f];
			[self sharedInstance]->mPendingScores.push_back(entry);
			
			notificationText = OFLOCALSTRING(@"New high score!");
		}
		else
		{
			notificationText = OFLOCALSTRING(@"New high score! Saving locally.");
		}
		
		if (!silently)
		{
			OFNotificationData* notice = [OFNotificationData dataWithText:notificationText andCategory:kNotificationCategoryHighScore andType:kNotificationTypeSuccess];
			notice.imageName = @"HighScoreNotificationIcon.png";
			if([OpenFeint isOnline])
			{
				[[OFNotification sharedInstance] setDefaultBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
			}
			else 
			{
				[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
			}
		}
	}
	else if([OpenFeint isLoggedIntoGameCenter] && !submittedToGameCenterBecauseOFUnapproved)
	{
		//HACK - Make sure we always submit to gamecenter for time scoped leaderboard purposes (this is broken for OF).
		OFHighScoreBatchEntry* entry = new OFHighScoreBatchEntry(leaderboardId, score, nil, nil, nil);
		OFHighScoreBatchEntrySeries onlySendToGameCenterEntries;
		onlySendToGameCenterEntries.push_back(entry);
		OFSubmitHighScoreToGameCenterOnly* submitObject = [[[OFSubmitHighScoreToGameCenterOnly alloc] init] autorelease];
		[submitObject submitToGameCenterOnlyWithScores:onlySendToGameCenterEntries];
	}
	
	if (succeeded)
		onSuccess.invoke();
	else
		onFailure.invoke();
}

+ (OFRequestHandle*) batchSetHighScores:(OFHighScoreBatchEntrySeries&)highScoreBatchEntrySeries onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage
{
	return [OFHighScoreService batchSetHighScores:highScoreBatchEntrySeries silently:NO onSuccess:onSuccess onFailure:onFailure optionalMessage:submissionMessage];
}

+ (OFRequestHandle*) batchSetHighScores:(OFHighScoreBatchEntrySeries&)highScoreBatchEntrySeries silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage
{
	return [OFHighScoreService batchSetHighScores:highScoreBatchEntrySeries silently:silently onSuccess:onSuccess onFailure:onFailure optionalMessage:submissionMessage fromSynch:NO];
}

+ (OFRequestHandle*) batchSetHighScores:(OFHighScoreBatchEntrySeries&)highScoreBatchEntrySeries silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage fromSynch:(BOOL)fromSynch
{
	OFRequestHandle* requestHandle = nil;
	
	if(![OpenFeint hasUserApprovedFeint] && [OpenFeint isLoggedIntoGameCenter])
	{
		OFSubmitHighScoreToGameCenterOnly* submitObject = [[[OFSubmitHighScoreToGameCenterOnly alloc] init] autorelease];
		[submitObject submitToGameCenterOnlyWithScores:highScoreBatchEntrySeries];
	}

	BOOL succeeded = YES;

	if (!fromSynch)
	{
		NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
		int seriesSize = highScoreBatchEntrySeries.size();
		OFHighScoreBatchEntrySeries::iterator it = highScoreBatchEntrySeries.end() - 1;
		for(int i = seriesSize; i > 0 ; i--)
		{
			OFHighScoreBatchEntrySeries::iterator it1 = it;
			it--;
			OFHighScoreBatchEntry* highScore = (*it1);
			BOOL shouldSubmit = YES;
			succeeded = [OFHighScoreService localSetHighScore:highScore->score forLeaderboard:highScore->leaderboardId forUser:lastLoggedInUser displayText:highScore->displayText customData:highScore->customData serverDate:nil addToExisting:NO shouldSubmit:&shouldSubmit];
			if (!shouldSubmit)
			{
				highScoreBatchEntrySeries.erase(it1);
			}
		}
	}
	
	OFHighScoreBatchEntrySeries::const_iterator it = highScoreBatchEntrySeries.begin();
	OFHighScoreBatchEntrySeries::const_iterator itEnd = highScoreBatchEntrySeries.end();
	for (; it != itEnd; ++it)
	{
		if ((*it)->blob)
		{
			[OFHighScoreService setPendingBlob:(*it)->blob.get() forLeaderboard:(*it)->leaderboardId.get() andScore:(*it)->score];
		}
		else
		{
			[OFHighScoreService removePendingBlobForLeaderboard:(*it)->leaderboardId.get()];
		}
	}
	
	if (succeeded)
	{
		requestHandle = [OFHighScoreService submitHighScoreBatch:highScoreBatchEntrySeries silently:silently onSuccess:onSuccess onFailure:onFailure optionalMessage:submissionMessage ? submissionMessage : OFLOCALSTRING(@"Submitted High Scores")];
	}
	else
	{
		onFailure.invoke();
	}
	
	return requestHandle;
}

- (void)dispatchPendingScores
{
	OFDelegate submitSuccessDelegate(self, @selector(_onSetHighScore:nextCall:));
	[OFHighScoreService submitHighScoreBatch:mPendingScores silently:YES onSuccess:submitSuccessDelegate onFailure:OFDelegate() optionalMessage:nil];
	mPendingScores.clear();
}

+ (OFRequestHandle*)submitHighScoreBatch:(OFHighScoreBatchEntrySeries&)highScoreBatchEntrySeries silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage
{
	OFRequestHandle* requestHandle = nil;

	OFDelegate uploadDelegate = OFDelegate([OFHighScoreService sharedInstance], @selector(_uploadBlobs:));
	
    OFGameCenterHighScore* highScore = [[OFGameCenterHighScore alloc] initWithSeries:highScoreBatchEntrySeries];
    highScore.silently = silently;
    highScore.message = submissionMessage;
    requestHandle = [highScore submitOnSuccess:onSuccess onFailure:onFailure onUploadBlob:uploadDelegate];
    [highScore release];
    
	return requestHandle;
}

+ (void) getAllHighScoresForLoggedInUser:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure optionalMessage:(NSString*)submissionMessage
{
	OFNotificationData* notice = [OFNotificationData dataWithText:submissionMessage ? submissionMessage : @"Downloaded High Scores" 
													  andCategory:kNotificationCategoryHighScore
														  andType:kNotificationTypeDownloading];
	OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
	OFRetainedPtr<NSString> me = @"me";
	bool acrossLeaderboards = true;
	params->io("across_leaderboards", acrossLeaderboards);
	params->io("user_id", me);
	
	[[self sharedInstance] 
	 getAction:@"client_applications/@me/high_scores.xml"
	 withParameters:params
	 withSuccess:onSuccess
	 withFailure:onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:notice];
}

+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	[OFHighScoreService getHighScoresFromLocation:origin radius:radius pageIndex:pageIndex forLeaderboard:leaderboardId userMapMode:nil onSuccess:onSuccess onFailure:onFailure];
}

+ (void) getHighScoresFromLocation:(CLLocation*)origin radius:(int)radius pageIndex:(NSInteger)pageIndex forLeaderboard:(NSString*)leaderboardId userMapMode:(NSString*)userMapMode onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
	
	bool geolocation = true;
	params->io("geolocation", geolocation);

	params->io("page", pageIndex);
	
	params->io("leaderboard_id", leaderboardId);
	if (radius != 0)
		params->io("radius", radius);
	
	if (origin)
	{
		CLLocationCoordinate2D coord = origin.coordinate;
		params->io("lat", coord.latitude);
		params->io("lng", coord.longitude);
	}
	
	if (userMapMode)
	{
		params->io("map_me", userMapMode);
	}

	[[self sharedInstance] 
	 getAction:@"client_applications/@me/high_scores.xml"
	 withParameters:params
	 withSuccess:onSuccess
	 withFailure:onFailure
	 withRequestType:OFActionRequestForeground
	 withNotice:nil];	
}

+ (OFRequestHandle*) getDistributedHighScoresAtPage:(NSInteger)pageIndex 
										   pageSize:(NSInteger)pageSize 
										 scoreDelta:(NSInteger)scoreDelta
										 startScore:(NSInteger)startScore
									 forLeaderboard:(NSString*)leaderboardId 
										  onSuccess:(const OFDelegate&)onSuccess 
										  onFailure:(const OFDelegate&)onFailure
{
	return [[self sharedInstance] 
			getAction:[NSString stringWithFormat:@"leaderboards/%@/high_scores/range/%d/%d/%d/%d.xml", leaderboardId, startScore, scoreDelta, pageIndex, pageSize]
			withParameters:nil
			withSuccess:onSuccess
			withFailure:onFailure
			withRequestType:OFActionRequestSilent
			withNotice:nil];
}


+ (OFRequestHandle*) downloadBlobForHighScore:(OFHighScore*)highScore onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OFRequestHandle* request = nil;
	if (![highScore hasBlob])
	{
		OFLog(@"Trying to download the blob for a high score that doesn't have a blob attached to it.");
		onFailure.invoke();
	}
	else
	{	
		if (highScore.blob)
		{
			onSuccess.invoke(highScore);
		}
		else
		{
			OFDelegate chainedSuccess([OFHighScoreService sharedInstance], @selector(onBlobDownloaded:nextCall:), onSuccess);
			OFDelegate chainedFailure([OFHighScoreService sharedInstance], @selector(onBlobFailedDownloading:nextCall:), onFailure);
			request = [OFCloudStorageService downloadS3Blob:highScore.blobUrl passThroughUserData:highScore onSuccess:chainedSuccess onFailure:chainedFailure];
		}
	}
	
	return request;
}

- (void) onBlobDownloaded:(OFS3Response*)response nextCall:(OFDelegateChained*)nextCall
{
	OFHighScore* highScore = (OFHighScore*)response.userParam;
	if (highScore)
	{
		[highScore _setBlob:response.data];
	}
	[nextCall invokeWith:highScore];
}

- (void) onBlobFailedDownloading:(OFS3Response*)response nextCall:(OFDelegateChained*)nextCall
{
	if (response && response.statusCode == 404)
	{
		[OFHighScoreService reportMissingBlobForHighScore:(OFHighScore*)response.userParam];
	}
	[nextCall invoke];
}

@end

