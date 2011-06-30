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

#import "OFAchievementService.h"
#import "OFAchievementService+Private.h"
#import "OFDependencies.h"
#import "OFAchievement.h"
#import "OFSqlQuery.h"
#import "OFReachability.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFActionRequestType.h"
#import "OFService+Private.h"
#import "OpenFeint+Private.h"
#import "OpenFeint+UserOptions.h"
#import <sqlite3.h>
#import "OFPaginatedSeries.h"
#import "OFOfflineService.h"
#import "OFUser.h"
#import "OFGameCenterAchievement.h"
#import "OFUnlockedAchievement.h"
#import "OFNotification.h"
#import "OFSocialNotificationService+Private.h"
#import "OpenFeint+GameCenter.h"
#import "OFProvider.h"

namespace
{
	static OFSqlQuery sUpdateQuery;
	static OFSqlQuery sPendingUnlocksQuery;
	static OFSqlQuery sDeleteRowQuery;
	static OFSqlQuery sAlreadyAtLeastPartlyCompleteQuery;
	static OFSqlQuery sServerSynchQuery;
	static OFSqlQuery sServerSynchQueryBootstrap;
	static OFSqlQuery sAchievementDefSynchQuery;
	static OFSqlQuery sAchievementDefSynchQueryBootstrap;
	static OFSqlQuery sLastSynchQuery;
	static OFSqlQuery sGetUnlockedAchievementsQuery;
	static OFSqlQuery sGetUnlockedAchievementQuery;
	static OFSqlQuery sGetAchievementsQuery;
	static OFSqlQuery sGetAchievementDefQuery;
	static OFSqlQuery sChangeNullUserQuery;
    static OFSqlQuery sSetUserSynchDateQuery;
	static OFSqlQuery sSetUserSynchDateQueryBootstrap;
}

@implementation OFAchievementService (Private)

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		//[OFAchievementService setupOfflineSupport];
	}
	
	return self;
}

- (void) dealloc
{
	sUpdateQuery.destroyQueryNow();
	sPendingUnlocksQuery.destroyQueryNow();
	sDeleteRowQuery.destroyQueryNow();
	sAlreadyAtLeastPartlyCompleteQuery.destroyQueryNow();
	sServerSynchQuery.destroyQueryNow();
	sServerSynchQueryBootstrap.destroyQueryNow();
	sAchievementDefSynchQuery.destroyQueryNow();
	sAchievementDefSynchQueryBootstrap.destroyQueryNow();
	sLastSynchQuery.destroyQueryNow();
	sGetUnlockedAchievementsQuery.destroyQueryNow();
	sGetUnlockedAchievementQuery.destroyQueryNow();
	sGetAchievementsQuery.destroyQueryNow();
	sGetAchievementDefQuery.destroyQueryNow();
	sChangeNullUserQuery.destroyQueryNow();
	sSetUserSynchDateQuery.destroyQueryNow();
	sSetUserSynchDateQueryBootstrap.destroyQueryNow();
	[super dealloc];
}

+ (void) setupOfflineSupport:(bool)recreateDB
{
	bool oldSchema = false;
	//Check for latest DB schema
	if( !recreateDB )
	{
		oldSchema = ([OFOfflineService getTableVersion:@"unlocked_achievements"] == 1);
	}
	
	if( recreateDB || oldSchema )
	{
		//Doesn't have new table schema, so create it.
		if( oldSchema )
		{
			OFSqlQuery(
				[OpenFeint getOfflineDatabaseHandle], 
				"DROP TABLE IF EXISTS unlocked_achievements_save"
				).execute();
			
		    OFSqlQuery(
				[OpenFeint getOfflineDatabaseHandle], 
				"CREATE TABLE unlocked_achievements_save "
				"AS SELECT * FROM unlocked_achievements",
				false
				).execute(false);
		}
		
		OFSqlQuery(
				   [OpenFeint getOfflineDatabaseHandle], 
				   "DROP TABLE IF EXISTS unlocked_achievements"
				   ).execute();
		
		OFSqlQuery(
				   [OpenFeint getOfflineDatabaseHandle], 
				   "DROP TABLE IF EXISTS achievement_definitions"
				   ).execute();
	}
		
	OFSqlQuery(
			   [OpenFeint getOfflineDatabaseHandle],
			   "CREATE TABLE IF NOT EXISTS unlocked_achievements("
			   "user_id INTEGER NOT NULL,"
			   "achievement_definition_id INTEGER NOT NULL,"
			   "gamerscore INTEGER DEFAULT 0,"
			   "created_at INTEGER DEFAULT NULL,"
			   "server_sync_at INTEGER DEFAULT NULL)"
			   ).execute();
	
	if([OFOfflineService getTableVersion:@"unlocked_achievements"] < 3)
	{
		//Percent complete achievements become supported in version 3 of the unlocked_achievements table
		//This ensures it only adds this column once for tables that are below this version (we change the version, a little below this to higher...)
		OFSqlQuery(
				   [OpenFeint getOfflineDatabaseHandle],
				   "ALTER TABLE unlocked_achievements "
				   "ADD COLUMN percent_complete DOUBLE DEFAULT 100"
				   ).execute();
	}
	
	OFSqlQuery(
			   [OpenFeint getOfflineDatabaseHandle], 
			   "CREATE UNIQUE INDEX IF NOT EXISTS unlocked_achievements_index "
			   "ON unlocked_achievements (achievement_definition_id, user_id)"
			   ).execute();

	OFSqlQuery(
			   [OpenFeint getOfflineDatabaseHandle], 
			   "CREATE TABLE IF NOT EXISTS unlocked_achievements_synch_date( "
               "user_id INTEGER NOT NULL,"
               "synch_date INTEGER NOT NULL)"
			   ).execute();
    
    OFSqlQuery(
               [OpenFeint getOfflineDatabaseHandle],
               "CREATE UNIQUE INDEX IF NOT EXISTS unlocked_achievements_synch_date_index "
               "ON unlocked_achievements_synch_date (user_id)"
               ).execute();
	
	[OFOfflineService setTableVersion:@"unlocked_achievements" version:3];
	
	int achievementDefinitionVersion = [OFOfflineService getTableVersion:@"achievement_definitions"];
	if( achievementDefinitionVersion == 0)
	{
		OFSqlQuery(
			   [OpenFeint getOfflineDatabaseHandle],
			   "CREATE TABLE IF NOT EXISTS achievement_definitions(" 
			   "id INTEGER NOT NULL,"
			   "title TEXT DEFAULT NULL,"
			   "description TEXT DEFAULT NULL,"
			   "gamerscore  INTEGER DEFAULT 0,"
			   "is_secret INTEGER DEFAULT 0,"
			   "icon_file_name TEXT DEFAULT NULL,"
			   "position INTEGER DEFAULT 0,"
			   "start_version  TEXT DEFAULT NULL,"
			   "end_version  TEXT DEFAULT NULL,"
			   "server_sync_at INTEGER DEFAULT NULL)"
			   ).execute();
		
		OFSqlQuery(
		   [OpenFeint getOfflineDatabaseHandle], 
		   "CREATE UNIQUE INDEX IF NOT EXISTS achievement_definitions_index "
		   "ON achievement_definitions (id)"
		   ).execute();
	}
	else
	{
		if( achievementDefinitionVersion == 1)
		{
			OFSqlQuery(
				   [OpenFeint getOfflineDatabaseHandle],
				   "ALTER TABLE achievement_definitions " 
				   "ADD COLUMN start_version  TEXT DEFAULT NULL"
				   ).execute();
		
			OFSqlQuery(
				   [OpenFeint getOfflineDatabaseHandle],
				   "ALTER TABLE achievement_definitions " 
				   "ADD COLUMN end_version  TEXT DEFAULT NULL"
				   ).execute();
		}
		if( achievementDefinitionVersion != 3 )
		OFSqlQuery(
			[OpenFeint getOfflineDatabaseHandle],
			"ALTER TABLE achievement_definitions " 
			"ADD COLUMN position INT DEFAULT 0"
			).execute();
	}
	[OFOfflineService setTableVersion:@"achievement_definitions" version:3];
	
	
	if( oldSchema )
	{
		OFSqlQuery(
			[OpenFeint getOfflineDatabaseHandle], 
			"INSERT INTO unlocked_achievements "
			"(user_id, achievement_definition_id,created_at) "
			"SELECT user_id, achievement_definition_id, strftime('%s', 'now') FROM unlocked_achievements_save",
			false
			).execute(false);
		
		OFSqlQuery(
			[OpenFeint getOfflineDatabaseHandle], 
			"DROP TABLE IF EXISTS unlocked_achievements_save"
			).execute();
	}

	//for testing
	//OFSqlQuery([OpenFeint getOfflineDatabaseHandle], "UPDATE unlocked_achievements SET server_sync_at = NULL").execute();

	//queries needed for offline achievement support
	sUpdateQuery.reset(
		[OpenFeint getOfflineDatabaseHandle], 
		"REPLACE INTO unlocked_achievements "
		"(achievement_definition_id, user_id, percent_complete, created_at) "
		"VALUES(:achievement_definition_id, :user_id, :percent_complete, strftime('%s', 'now'))"
		);
	
	sPendingUnlocksQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"SELECT achievement_definition_id "
		"FROM unlocked_achievements "
		"WHERE user_id = :user_id AND "
		"server_sync_at IS NULL"
		);
	
	sAlreadyAtLeastPartlyCompleteQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"SELECT percent_complete "
		"FROM unlocked_achievements "
		"WHERE user_id = :user_id AND "
		"achievement_definition_id = :achievement_definition_id"
		);
	
	sServerSynchQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"REPLACE INTO unlocked_achievements "
		"(user_id, achievement_definition_id, gamerscore, percent_complete, created_at, server_sync_at) "
		"VALUES (:user_id, :achievement_definition_id, :gamerscore, :percent_complete, :server_sync_at, :server_sync_at)"
		);
	
	sServerSynchQueryBootstrap.reset(
		 [OpenFeint getBootstrapOfflineDatabaseHandle],
		 "REPLACE INTO unlocked_achievements "
		 "(user_id, achievement_definition_id, gamerscore, percent_complete, created_at, server_sync_at) "
		 "VALUES (:user_id, :achievement_definition_id, :gamerscore, :percent_complete, :server_sync_at, :server_sync_at)"
		 );

	sGetAchievementsQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"SELECT * FROM achievement_definitions ORDER BY position"
		);
		
	sGetAchievementDefQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"SELECT *, 0 AS unlocked_date FROM achievement_definitions WHERE id = :id"
		);
	
	sDeleteRowQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"DELETE FROM unlocked_achievements "
		"WHERE user_id = :user_id AND "
		"achievement_definition_id = :achievement_definition_id"
		);
	
	sAchievementDefSynchQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"REPLACE INTO achievement_definitions "
		"(id, title, description, gamerscore, is_secret, icon_file_name, position, start_version, end_version, server_sync_at) "
		"VALUES (:id , :title , :description , :gamerscore , :is_secret , :icon_file_name, :position, :start_version, :end_version, strftime('%s', 'now'))"
		);
	
	sAchievementDefSynchQueryBootstrap.reset(
		 [OpenFeint getBootstrapOfflineDatabaseHandle],
		 "REPLACE INTO achievement_definitions "
		 "(id, title, description, gamerscore, is_secret, icon_file_name, position, start_version, end_version, server_sync_at) "
		 "VALUES (:id , :title , :description , :gamerscore , :is_secret , :icon_file_name, :position, :start_version, :end_version, strftime('%s', 'now'))"
		 );
	

    sLastSynchQuery.reset(
        [OpenFeint getOfflineDatabaseHandle],
        "SELECT datetime(MAX(server_sync_at), 'unixepoch') as last_sync_date FROM "
        "(SELECT MIN(server_sync_at) AS server_sync_at FROM "
        "(SELECT MAX(server_sync_at) AS server_sync_at FROM "
        "(SELECT MAX(synch_date) AS server_sync_at FROM unlocked_achievements_synch_date WHERE user_id = :user_id UNION SELECT 0 AS server_sync_at) X "
        "UNION SELECT MAX(server_sync_at) AS server_sync_at FROM achievement_definitions WHERE server_sync_at IS NOT NULL) Y ) Z"
        );
    
	sGetUnlockedAchievementsQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"select defs.*, unlocked_achievements.created_at AS unlocked_date "
		"FROM (select * from achievement_definitions WHERE start_version <= :app_version AND end_version >= :app_version) AS defs "
		"LEFT JOIN unlocked_achievements ON unlocked_achievements.achievement_definition_id = defs.id "
		"AND unlocked_achievements.user_id = :user_id "
		"ORDER BY unlocked_achievements.created_at DESC, position ASC, defs.id ASC"
		);
	
	sGetUnlockedAchievementQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"select defs.*, unlocked_achievements.created_at AS unlocked_date "
		"FROM (select * from achievement_definitions WHERE start_version <= :app_version AND end_version >= :app_version AND id = :achievement_id) AS defs "
		"LEFT JOIN unlocked_achievements ON unlocked_achievements.achievement_definition_id = defs.id "
		"AND unlocked_achievements.user_id = :user_id "
		"ORDER BY unlocked_achievements.created_at DESC, position ASC, defs.id ASC"
		);

	sChangeNullUserQuery.reset(
		[OpenFeint getOfflineDatabaseHandle],
		"UPDATE unlocked_achievements "
		"SET user_id = :user_id "
		"WHERE user_id IS NULL or user_id = 0"
		);
    
    sSetUserSynchDateQuery.reset(
         [OpenFeint getOfflineDatabaseHandle],
         "REPLACE INTO unlocked_achievements_synch_date "
         "(user_id, synch_date) "
         "VALUES (:user_id, strftime('%s', 'now'))"
         );
	
	sSetUserSynchDateQueryBootstrap.reset(
		  [OpenFeint getBootstrapOfflineDatabaseHandle],
		  "REPLACE INTO unlocked_achievements_synch_date "
		  "(user_id, synch_date) "
		  "VALUES (:user_id, strftime('%s', 'now'))"
		  );
}

+ (OFRequestHandle*) sendPendingAchievements:(NSString*)userId syncOnly:(BOOL)syncOnly onSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure
{
	OFRequestHandle* handle = nil;

	//NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
	if ([OpenFeint isOnline] && [userId longLongValue] > 0)
	{
		//One time case to sync up gamecenter witht he current OpenFeint User.
		if([OpenFeint isLoggedIntoGameCenter] && ![OpenFeint isSynchedWithGameCenterAchievements])
		{
			//Sync everything to game center everytime since we don't have a sync date with game center stored on its server (we can't assume it is the same sync date as above because of new games moving to this integration).
			NSArray* allAchievements = [OFAchievementService getAchievementsLocal];
			NSMutableArray* allAchievementIds = [[NSMutableArray new] autorelease];
			NSMutableArray* allPercentCompletes = [[NSMutableArray new] autorelease];
			for(uint i = 0; i < [allAchievements count]; i++)
			{
				OFAchievement* achievement = [allAchievements objectAtIndex:i];
				[allAchievementIds addObject:achievement.resourceId];
				[allPercentCompletes addObject:[NSNumber numberWithDouble:achievement.percentComplete]];
			}
			
			if([allAchievementIds count] > 0 && [allPercentCompletes count] > 0)
			{
				OFGameCenterAchievement* gcAchievement = [[OFGameCenterAchievement new] autorelease];
				gcAchievement.achievementIds = allAchievementIds;
				gcAchievement.percentsComplete = allPercentCompletes;
				gcAchievement.batch = YES;
				gcAchievement.sync = syncOnly;
				handle = [gcAchievement submitOnSuccess:onSuccess onFailure:onFailure];
			}
			[OpenFeint setSynchWithGameCenterAchievements:YES];
		}
		else
		{
			//associate any offline achievements to user
			sChangeNullUserQuery.bind("user_id", userId);
			sChangeNullUserQuery.execute();
			sChangeNullUserQuery.resetQuery();
			
			NSMutableArray* achievementIdList = [[NSMutableArray new] autorelease];
			NSMutableArray* percentCompleteList = [[NSMutableArray new] autorelease];
			
			sPendingUnlocksQuery.bind("user_id", userId);
			for (sPendingUnlocksQuery.execute(); !sPendingUnlocksQuery.hasReachedEnd(); sPendingUnlocksQuery.step())
			{
				NSString* achievementId = [NSString stringWithFormat:@"%d", sPendingUnlocksQuery.getInt("achievement_definition_id")];
				[achievementIdList addObject:achievementId];
				
				sAlreadyAtLeastPartlyCompleteQuery.bind("achievement_definition_id", achievementId);
				sAlreadyAtLeastPartlyCompleteQuery.bind("user_id", userId);		
				sAlreadyAtLeastPartlyCompleteQuery.execute();
				float percentComplete = (double)(sAlreadyAtLeastPartlyCompleteQuery.getDouble("percent_complete"));
				sAlreadyAtLeastPartlyCompleteQuery.resetQuery();
				
				[percentCompleteList addObject:[NSNumber numberWithDouble:percentComplete]];
			}
			sPendingUnlocksQuery.resetQuery();
			
			if ([achievementIdList count] > 0 && [percentCompleteList count] > 0)
			{
				OFGameCenterAchievement* gcAchievement = [[OFGameCenterAchievement new] autorelease];
				gcAchievement.achievementIds = achievementIdList;
				gcAchievement.percentsComplete = percentCompleteList;
				gcAchievement.batch = YES;
				gcAchievement.sync = syncOnly;
				handle = [gcAchievement submitOnSuccess:onSuccess onFailure:onFailure];
			}
			
		}
	}
	
	return handle;
}

+ (bool) localUpdateAchievement:(NSString*)achievementId forUser:(NSString*)userId andPercentComplete:(double)percentComplete
{
    if([achievementId length] == 0)
    {
        return false;
    }

    if (percentComplete <= [OFAchievementService getPercentComplete:achievementId forUser:userId]) {
        return false;
    }

	sGetAchievementDefQuery.bind("id", achievementId);
	sGetAchievementDefQuery.execute();
	int gamerscore = sGetAchievementDefQuery.getInt("gamerscore");

	double currentPercentComplete = [self getPercentComplete:achievementId forUser:userId];
	
	if (gamerscore > 0 && percentComplete == 100.0 && currentPercentComplete != 100.0)
	{
		OFUser* localUser = [OpenFeint localUser];
		[localUser adjustGamerscore:gamerscore];
		[OpenFeint setLocalUser:localUser];
	}

	sGetAchievementDefQuery.resetQuery();

	sUpdateQuery.bind("achievement_definition_id", achievementId);
	sUpdateQuery.bind("user_id", userId);
	sUpdateQuery.bind("percent_complete", [NSString stringWithFormat:@"%lf", percentComplete]);
	sUpdateQuery.execute();
	bool success = (sUpdateQuery.getLastStepResult() == SQLITE_OK);
	sUpdateQuery.resetQuery();
	
	return success;
}

+ (NSString*) getLastSyncDateForUserId:(NSString*)userId
{
	NSString* lastSyncDate = NULL;
	sLastSynchQuery.bind("user_id", userId);
	sLastSynchQuery.execute();
	lastSyncDate = [NSString stringWithFormat:@"%s", sLastSynchQuery.getText("last_sync_date")];
	sLastSynchQuery.resetQuery();
	return lastSyncDate;
}

+ (OFRequestHandle*) updateAchievements:(NSArray*)achievementIdList withPercentCompletes:(NSArray*)percentCompletes onSuccess:(OFDelegate const&)onSuccess onFailure:(OFDelegate const&)onFailure
{
	OFPointer<OFHttpNestedQueryStringWriter> params = new OFHttpNestedQueryStringWriter;
	{
		OFISerializer::Scope high_score(params, "achievement_list", true);
		
		BOOL anyValidAchievements = NO;
		for (uint i = 0; i < [achievementIdList count] && i < [percentCompletes count]; i++)
		{
			NSString* achievementId = [achievementIdList objectAtIndex:i];
			
			//No Blank achievement id submissions
			if(achievementId && ![achievementId isEqualToString:@""])
			{
				anyValidAchievements = YES;
				double percentComplete = [(NSNumber*)[percentCompletes objectAtIndex:i] doubleValue];
				
				OFISerializer::Scope high_score(params, "achievement");
				OFRetainedPtr<NSString> resourceId = achievementId;
				params->io("achievement_definition_id", resourceId);
				params->io("percent_complete", percentComplete);
			}
		}
		
		if(!anyValidAchievements)
		{
			//TODO Change To Assert when asserts pop alert views
			//No valid achievement ids
			onFailure.invoke();
			return nil;
		}
	}
	
	return [[self sharedInstance] 
	 postAction:@"users/@me/unlocked_achievements.xml"
	 withParameters:params
	 withSuccess:onSuccess
	 withFailure:onFailure
	 withRequestType:OFActionRequestSilent
	 withNotice:[OFNotificationData dataWithText:@"Submitted Unlocked Achivements" andCategory:kNotificationCategoryAchievement andType:kNotificationTypeSubmitting]];
}

// Note: this should be moved into public API
+ (double) getPercentComplete:(NSString*)achievementId forUser:(NSString*)userId
{
	sAlreadyAtLeastPartlyCompleteQuery.bind("achievement_definition_id", achievementId);
	sAlreadyAtLeastPartlyCompleteQuery.bind("user_id", userId);		
	sAlreadyAtLeastPartlyCompleteQuery.execute();
	float percentComplete = (double)(sAlreadyAtLeastPartlyCompleteQuery.getDouble("percent_complete"));
	sAlreadyAtLeastPartlyCompleteQuery.resetQuery();
	return percentComplete;
}

+ (bool) synchUnlockedAchievement:(NSString*)achievementId forUser:(NSString*)userId gamerScore:(NSString*)gamerScore serverDate:(NSDate*)serverDate percentComplete:(double)percentComplete
{
	OFSqlQuery* serverSynchQuery = nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		serverSynchQuery = &sServerSynchQueryBootstrap;
	}
	else 
	{
		serverSynchQuery = &sServerSynchQuery;

	}
	
	NSString* serverSynch = [NSString stringWithFormat:@"%d", (long)[serverDate timeIntervalSince1970]];
	serverSynchQuery->bind("achievement_definition_id", achievementId);
	serverSynchQuery->bind("user_id", userId);
	serverSynchQuery->bind("gamerscore", gamerScore);
	serverSynchQuery->bind("server_sync_at", serverSynch);
	serverSynchQuery->bind("percent_complete", [NSString stringWithFormat:@"%lf", percentComplete]);
	serverSynchQuery->execute();
	bool success = (sServerSynchQuery.getLastStepResult() == SQLITE_OK);
	serverSynchQuery->resetQuery();
	return success;
}

+ (void)synchAchievementsList:(NSArray*)achievements forUser:(NSString*)userId
{
	struct sqlite3* databaseHandle = nil;
	OFSqlQuery* achievementDefSynchQuery = nil;
	OFSqlQuery* setUserSynchDataQuery = nil;
	
	if([NSThread currentThread] == [OpenFeint provider].requestThread)	
	{
		databaseHandle = [OpenFeint getBootstrapOfflineDatabaseHandle];
		achievementDefSynchQuery = &sAchievementDefSynchQueryBootstrap;
		setUserSynchDataQuery = &sSetUserSynchDateQueryBootstrap;
	}
	else 
	{
		databaseHandle = [OpenFeint getOfflineDatabaseHandle];
		achievementDefSynchQuery = &sAchievementDefSynchQuery;
		setUserSynchDataQuery = &sSetUserSynchDateQuery;
	}

	

	unsigned int achievementCnt = [achievements count];
	OFSqlQuery(databaseHandle,"BEGIN TRANSACTION").execute();
	for (unsigned int i = 0; i < achievementCnt; i++)
	{
		OFAchievement* achievement = [achievements objectAtIndex:i];
		
		//update or add achievement definition as needed
		 achievementDefSynchQuery->bind("id", achievement.resourceId);
		 achievementDefSynchQuery->bind("title", achievement.title);
		 achievementDefSynchQuery->bind("description", achievement.description);
		 achievementDefSynchQuery->bind("gamerscore", [NSString stringWithFormat:@"%d", achievement.gamerscore]);
		 achievementDefSynchQuery->bind("is_secret", [NSString stringWithFormat:@"%d", (achievement.isSecret? 1 : 0)]);
		 achievementDefSynchQuery->bind("position", [NSString stringWithFormat:@"%d", achievement.position]);
		 achievementDefSynchQuery->bind("icon_file_name", achievement.iconUrl);
		 achievementDefSynchQuery->bind("start_version", achievement.startVersion);
		 achievementDefSynchQuery->bind("end_version", achievement.endVersion);
		 achievementDefSynchQuery->execute();
		 achievementDefSynchQuery->resetQuery();

		//add user achievements as need 
		if (achievement.percentComplete > 0.0) 
		{
			[OFAchievementService 
			 synchUnlockedAchievement:achievement.resourceId
			 forUser:userId
			 gamerScore:[NSString stringWithFormat:@"%d", achievement.gamerscore]
			 serverDate:achievement.unlockDate
			 percentComplete:achievement.percentComplete];
		}
	}
	OFSqlQuery(databaseHandle,"COMMIT").execute();
    setUserSynchDataQuery->bind("user_id", userId);
    setUserSynchDataQuery->execute();
    setUserSynchDataQuery->resetQuery();
}

+ (void) getAchievementsLocal:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure 
{
	NSArray* achievements = [self getAchievementsLocal];
	onSuccess.invoke([OFPaginatedSeries paginatedSeriesFromArray:achievements]);
}

+ (NSArray*) getAchievementsLocal
{
	NSMutableArray* achievements = [NSMutableArray arrayWithCapacity:20];
	
	sGetUnlockedAchievementsQuery.bind("app_version", [OFOfflineService getFormattedAppVersion]);
	sGetUnlockedAchievementsQuery.bind("user_id", [OpenFeint lastLoggedInUserId]);
	for (sGetUnlockedAchievementsQuery.execute(); !sGetUnlockedAchievementsQuery.hasReachedEnd(); sGetUnlockedAchievementsQuery.step())
	{
		[achievements addObject:[[[OFAchievement alloc] initWithLocalSQL:&sGetUnlockedAchievementsQuery] autorelease]];
	}
	
	sGetUnlockedAchievementsQuery.resetQuery();
	
	return achievements;
}

+ (bool) hasAchievements
{
	sGetAchievementsQuery.execute(); 
	bool hasActive = (sGetAchievementsQuery.getLastStepResult() == SQLITE_ROW);
	sGetAchievementsQuery.resetQuery();
	return hasActive;
}

+ (OFAchievement*) getAchievement:(NSString*)achievementId
{
	sGetAchievementDefQuery.bind("id", achievementId);
	OFAchievement* achievement = nil;
	sGetAchievementDefQuery.execute();
	if (sGetAchievementDefQuery.getLastStepResult() == SQLITE_ROW)
	{
		achievement = [[[OFAchievement alloc] initWithLocalSQL:&sGetAchievementDefQuery] autorelease];
	}
	sGetAchievementDefQuery.resetQuery();
	return achievement;
}

+ (OFAchievement*) getAchievementLocalWithUnlockInfo:(NSString*)achievementId
{
	OFAchievement* achievement = nil;
	sGetUnlockedAchievementQuery.bind("app_version", [OFOfflineService getFormattedAppVersion]);
	sGetUnlockedAchievementQuery.bind("user_id", [OpenFeint lastLoggedInUserId]);
	sGetUnlockedAchievementQuery.bind("achievement_id", achievementId);
	sGetUnlockedAchievementQuery.execute();
	if (sGetUnlockedAchievementQuery.getLastStepResult() == SQLITE_ROW)
	{
		achievement = [[[OFAchievement alloc] initWithLocalSQL:&sGetUnlockedAchievementQuery] autorelease];
	}
	
	sGetUnlockedAchievementQuery.resetQuery();
	return achievement;
}

//piece pulled out so the GameCenter integration can call it
+(void)syncOfflineAchievements:(OFPaginatedSeries*)page {
	unsigned int achievementCnt = [page count];
	NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
	OFUnlockedAchievement* unlockedAchievement = nil;
	
	for (unsigned int i = 0; i < achievementCnt; i++)
	{
		unlockedAchievement = [page objectAtIndex:i];
		if (!unlockedAchievement.isInvalidResult)
		{
			NSDate* unlockedDate = unlockedAchievement.achievement.unlockDate;
			if (!unlockedDate)
			{
				unlockedDate = [NSDate date];
			}
			[OFAchievementService 
			 synchUnlockedAchievement:unlockedAchievement.achievement.resourceId
			 forUser:lastLoggedInUser
			 gamerScore:[NSString stringWithFormat:@"%d", unlockedAchievement.achievement.gamerscore]
			 serverDate:unlockedDate
			 percentComplete:unlockedAchievement.percentComplete];		
		}
	}
}

+(void)finishAchievementsPage:(OFPaginatedSeries*)page duringSync:(BOOL)duringSync fromBatch:(BOOL) fromBatch 
{
	unsigned int achievementCnt = [page count];
	
	if (achievementCnt > 1)
	{
		if (!duringSync)
		{
			OFNotificationData* notice = [OFNotificationData dataWithText:@"Submitted Achievements To Server" andCategory:kNotificationCategoryAchievement andType:kNotificationTypeSuccess];
			[[OFNotification sharedInstance] showBackgroundNotice:notice andStatus:OFNotificationStatusSuccess];
		}
	}
	
    
}


@end
