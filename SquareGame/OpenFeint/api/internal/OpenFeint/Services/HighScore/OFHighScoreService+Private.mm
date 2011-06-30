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

#import "OFHighScoreService+Private.h"
#import "OFSqlQuery.h"
#import "OFReachability.h"
#import "OFActionRequestType.h"
#import "OFService+Private.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import <sqlite3.h>
#import "OFLeaderboardService+Private.h"
#import "OFHighScoreBatchEntry.h"
#import "OFHighScore.h"
#import "OFUser.h"
#import "OFUserService+Private.h"
#import "OFPaginatedSeries.h"
#import "OFOfflineService.h"
#import "OFLeaderboard+Sync.h"
#import "OFNotification.h"
#import "OFCloudStorageService.h"
#import "OFS3Response.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+GameCenter.h"
#import "OFProvider.h"

namespace
{
	static OFSqlQuery sSetHighScoreQuery;
	static OFSqlQuery sSetHighScoreQueryBootstrap;
	static OFSqlQuery sPendingHighScoresQuery;
	static OFSqlQuery sScoreToKeepQuery;
	static OFSqlQuery sScoreToKeepQueryBootstrap;
	static OFSqlQuery sServerSynchQuery;
	static OFSqlQuery sDeleteScoresQuery;
	static OFSqlQuery sDeleteScoresQueryBootstrap;
	static OFSqlQuery sMakeOnlyOneSynchQuery;
	static OFSqlQuery sMakeOnlyOneSynchQueryBootstrap;
	static OFSqlQuery sLastSynchQuery;
	static OFSqlQuery sGetHighScoresQuery;
	static OFSqlQuery sGetHighScoresQueryBootstrap;
	static OFSqlQuery sChangeNullUserQuery;
    static OFSqlQuery sNullUserLeaderboardsQuery;
}

// A regular dictionary won't work. If you submit 2 scores in quick succession then it's important that when the first call returns it doesn't think
// the second calls blob belongs to it. We also want to clear based on only leaderboard id so using a combination of leaderboard and score as a NSDictionaty key wont work.
@interface OFPendingBlob : NSObject
{
	NSString* leaderboardId;
	int64_t score;
	NSData* blob;
}

@property (nonatomic, retain) NSString* leaderboardId;
@property (nonatomic, retain) NSData* blob;
@property (nonatomic, assign) int64_t score;

@end

@implementation OFPendingBlob

@synthesize leaderboardId, score, blob;

- (id)initWithLeaderboardId:(NSString*)_leaderboardId andScore:(int64_t)_score andBlob:(NSData*)_blob
{
	self = [super init];
	if (self)
	{
		self.leaderboardId = _leaderboardId;
		self.score = _score;
		self.blob = _blob;
	}
	return self;
}

- (void)dealloc
{
	self.leaderboardId = nil;
	self.blob = nil;
	[super dealloc];
}

@end


@implementation OFHighScoreService (Private)

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		mPendingBlobs = [NSMutableArray new];
	}
	
	return self;
}

- (void) dealloc
{
	OFSafeRelease(mPendingBlobs);
	sSetHighScoreQuery.destroyQueryNow();
	sSetHighScoreQueryBootstrap.destroyQueryNow();
	sPendingHighScoresQuery.destroyQueryNow();
	sScoreToKeepQuery.destroyQueryNow();
	sScoreToKeepQueryBootstrap.destroyQueryNow();
	sServerSynchQuery.destroyQueryNow();
	sDeleteScoresQuery.destroyQueryNow();
	sDeleteScoresQueryBootstrap.destroyQueryNow();
	sMakeOnlyOneSynchQuery.destroyQueryNow();
	sMakeOnlyOneSynchQueryBootstrap.destroyQueryNow();
	sLastSynchQuery.destroyQueryNow();
	sGetHighScoresQuery.destroyQueryNow();
	sGetHighScoresQueryBootstrap.destroyQueryNow();
	sChangeNullUserQuery.destroyQueryNow();
	sNullUserLeaderboardsQuery.destroyQueryNow();
	[super dealloc];
}

+ (void) setupOfflineSupport:(bool)recreateDB
{
	if( recreateDB )
	{
		OFSqlQuery(
			[OpenFeint getOfflineDatabaseHandle],
			"DROP TABLE IF EXISTS high_scores"
			).execute();
	}
	
	//Special PG patch
	OFSqlQuery(
		[OpenFeint getOfflineDatabaseHandle],
		"ALTER TABLE high_scores " 
		"ADD COLUMN display_text TEXT DEFAULT NULL",
		false
		).execute(false);
	//

	int highScoresVersion = [OFOfflineService getTableVersion:@"high_scores"];
	if (highScoresVersion == 1)
	{
		OFSqlQuery(
			[OpenFeint getOfflineDatabaseHandle],
			"ALTER TABLE high_scores " 
			"ADD COLUMN custom_data TEXT DEFAULT NULL"
			).execute();
		highScoresVersion = 2;
	}
	if (highScoresVersion == 2)
	{
		OFSqlQuery(
			[OpenFeint getOfflineDatabaseHandle],
			"ALTER TABLE high_scores " 
			"ADD COLUMN blob BLOB DEFAULT NULL"
			).execute(); 
	}
	else
	{
		OFSqlQuery(
			[OpenFeint getOfflineDatabaseHandle],
			"CREATE TABLE IF NOT EXISTS high_scores("
			"user_id INTEGER NOT NULL,"
			"leaderboard_id INTEGER NOT NULL,"
			"score INTEGER DEFAULT 0,"
			"display_text TEXT DEFAULT NULL,"
			"custom_data TEXT DEFAULT NULL,"
			"server_sync_at INTEGER DEFAULT NULL,"
			"blob BLOB DEFAULT NULL,"
			"UNIQUE(leaderboard_id, user_id, score))"
			).execute();
		
		OFSqlQuery(
			[OpenFeint getOfflineDatabaseHandle], 
			"CREATE INDEX IF NOT EXISTS high_scores_index "
			"ON high_scores (user_id, leaderboard_id)"
			).execute();
	}
	[OFOfflineService setTableVersion:@"high_scores" version:3];
	
	sSetHighScoreQuery.reset(
		[OpenFeint getOfflineDatabaseHandle], 
		"REPLACE INTO high_scores "
		"(user_id, leaderboard_id, score, display_text, custom_data, blob, server_sync_at) "
		"VALUES(:user_id, :leaderboard_id, :score, :display_text, :custom_data, :blob, :server_sync_at)"
		);
	
	sSetHighScoreQueryBootstrap.reset(
	  [OpenFeint getBootstrapOfflineDatabaseHandle], 
	  "REPLACE INTO high_scores "
	  "(user_id, leaderboard_id, score, display_text, custom_data, blob, server_sync_at) "
	  "VALUES(:user_id, :leaderboard_id, :score, :display_text, :custom_data, :blob, :server_sync_at)"
	  );
									  
	
	sPendingHighScoresQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"SELECT leaderboard_id, score, display_text, custom_data, blob "
		"FROM high_scores "
		"WHERE user_id = :user_id AND "
		"server_sync_at IS NULL"
		);
	
	//for testing
	//OFSqlQuery([OpenFeint getOfflineDatabaseHandle], "UPDATE high_scores SET server_sync_at = NULL").execute();
	
	sScoreToKeepQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"SELECT min(score) AS score FROM "
		"(SELECT score FROM high_scores  "
		"WHERE user_id = :user_id AND "
		"leaderboard_id = :leaderboard_id "
		"ORDER BY score DESC LIMIT :max_scores) AS x"
		);
	
	sScoreToKeepQueryBootstrap.reset(
		 [OpenFeint getBootstrapOfflineDatabaseHandle],
		 "SELECT min(score) AS score FROM "
		 "(SELECT score FROM high_scores  "
		 "WHERE user_id = :user_id AND "
		 "leaderboard_id = :leaderboard_id "
		 "ORDER BY score DESC LIMIT :max_scores) AS x"
		 );

	sDeleteScoresQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"DELETE FROM high_scores  "
		"WHERE user_id = :user_id AND "
		"leaderboard_id = :leaderboard_id AND "
		"score < :score"
		);
	
	sDeleteScoresQueryBootstrap.reset(
	  [OpenFeint getBootstrapOfflineDatabaseHandle],
	  "DELETE FROM high_scores  "
	  "WHERE user_id = :user_id AND "
	  "leaderboard_id = :leaderboard_id AND "
	  "score < :score"
	  );
	
	
	sMakeOnlyOneSynchQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"UPDATE high_scores "
		"SET server_sync_at = :server_sync_at "
		"WHERE user_id = :user_id AND "
		"leaderboard_id = :leaderboard_id AND "
		"score != :score AND "
		"server_sync_at IS NULL"
		);
	
	sMakeOnlyOneSynchQueryBootstrap.reset(
	  [OpenFeint getBootstrapOfflineDatabaseHandle],
	  "UPDATE high_scores "
	  "SET server_sync_at = :server_sync_at "
	  "WHERE user_id = :user_id AND "
	  "leaderboard_id = :leaderboard_id AND "
	  "score != :score AND "
	  "server_sync_at IS NULL"
	  );
	
	sChangeNullUserQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"UPDATE high_scores "
		"SET user_id = :user_id "
		"WHERE user_id IS NULL or user_id = 0"
		);
	
	sNullUserLeaderboardsQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"SELECT DISTINCT(leaderboard_id) FROM high_scores "
		"WHERE user_id IS NULL or user_id = 0"
		);
}

+ (bool) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId
{
	return [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:userId displayText:nil serverDate:nil addToExisting:NO];
}

+ (bool) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText serverDate:(NSDate*)serverDate addToExisting:(BOOL) addToExisting
{
	return [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:userId displayText:displayText customData:nil serverDate:nil addToExisting:NO];
}

+ (bool) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText customData:(NSString*)customData serverDate:(NSDate*)serverDate addToExisting:(BOOL) addToExisting
{
	return [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:userId displayText:displayText customData:customData serverDate:serverDate addToExisting:addToExisting shouldSubmit:nil];
}

+ (bool) localSetHighScore:(int64_t)score forLeaderboard:(NSString*)leaderboardId forUser:(NSString*)userId displayText:(NSString*)displayText customData:(NSString*)customData serverDate:(NSDate*)serverDate addToExisting:(BOOL)addToExisting shouldSubmit:(BOOL*)outShouldSubmit
{
	return [OFHighScoreService localSetHighScore:score forLeaderboard:leaderboardId forUser:userId displayText:displayText customData:customData blob:nil serverDate:serverDate addToExisting:addToExisting shouldSubmit:nil overrideExisting:YES];
}

+ (bool) localSetHighScore:(int64_t)score 
			forLeaderboard:(NSString*)leaderboardId 
				   forUser:(NSString*)userId 
			   displayText:(NSString*)displayText 
				customData:(NSString*)customData 
					  blob:(NSData*)blob
				serverDate:(NSDate*)serverDate 
			 addToExisting:(BOOL) addToExisting 
			  shouldSubmit:(BOOL*)outShouldSubmit
		  overrideExisting:(BOOL)overrideExisting
{
	OFSqlQuery* setHighScoreQuery = nil;
	OFSqlQuery* scoreToKeepQuery = nil;
	OFSqlQuery* deleteScoresQuery = nil;
	OFSqlQuery* makeOnlyOneSynchQuery= nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		setHighScoreQuery = &sSetHighScoreQueryBootstrap;
		scoreToKeepQuery = &sScoreToKeepQueryBootstrap;
		deleteScoresQuery = &sDeleteScoresQueryBootstrap;
		makeOnlyOneSynchQuery = &sMakeOnlyOneSynchQueryBootstrap;
	}
	else 
	{
		setHighScoreQuery = &sSetHighScoreQuery;
		scoreToKeepQuery = &sScoreToKeepQuery;
		deleteScoresQuery = &sDeleteScoresQuery;
		makeOnlyOneSynchQuery = &sMakeOnlyOneSynchQuery;
	}
	
	BOOL success = NO;
	BOOL shouldSubmitToServer = YES;
	OFLeaderboard_Sync* leaderboard = [OFLeaderboardService getLeaderboardDetails:leaderboardId];
    

	if (leaderboard && (!leaderboard.isAggregate || addToExisting))
	{
		NSString* serverSynch = nil;
		if( serverDate )
		{
			serverSynch = [NSString stringWithFormat:@"%d", (long)[serverDate timeIntervalSince1970]];
		}
		NSString*lastSyncDate = [OFLeaderboardService getLastSyncDateUnixForUserId:userId];
		int64_t previousScore = 0;
		BOOL hasPreviousScore = [OFHighScoreService getPreviousHighScoreLocal:&previousScore forLeaderboard:leaderboardId];
		if (addToExisting && hasPreviousScore)
		{
			score =  previousScore + score;
		}
		
		//@note allowPostingLowerScores actually means allow posting WORSE scores
		if (!leaderboard.allowPostingLowerScores && hasPreviousScore)
		{
			if ((leaderboard.descendingSortOrder && score <= previousScore) ||	// if higher is better and this new score is lower
				(!leaderboard.descendingSortOrder && score >= previousScore))	// or lower is better and this new score is higher
			{
				if (blob == nil || score != previousScore)
				{
					shouldSubmitToServer = NO;										// don't submit it to the server
				}
			}
		}
		
		
		[OFHighScoreService buildSetHighScoreQuery:overrideExisting];
		
		NSString* sScore = [NSString stringWithFormat:@"%qi", score];
		setHighScoreQuery->bind("user_id", userId);		
		setHighScoreQuery->bind("leaderboard_id", leaderboardId);
		setHighScoreQuery->bind("score", sScore);
		setHighScoreQuery->bind("display_text", displayText);
		setHighScoreQuery->bind("custom_data", customData);
		NSString* newScoresSynchTime = serverSynch;
		if (!newScoresSynchTime && !shouldSubmitToServer)
		{
			// If it shouldn't be submitted then mark it as synched right away
			newScoresSynchTime = [NSString stringWithFormat:@"%d", (long)[[NSDate date] timeIntervalSince1970]];
		}
		setHighScoreQuery->bind("server_sync_at", newScoresSynchTime);
		if (blob)
		{
			setHighScoreQuery->bind("blob", blob.bytes, blob.length);
		}
		
		setHighScoreQuery->execute();
		success = (setHighScoreQuery->getLastStepResult() == SQLITE_OK);
		setHighScoreQuery->resetQuery();
		
		
		[self buildScoreToKeepQuery:leaderboard.descendingSortOrder];
		scoreToKeepQuery->bind("leaderboard_id", leaderboardId);
		scoreToKeepQuery->bind("user_id", userId);		
		scoreToKeepQuery->execute();
		if( scoreToKeepQuery->getLastStepResult() == SQLITE_ROW )
		{
			[self buildDeleteScoresQuery:leaderboard.descendingSortOrder];
			NSString* scoreToKeep = [NSString stringWithFormat:@"%qi", scoreToKeepQuery->getInt64("keep_score")];
			deleteScoresQuery->bind("leaderboard_id", leaderboardId);
			deleteScoresQuery->bind("user_id", userId);		
			deleteScoresQuery->bind("score", scoreToKeep);		
			deleteScoresQuery->execute();
			deleteScoresQuery->resetQuery();
		}
		NSString* synchScore = leaderboard.allowPostingLowerScores ? sScore : [NSString stringWithFormat:@"%qi", scoreToKeepQuery->getInt64("high_score")];
		scoreToKeepQuery->resetQuery();
		
		// [adill note] this normally sets server_sync_at for all scores other
		// than this one. we want to avoid that if the leaderboard allows worse
		// scores and this score is sourced from a server sync (during bootstrap)
		// because it will mark the latest offline score as un-sync'd -- which is bad.
		if (!(leaderboard.allowPostingLowerScores && serverSynch))
		{
			//want only one pending score, but keep history of other scores
			makeOnlyOneSynchQuery->bind("leaderboard_id", leaderboardId);
			makeOnlyOneSynchQuery->bind("user_id", userId);		
			makeOnlyOneSynchQuery->bind("score", synchScore);
			makeOnlyOneSynchQuery->bind("server_sync_at", lastSyncDate);
			makeOnlyOneSynchQuery->execute();
			makeOnlyOneSynchQuery->resetQuery();
		}
		
		//Is leaderboard part of an aggregate
		NSMutableArray* aggregateLeaderboards = [OFLeaderboardService getAggregateParents:leaderboardId];
		for (unsigned int i = 0; i < [aggregateLeaderboards count]; i++)
		{
			OFLeaderboard_Sync* parentLeaderboard = (OFLeaderboard_Sync*)[aggregateLeaderboards objectAtIndex:i];
			[OFHighScoreService localSetHighScore:(score - previousScore)
								   forLeaderboard:parentLeaderboard.resourceId
										  forUser:userId 
									  displayText:nil
									  customData:nil
									   serverDate:[NSDate date]
									addToExisting:YES];
			//[parentLeaderboard release];
		}
	}

	if (outShouldSubmit != nil)
	{
		(*outShouldSubmit) = shouldSubmitToServer;
	}

	return success;
}

+ (bool) synchHighScore:(NSString*)userId
{
	sServerSynchQuery.bind("user_id", userId);	
	sServerSynchQuery.execute();
	bool success = (sServerSynchQuery.getLastStepResult() == SQLITE_OK);
	sServerSynchQuery.resetQuery();
	return success;
}

+ (OFRequestHandle*) sendPendingHighScores:(NSString*)userId silently:(BOOL)silently onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OFRequestHandle* handle = nil;
	OFDelegate chainedSuccessDelegate([OFHighScoreService sharedInstance], @selector(_onSetHighScore:nextCall:), onSuccess);
	
	if ([OpenFeint isOnline] && userId != @"Invalid" && [userId longLongValue] > 0)
	{
		if([OpenFeint isLoggedIntoGameCenter] && ![OpenFeint isSynchedWithGameCenterLeaderboards])
		{
			NSString* mappingPath = [[OpenFeint getResourceBundle] pathForResource:@"OFGameCenter" ofType:@"plist"];
			NSDictionary* mappings = [[NSDictionary alloc] initWithContentsOfFile:mappingPath];
			OFHighScoreBatchEntrySeries pendingHighScores;
			for(NSString* leaderboardId in [mappings objectForKey:@"Leaderboards"])
			{
				NSArray* localHighScores = [OFHighScoreService getHighScoresLocal:leaderboardId];
				for(uint i = 0; i < [localHighScores count]; i++)
				{
					OFHighScore* highScore = [localHighScores objectAtIndex:i];
					OFHighScoreBatchEntry* highScoreBatchEntry = new OFHighScoreBatchEntry();
					highScoreBatchEntry->leaderboardId = leaderboardId;
					highScoreBatchEntry->score = highScore.score;
					highScoreBatchEntry->displayText = highScore.displayText;
					highScoreBatchEntry->customData = highScore.customData;
					highScoreBatchEntry->blob = highScore.blob;
					pendingHighScores.push_back(highScoreBatchEntry);
				}
			}

			handle = [OFHighScoreService 
					  batchSetHighScores:pendingHighScores
					  silently:YES
					  onSuccess:chainedSuccessDelegate
					  onFailure:onFailure
					  optionalMessage: nil
					  fromSynch:YES];
			[OpenFeint setSynchWithGameCenterLeaderboards:YES];
		}

		int64_t leaderboardBestScore = 0;
		NSString* leaderboardId = nil;

		NSString*lastSyncDate = [OFLeaderboardService getLastSyncDateUnixForUserId:userId];
		
		//Get leaderboards with no user_id
		sNullUserLeaderboardsQuery.execute();
		
		//associate any offline high scores to user
		sChangeNullUserQuery.bind("user_id", userId);
		sChangeNullUserQuery.execute();
		sChangeNullUserQuery.resetQuery();
		
		for (; !sNullUserLeaderboardsQuery.hasReachedEnd(); sNullUserLeaderboardsQuery.step())
		{
			leaderboardId = [NSString stringWithFormat:@"%d", sNullUserLeaderboardsQuery.getInt("leaderboard_id")];
			[OFHighScoreService getPreviousHighScoreLocal:&leaderboardBestScore forLeaderboard:leaderboardId];
			sMakeOnlyOneSynchQuery.bind("score", [NSString stringWithFormat:@"%qi", leaderboardBestScore]);
			sMakeOnlyOneSynchQuery.bind("leaderboard_id", leaderboardId);
			sMakeOnlyOneSynchQuery.bind("user_id", userId);
			sMakeOnlyOneSynchQuery.bind("server_sync_at", lastSyncDate);
			sMakeOnlyOneSynchQuery.execute();
			sMakeOnlyOneSynchQuery.resetQuery();
		}

		sNullUserLeaderboardsQuery.resetQuery();
		
		OFHighScoreBatchEntrySeries pendingHighScores;
		sPendingHighScoresQuery.bind("user_id", userId);
		for (sPendingHighScoresQuery.execute(); !sPendingHighScoresQuery.hasReachedEnd(); sPendingHighScoresQuery.step())
		{
			OFHighScoreBatchEntry *highScore = new OFHighScoreBatchEntry();
			highScore->leaderboardId = [NSString stringWithFormat:@"%d", sPendingHighScoresQuery.getInt("leaderboard_id")];
			highScore->score = sPendingHighScoresQuery.getInt64("score");
			const char* cDisplayText = sPendingHighScoresQuery.getText("display_text");
			if( cDisplayText != nil )
			{
				highScore->displayText = [NSString stringWithUTF8String:cDisplayText];
			}
			const char* cCustomData = sPendingHighScoresQuery.getText("custom_data");
			if( cCustomData != nil )
			{
				highScore->customData = [NSString stringWithUTF8String:cCustomData];
			}
			const char* bytes = NULL;
			unsigned int blobLength = 0;
			sPendingHighScoresQuery.getBlob("blob", bytes, blobLength);
			if (blobLength > 0)
			{
				highScore->blob = [NSData dataWithBytes:bytes length:blobLength];
			}

			pendingHighScores.push_back(highScore);
		}
		sPendingHighScoresQuery.resetQuery();
		
		if (pendingHighScores.size() > 0)
		{
			if (false) //(!silently)
			{
				OFLOCALIZECOMMENT("Number inside text")
				OFNotificationData* notice = [OFNotificationData dataWithText:[NSString stringWithFormat:OFLOCALSTRING(@"Submitted %i Score%s"), pendingHighScores.size(), pendingHighScores.size() > 1 ? "" : "s"] andCategory:kNotificationCategoryLeaderboard andType:kNotificationTypeSuccess];
				[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
			}
			
			handle = [OFHighScoreService 
				 batchSetHighScores:pendingHighScores
						   silently:YES
						  onSuccess:chainedSuccessDelegate
						  onFailure:onFailure
					optionalMessage: nil
						  fromSynch:YES
			 ];
		}
	}
	
	return handle;
}

+ (BOOL) getPreviousHighScoreLocal:(int64_t*)score forLeaderboard:(NSString*)leaderboardId
{
	OFLeaderboard_Sync* leaderboard = [OFLeaderboardService getLeaderboardDetails:leaderboardId];
	OFSqlQuery* getHighScoresQuery= [self buildGetHighScoresQuery:leaderboard.descendingSortOrder limit:1];
	getHighScoresQuery->bind("leaderboard_id", leaderboardId);
	getHighScoresQuery->bind("user_id", [OpenFeint localUser].resourceId);
	getHighScoresQuery->execute(); 
	
	BOOL foundScore = NO;
	int64_t scoreToReturn = 0;	// for historical reasons we're going to set 'score' to 0 even if we don't have a score
	if (!getHighScoresQuery->hasReachedEnd())
	{
		foundScore = YES;
		scoreToReturn = getHighScoresQuery->getInt64("score");
	}
	getHighScoresQuery->resetQuery();
	
	if (score != nil)
	{
		(*score) = scoreToReturn;
	}

	return foundScore;
}

+ (void) getHighScoresLocal:(NSString*)leaderboardId onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OFPaginatedSeries* page = [OFPaginatedSeries paginatedSeriesFromArray:[self getHighScoresLocal:leaderboardId]];
	onSuccess.invoke(page);
}

+ (NSArray*) getHighScoresLocal:(NSString*)leaderboardId
{
	NSMutableArray* highScores = [NSMutableArray arrayWithCapacity:10];
	
	OFLeaderboard_Sync* leaderboard = [OFLeaderboardService getLeaderboardDetails:leaderboardId];
	OFSqlQuery* getHighScoresQuery = [self buildGetHighScoresQuery:leaderboard.descendingSortOrder limit:10];
	getHighScoresQuery->bind("leaderboard_id", leaderboardId);
	getHighScoresQuery->bind("user_id", [OpenFeint localUser].resourceId);
	NSUInteger rank = 0;
	for (getHighScoresQuery->execute(); !getHighScoresQuery->hasReachedEnd(); getHighScoresQuery->step())
	{
		OFUser* user = [OFUserService getLocalUser:[NSString stringWithFormat:@"%s", getHighScoresQuery->getText("user_id")]];
		[highScores addObject:[[[OFHighScore alloc] initWithLocalSQL:getHighScoresQuery forUser:user rank:++rank] autorelease]];
	}
	sGetHighScoresQuery.resetQuery();
	
	return highScores;
}

+ (OFHighScore*)getHighScoreForUser:(OFUser*)user leaderboardId:(NSString*)leaderboardId descendingSortOrder:(bool)descendingSortOrder
{
	OFSqlQuery* getHighScoresQuery = [self buildGetHighScoresQuery:descendingSortOrder limit:1];
	getHighScoresQuery->bind("leaderboard_id", leaderboardId);
	getHighScoresQuery->bind("user_id", user.resourceId);
	getHighScoresQuery->execute();
	OFHighScore* highScore = !getHighScoresQuery->hasReachedEnd() ? [[[OFHighScore alloc] initWithLocalSQL:getHighScoresQuery forUser:user rank:1] autorelease] : nil;
	getHighScoresQuery->resetQuery();
	return highScore;
}

+ (void) uploadBlob:(NSData*)blob forHighScore:(OFHighScore*)highScore
{
	if (!highScore.blobUploadParameters)
	{
		OFLog(@"Trying to upload a blob for a high score that doesn't have any upload parameters");
		return;
	}
	if (!blob)
	{
		OFLog(@"Trying to upload a nil high score blob");
		return;
	}
	[highScore _setBlob:blob];
	OFDelegate success([OFHighScoreService sharedInstance], @selector(onBlobUploaded:));
	OFDelegate failure([OFHighScoreService sharedInstance], @selector(onBlobUploadFailed));
	[OFCloudStorageService uploadS3Blob:blob withParameters:highScore.blobUploadParameters passThroughUserData:highScore onSuccess:success onFailure:failure];
}

- (void)onBlobUploaded:(OFS3Response*)response
{
	OFHighScore* highScore = (OFHighScore*)response.userParam;
	[OFHighScoreService 
		localSetHighScore:highScore.score
		forLeaderboard:highScore.leaderboardId
		forUser:highScore.user.resourceId
		displayText:highScore.displayText
		customData:highScore.customData
		blob:highScore.blob
		serverDate:[NSDate date]
		addToExisting:NO
		shouldSubmit:nil
	overrideExisting:YES];
}

- (void)onBlobUploadFailed
{
	OFLog(@"Failed to upload high score blob");
}

+ (OFSqlQuery*) buildGetHighScoresQuery:(bool)descendingOrder limit:(int)limit
{
	OFSqlQuery* getHighScoresQuery = nil;
	struct sqlite3* databaseHandle = NULL;

	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
        databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
		getHighScoresQuery = &sGetHighScoresQueryBootstrap;
	}
	else 
	{
        databaseHandle = [OpenFeint getOfflineDatabaseHandle];
		getHighScoresQuery = &sGetHighScoresQuery;
	}
	
	NSMutableString* query = [[[NSMutableString alloc] initWithString:@"SELECT * FROM high_scores WHERE leaderboard_id = :leaderboard_id AND user_id = :user_id ORDER BY score "] autorelease];
	NSString* orderClause = (descendingOrder ? @"DESC" : @"ASC");
	[query appendString:orderClause];
	[query appendString:[NSString stringWithFormat:@" LIMIT %i", limit]];
	getHighScoresQuery->reset( databaseHandle, [query UTF8String] );
    return getHighScoresQuery;
}

+ (void) buildScoreToKeepQuery:(bool)descendingOrder
{
	struct sqlite3* databaseHandle = nil; 
	OFSqlQuery* scoreToKeepQuery = nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
		scoreToKeepQuery = &sScoreToKeepQueryBootstrap;
	}
	else 
	{
		databaseHandle = [OpenFeint getOfflineDatabaseHandle];
		scoreToKeepQuery = &sScoreToKeepQuery;
	}
	
	//Book keeping save top 10 scores
	NSMutableString* query = [[[NSMutableString alloc] initWithString:@"SELECT "] autorelease];
	NSString* scoreClause = (descendingOrder ? @"min" : @"max");
	[query appendString:scoreClause];
	[query appendString:@"(x.score) AS keep_score, "];
	scoreClause = (descendingOrder ? @"max" : @"min");
	[query appendString:scoreClause];
	[query appendString:@"(x.score) AS high_score FROM (SELECT score FROM high_scores WHERE user_id = :user_id AND leaderboard_id = :leaderboard_id ORDER BY score "];
	NSString* orderClause = (descendingOrder ? @"DESC" : @"ASC");
	[query appendString:orderClause];
	[query appendString:@" LIMIT 10) AS x"];
	scoreToKeepQuery->reset( databaseHandle, [query UTF8String]);
}

+ (void) buildDeleteScoresQuery:(bool)descendingOrder
{
	struct sqlite3* databaseHandle = nil;
	OFSqlQuery* deleteScoresQuery = nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
		deleteScoresQuery = &sDeleteScoresQueryBootstrap;
	}
	else 
	{
		databaseHandle = [OpenFeint getOfflineDatabaseHandle];
		deleteScoresQuery = &sDeleteScoresQuery;
	}
	
	NSMutableString* query =[[[NSMutableString alloc] initWithString:@"DELETE FROM high_scores WHERE user_id = :user_id AND leaderboard_id = :leaderboard_id AND score "] autorelease];
	NSString* comparison = (descendingOrder ? @"<" : @">");
	[query appendString:comparison];
	[query appendString:@" :score"];
	deleteScoresQuery->reset(databaseHandle, [query UTF8String]);
}

+ (void) buildSetHighScoreQuery:(bool)replaceExisting
{
	struct sqlite3* databaseHandle = nil;
	OFSqlQuery* setHighScoreQuery = nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
		setHighScoreQuery = &sSetHighScoreQueryBootstrap;
	}
	else 
	{
		databaseHandle = [OpenFeint getOfflineDatabaseHandle];
		setHighScoreQuery = &sSetHighScoreQuery;
	}
	
	NSMutableString* query =[[[NSMutableString alloc] initWithString:replaceExisting ? @"REPLACE " : @"INSERT OR IGNORE "] autorelease];
	[query appendString:@"INTO high_scores (user_id, leaderboard_id, score, display_text, custom_data, blob, server_sync_at) "
						"VALUES(:user_id, :leaderboard_id, :score, :display_text, :custom_data, :blob, :server_sync_at)"];
	setHighScoreQuery->reset(databaseHandle, [query UTF8String]);
}

- (NSData*)_getPendingBlobForLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score
{
	for (OFPendingBlob* pendingBlob in mPendingBlobs)
	{
		if (pendingBlob.score == score && [pendingBlob.leaderboardId isEqualToString:leaderboardId])
		{
			return pendingBlob.blob;
		}
	}
	return nil;
}

+ (NSData*)getPendingBlobForLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score
{
	return [[OFHighScoreService sharedInstance] _getPendingBlobForLeaderboard:leaderboardId andScore:score];
}

- (void)_setPendingBlob:(NSData*)blob forLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score
{
	[OFHighScoreService removePendingBlobForLeaderboard:leaderboardId];
	OFPendingBlob* pendingBlob = [[[OFPendingBlob alloc] initWithLeaderboardId:leaderboardId andScore:score andBlob:blob] autorelease];
	[mPendingBlobs addObject:pendingBlob];
}

+ (void)setPendingBlob:(NSData*)blob forLeaderboard:(NSString*)leaderboardId andScore:(int64_t)score
{
	[[OFHighScoreService sharedInstance] _setPendingBlob:blob forLeaderboard:leaderboardId andScore:score];
}

- (void)_removePendingBlobForLeaderboard:(NSString*)leaderboardId
{
	for (OFPendingBlob* pendingBlob in mPendingBlobs)
	{
		if ([pendingBlob.leaderboardId isEqualToString:leaderboardId])
		{
			[mPendingBlobs removeObject:pendingBlob];
			return;
		}
	}
}

+ (void)removePendingBlobForLeaderboard:(NSString*)leaderboardId
{
	[[OFHighScoreService sharedInstance] _removePendingBlobForLeaderboard:leaderboardId];
}

+ (void)reportMissingBlobForHighScore:(OFHighScore*)highScore
{			
	if (!highScore)
	{
		OFLog(@"Reporting missing blob for nil high score");
		return;
	}
	
	[[self sharedInstance]
			postAction:[NSString stringWithFormat:@"high_scores/%@/invalidate_blob.xml", highScore.resourceId]
			 withParameters:NULL
			 withSuccess:OFDelegate()
			 withFailure:OFDelegate()
			 withRequestType:OFActionRequestSilent
			 withNotice:nil];
			
}

+ (OFRequestHandle*) submitHighScoreBatch:(OFHighScoreBatchEntrySeries) scores 
                      withGameCenterDates:(NSDictionary*) dates message:(NSString*) message silently:(BOOL) silently 
                                onSuccess:(const OFDelegate&) success onFailure:(const OFDelegate&) failure  
{    
    OFHighScoreBatchEntrySeries::iterator it = scores.begin();
    while(it != scores.end()) 
	{
		OFHighScoreBatchEntrySeries::iterator itNext = it+1; //Might erase it....
		
        OFHighScoreBatchEntry* entry = *it;
		if(!entry->leaderboardId || [entry->leaderboardId isEqualToString:@""])
		{
			//Invalid delete it
			scores.erase(it);
		}
		else
		{
			//valid - get the correct gamecenter date.
			NSDate*date = [dates objectForKey:entry->leaderboardId];
			if(date) 
			{
				entry->gameCenterDate = date;
			}
		}
		
		//advance.
        it = itNext;
    }
	
	if(scores.size() == 0)
	{
		//TODO Change To Assert when asserts pop alert views
		//All were invalid
		failure.invoke();
		return nil;
	}
    
    
    OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
    params->serialize("high_scores", "entry", scores);

    
    CLLocation* location = [OpenFeint getUserLocation];
    if (location)
    {
        double lat = location.coordinate.latitude;
        double lng = location.coordinate.longitude;
        params->io("lat", lat);
        params->io("lng", lng);
    }
    
    OFNotificationData* notice = [OFNotificationData dataWithText:message
                                                      andCategory:kNotificationCategoryHighScore
                                                          andType:kNotificationTypeSubmitting];
    OFRequestHandle* requestHandle = [[self sharedInstance]
                     postAction:@"client_applications/@me/high_scores.xml"
                     withParameters:params
                     withSuccess:success
                     withFailure:failure
                     withRequestType:(silently ? OFActionRequestSilent : OFActionRequestBackground)
                     withNotice:notice];

    return requestHandle;
    
}



@end
