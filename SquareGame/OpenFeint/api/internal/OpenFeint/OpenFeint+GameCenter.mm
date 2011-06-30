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

#import "OpenFeint+GameCenter.h"
#import "OpenFeint+Private.h"
#import "IPhoneOSIntrospection.h"
#import "OFPaginatedSeries.h"
#import "OFTableSectionDescription.h"
#import "OFHighScore.h"
#import "OFHighScoreService.h"
#import "OFLeaderboardService+Private.h"
#ifdef __IPHONE_4_1
#import "GameKit/GameKit.h"
#endif

NSString* OFNSNotificationGameCenterFriendsLoaded = @"OFNSNotificationGameCenterFriendsLoaded";
NSString* OFNSNotificationGameCenterScoresLoaded = @"OFNSNotificationGameCenterScoresLoaded";

//#define DUMP_PAGINATED_SERIES

@interface GCDeferredSubmission : NSObject
{
	GKAchievement *achievement;
	GKScore *score;
	void (^handler)(NSError*);
}

@property (nonatomic, retain) GKAchievement *achievement;
@property (nonatomic, retain) GKScore *score;

+(void)submitAchievement:(GKAchievement*)achievementParam andErrorHandler:(void(^)(NSError *error))errorHandler;
+(void)submitScore:(GKScore*)scoreParam andErrorHandler:(void(^)(NSError *error))errorHandler;

-(id)initWithAchievement:(GKAchievement*)achievementParam andErrorHandler:(void(^)(NSError *error))errorHandler;
-(id)initWithScore:(GKScore*)scoreParam andErrorHandler:(void(^)(NSError *error))errorHandler;
-(void)submit;
-(void)submitBackground;
-(void)callHandler:(NSError*)error;
@end

@implementation GCDeferredSubmission
@synthesize achievement;
@synthesize score;

+(void)submitAchievement:(GKAchievement*)achievementParam andErrorHandler:(void(^)(NSError *error))errorHandler
{
	// This is not a memory leak.
	// The GCDeferredSubmission object is responsible for destroying itself.
	GCDeferredSubmission *submission = [[GCDeferredSubmission alloc] initWithAchievement:achievementParam andErrorHandler:errorHandler];
	[submission submit];
}

+(void)submitScore:(GKScore*)scoreParam andErrorHandler:(void(^)(NSError *error))errorHandler
{
	// This is not a memory leak.
	// The GCDeferredSubmission object is responsible for destroying itself.
	GCDeferredSubmission *submission = [[GCDeferredSubmission alloc] initWithScore:scoreParam andErrorHandler:errorHandler];
	[submission submit];
}

-(id)initWithAchievement:(GKAchievement*)achievementParam andErrorHandler:(void(^)(NSError *error))errorHandler
{
	if((self = [super init]))
	{
		self.achievement = achievementParam;
		self.score = nil;
		handler = Block_copy(errorHandler);
	}
	
	return self;
}

-(id)initWithScore:(GKScore*)scoreParam andErrorHandler:(void(^)(NSError *error))errorHandler
{
	if((self = [super init]))
	{
		self.achievement = nil;
		self.score = scoreParam;
		handler = Block_copy(errorHandler);
	}
	
	return self;
}

-(void)submit
{
	[self performSelectorInBackground:@selector(submitBackground) withObject:nil];
}

-(void)submitBackground
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	if (self.achievement != nil)
	{
		[self.achievement reportAchievementWithCompletionHandler:^(NSError *error)
		 {
			 [self callHandler:error];
		 }];
	}
	else if (self.score != nil)
	{
		[self.score reportScoreWithCompletionHandler:^(NSError *error)
		 {	
			 [self callHandler:error];
		 }];
	}
    [pool release];
}

-(void)callHandler:(NSError*)error
{
	handler (error);
	
	Block_release (handler);
	// Once we've gotten our response we're okay to destroy ourself:
	self.achievement = nil;
	self.score = nil;
	handler = nil;
	
	[self autorelease];
}
@end




#ifdef __IPHONE_4_1
@interface OFHighScore (GameCenter)
-(id) initWithGkScore:(GKScore*) gkScore withRank:(NSInteger) _rank;
-(id) initWithOfScore:(OFHighScore*) ofScore withRank:(NSInteger) _rank;
-(void) setOverrideRank:(NSInteger) newRank;
-(NSString*) description;
@end

@implementation OFHighScore (GameCenter)

-(id) initWithOfScore:(OFHighScore*) ofScore withRank:(NSInteger) _rank {
    if((self = [super init])) {
        user = [ofScore.user retain];
        resourceId = [ofScore.resourceId retain];
        score = ofScore.score;
        rank = _rank;
        leaderboardId = [ofScore.leaderboardId retain];
        displayText = [ofScore.displayText retain];
        customData = [ofScore.customData retain];
        blob = [ofScore.blob retain];
        blobUrl = [ofScore.blobUrl retain];
        toHighRankText = [ofScore.toHighRankText retain];
        gameCenterSeconds = ofScore.gameCenterSeconds;
        blobUploadParameters = [ofScore.blobUploadParameters retain];
        latitude = ofScore.latitude;
        longitude = ofScore.longitude;
        distance = ofScore.distance;
    }
    return self;
}

-(id) initWithGkScore:(GKScore*) gkScore withRank:(NSInteger) _rank {
    if((self = [super init])) {
        user = nil;
		displayText = [gkScore.formattedValue retain];
        score = gkScore.value;
        rank = _rank;    
        gameCenterId = [gkScore.playerID retain]; 
    }
    return self;
}

-(void) setOverrideRank:(NSInteger) newRank {
    rank = newRank;
}

-(NSString*) description {
    return [NSString stringWithFormat:@"<OFHighScore %p> score %ld", self, self.score];
}
@end
#endif


@interface OpenFeintGameCenter : NSObject {
    NSDictionary* mappings;  //read from a plit named OFGameCenter.plist
    
    NSArray *friends;
    NSDictionary* categories;   //map of GameCenter categories to their titles
    NSMutableDictionary* leaderboardsPerTimeScope;
    NSString* currentCategory;
    NSString* currentLeaderboardId;
    NSMutableDictionary* achievements;   //maps OpenFeint Ids to percent complete (which is a double)
    BOOL friendsValid;
    NSUInteger submittedCount;
	BOOL useCustomAsyncSubmission;
}
@property (nonatomic, retain) NSArray* friends;
@property (nonatomic, retain) NSMutableDictionary* leaderboardsPerTimeScope;
@property (nonatomic, retain) NSDictionary* mappings;
@property (nonatomic, retain) NSString* currentCategory;
@property (nonatomic, retain) NSString* currentLeaderboardId;
@property (nonatomic, retain) NSMutableDictionary* achievements;
@property (nonatomic, readonly) BOOL playerValidated;
@property (nonatomic) NSUInteger submittedCount;
@property (nonatomic) BOOL friendsValid;
@property (nonatomic) BOOL useCustomAsyncSubmission;

-(id)init;
#ifdef __IPHONE_4_1        
-(void) gameCenterLogin;
-(void) loadFriends;
-(void) loadAchievements;
-(void) loadScores:(NSString*) category forScope:(GKLeaderboardTimeScope) scope;
-(void) finishLoading;
-(void)loadAllScoresForOFLeaderboardId:(NSString*) leaderboardId;
#endif
@end




@implementation  OpenFeintGameCenter
@synthesize friends;
@synthesize leaderboardsPerTimeScope;
@synthesize mappings;
@synthesize currentCategory;
@synthesize currentLeaderboardId;
@synthesize achievements;
@synthesize submittedCount;
@synthesize useCustomAsyncSubmission;
@synthesize friendsValid;

-(id)init {
    if((self = [super init])) {

		NSString *workingBuiltInSubmissions = @"4.2";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		
		// We use custom async submissions on devices with iOS < 4.2
		self.useCustomAsyncSubmission = [currSysVer compare:workingBuiltInSubmissions options:NSNumericSearch] == NSOrderedAscending;
		
#ifdef __IPHONE_4_1        
        NSString* mappingPath = [[NSBundle mainBundle] pathForResource:@"OFGameCenter" ofType:@"plist"];
        mappings = [[NSDictionary alloc] initWithContentsOfFile:mappingPath];
        self.leaderboardsPerTimeScope = [NSMutableDictionary dictionaryWithCapacity:3];
        self.achievements = [NSMutableDictionary dictionaryWithCapacity:10];
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError* error) {
            [self gameCenterLogin];
        }];
#endif
    }
    return self;
}

-(BOOL)playerValidated {
#ifdef __IPHONE_4_1
    return [GKLocalPlayer localPlayer].authenticated;
#endif
    return NO;
}

#ifdef __IPHONE_4_1  
-(void) gameCenterLogin {
    //we have a new GameCenter player
    GKLocalPlayer* player = [GKLocalPlayer localPlayer];
    
    self.friends = nil;
    friendsValid = NO;
    if(player.authenticated) {
        [self finishLoading];
		OF_OPTIONALLY_INVOKE_DELEGATE([OpenFeint getDelegate], userLoggedInToGameCenter);
    }
    else {
        //if GameCenter isn't enabled, then we'll do our regular login displays
        if([OpenFeint isSuccessfullyBootstrapped])
            [OpenFeint loginShowNotifications];
    }
	[OpenFeint loginGameCenterCheck];
}

-(void) finishLoading {
	
    [self loadFriends];
    [self loadAchievements];    
}

-(void) loadFriends {
    [[GKLocalPlayer localPlayer] loadFriendsWithCompletionHandler:^(NSArray* _friends, NSError* error) {
        if(error == nil) {
            self.friends = _friends;
        }
        else {
            OFLog(@"Error loading friends: %@", error);
            self.friends = nil;
        }
		
        friendsValid = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:OFNSNotificationGameCenterFriendsLoaded object:_friends];
    } ];    
}

-(void)loadAllScoresForOFLeaderboardId:(NSString*) leaderboardId {    
    NSString*category = [[mappings objectForKey:@"Leaderboards"] objectForKey:leaderboardId];
    if(category) {
        self.currentCategory = category;
        self.currentLeaderboardId = leaderboardId;
        [self loadScores:category forScope:GKLeaderboardTimeScopeAllTime];
        [self loadScores:category forScope:GKLeaderboardTimeScopeWeek];
        [self loadScores:category forScope:GKLeaderboardTimeScopeToday];
    }
}


-(void) loadScores:(NSString*)_category forScope:(GKLeaderboardTimeScope) timeScope {
    NSNumber *scopeAsNum = [NSNumber numberWithInt:timeScope];
    GKLeaderboard* board = [GKLeaderboard new];
    board.timeScope = timeScope;
    board.playerScope = GKLeaderboardPlayerScopeGlobal;
    board.category = _category;
    board.range = NSMakeRange(1, HIGH_SCORE_PAGE_SIZE);
    [board loadScoresWithCompletionHandler:^(NSArray *_scores, NSError *error) {
        if(error) {
            OFLog(@"Error loading scores: %@", error);
        }
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:scopeAsNum, @"scope", nil];
//        for(GKScore* score in _scores) {
//            OFLog(@"Gamecenter score %lld at %d\n", score.value, (NSUInteger) [score.date timeIntervalSince1970]);
//        }
		//OFLog(@"Num Game Center Scores: %d for Scope: %d", [_scores count], timeScope);
        [[NSNotificationCenter defaultCenter] postNotificationName:OFNSNotificationGameCenterScoresLoaded object:info];
    }];
    [self.leaderboardsPerTimeScope setObject:board forKey:scopeAsNum];
    [board release];
}

-(void) loadAchievements {
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *_achievements, NSError* error) {
        if(!error) {
            for(GKAchievement* ach in _achievements) {
                NSString* ofAchievement = [[self.mappings objectForKey:@"Achievements"] objectForKey:ach.identifier];
                if(ofAchievement)   
                    [self.achievements setObject:[NSNumber numberWithDouble:ach.percentComplete] forKey:ofAchievement];
            }
        }
        else {
            OFLog(@"Could not read GameCenter achievements: error %@", error);
        }
    }];
}

#endif


-(void) dealloc {
    self.friends = nil;
    self.mappings = nil;
    self.currentCategory = nil;
    self.currentLeaderboardId = nil;
    self.achievements = nil;
    self.leaderboardsPerTimeScope = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
@end

namespace {
    OpenFeintGameCenter* gameCenter;
}


@implementation OpenFeint (GameCenter)
+(BOOL) isUsingGameCenter {
    OpenFeint* instance = [OpenFeint sharedInstance];
    return instance->mIsUsingGameCenter;
}

+(BOOL) isLoggedIntoGameCenter {
#ifdef __IPHONE_4_1 
    if([OpenFeint isUsingGameCenter]) {
        GKLocalPlayer* player = [GKLocalPlayer localPlayer];
        return player.authenticated;
    }
#endif
    return NO;
}

+(void)initializeGameCenter {
	//Its possible to log into gamecenter when openfeint is not approved.  If that is the case and we do login to OpenFeint, then we don't want to reinitialize this data.
    if([self isUsingGameCenter] && !gameCenter) 
	{
			gameCenter = [OpenFeintGameCenter new];
    }
	else
	{
		[OpenFeint loginGameCenterCheck];
	}
	
}

+(void)releaseGameCenter {
    OFSafeRelease(gameCenter);
}

+(NSArray*) getGameCenterFriends {
	if (!gameCenter.friendsValid)
	{
		NSLog(@"Error: GameCenter Friends not yet valid!  Don't call getGameCenterFriends until you get the OFNSNotificationGameCenterFriendsLoaded notification.");
	}
    return gameCenter.friends;
}



+(void) loadGameCenterScores:(NSString*) leaderboardId {
#ifdef __IPHONE_4_1 
    if([OpenFeint isUsingGameCenter]) {
        [gameCenter loadAllScoresForOFLeaderboardId:leaderboardId];
    }
#endif
}

+(NSArray*) getGameCenterScores:(NSInteger) timeScope {
#ifdef __IPHONE_4_1
    GKLeaderboard* board = [gameCenter.leaderboardsPerTimeScope objectForKey:[NSNumber numberWithInt:timeScope]];
    return [board scores];
#else
    return nil;
#endif
}

//a NO result means that GC is enabled, is loading this specific Id and scope, and has not finished loading yet
+(BOOL) isGameCenterScoreLoadedForLeaderboardId:(NSString*)leaderboardId timeScope:(NSUInteger) scope {
#ifdef __IPHONE_4_1
    BOOL allChecksPass = true;
    allChecksPass &= [OpenFeint isUsingGameCenter];
    allChecksPass &= gameCenter.currentLeaderboardId == leaderboardId;
    GKLeaderboard* board = [gameCenter.leaderboardsPerTimeScope objectForKey:[NSNumber numberWithInt:scope]];
    allChecksPass &= board != nil;
    allChecksPass &= [board isLoading];
    
    //ok, so at this point if allChecksPass we know that the GC is supposed to be used and is loading, so report failure
    //otherwise, it is ok to go on, GameCenter isn't loading that one
    return !allChecksPass;
#else
    return YES; //
#endif
}


+(NSString*) getGameCenterAchievementId:(NSString*)openFeintAchievementId {
    return [[gameCenter.mappings objectForKey:@"Achievements"] objectForKey:openFeintAchievementId];
}

+(NSString*) getGameCenterLeaderboardCategory:(NSString*)openFeintLeaderboardId {
    return [[gameCenter.mappings objectForKey:@"Leaderboards"] objectForKey:openFeintLeaderboardId];
}

+(OFPaginatedSeries*) _combineGameCenterScope:(NSUInteger) scopeAsInt IntoPaginatedSeries:(OFPaginatedSeries*)series 
{   //assumes that all the necessary checks have been done first
#ifdef __IPHONE_4_1    
    GKLeaderboardTimeScope scope = scopeAsInt;  //invalid scope
    //make a lookup table out of the GameCenter values
    GKLeaderboard* board = [gameCenter.leaderboardsPerTimeScope objectForKey:[NSNumber numberWithInt:scope]];
    NSMutableArray* combinedArray = [NSMutableArray arrayWithCapacity:/*series.objects.count + board.scores.count*/50];
    NSMutableDictionary* gameCenterLookup = [NSMutableDictionary dictionaryWithCapacity:board.scores.count];
    for(GKScore *score in board.scores) {
        NSUInteger dateSeconds = (NSUInteger) [score.date timeIntervalSince1970];
        [gameCenterLookup setObject:score forKey:[NSNumber numberWithUnsignedInt:dateSeconds]];
    }
    //knock out any gameCenter duplicates
    for(OFHighScore*score in series.objects) {
        NSNumber* key = [NSNumber numberWithUnsignedInt:score.gameCenterSeconds];
        GKScore* gkScore = [gameCenterLookup objectForKey:key];
        if(gkScore.value == score.score) {
            [gameCenterLookup removeObjectForKey:key]; //duplicate found
        }
    }
    //now, remaining GameCenter values need to be merged with the OpenFeint list
    //sort the gameCenter list and do a merge sort
    OFLeaderboard* ofBoard = [OFLeaderboardService getLeaderboard:gameCenter.currentLeaderboardId];
    
    NSArray* sortedArray;
    
    NSArray* gcArray = [NSArray arrayWithArray:[gameCenterLookup allValues]];
    
    if(ofBoard.descendingScoreOrder) {
        sortedArray = [gcArray sortedArrayUsingComparator:^(id lhs, id rhs) {
            GKScore* lhsScore = lhs;
            GKScore* rhsScore = rhs;
            if(lhsScore.value > rhsScore.value)
                return (NSComparisonResult) NSOrderedAscending;
            if(lhsScore.value < rhsScore.value)
                return (NSComparisonResult) NSOrderedDescending;
            return (NSComparisonResult) NSOrderedSame;
        }];
    }
    else {
        sortedArray = [gcArray sortedArrayUsingComparator:^(id lhs, id rhs) {
            GKScore* lhsScore = lhs;
            GKScore* rhsScore = rhs;
            if(lhsScore.value > rhsScore.value)
                return (NSComparisonResult) NSOrderedDescending;
            if(lhsScore.value < rhsScore.value)
                return (NSComparisonResult) NSOrderedAscending;
            return (NSComparisonResult) NSOrderedSame;
        }];
    }
    
    NSEnumerator* gcEnum = [sortedArray objectEnumerator];
    NSEnumerator* ofEnum = [series.objects objectEnumerator];
    
    GKScore *currentGkScore = [gcEnum nextObject];
    OFHighScore*currentOfScore = [ofEnum nextObject];
    while(currentGkScore || currentOfScore) {
        //find smallest remaining
        //case1: OF, no GC = want OF score
        //case2: no OF, GC = want GC score
        //case3: OF, GC OF >= GC = want OF score
        //case4: OF, GC, OF < GC = want GC
        
        //reverse greater/less for low scores ranking higher
        
        BOOL useOfScore = currentOfScore != nil;  //handles case of only one existing
        if(useOfScore && currentGkScore) {
            if(ofBoard.descendingScoreOrder) {
                if(currentGkScore.value > currentOfScore.score) useOfScore = NO;
            }
            else {
                if(currentGkScore.value < currentOfScore.score) useOfScore = NO;
            }
        }
        //remove one or the other
        if(useOfScore) {
            [combinedArray addObject:[[[OFHighScore alloc] initWithOfScore:currentOfScore withRank:combinedArray.count + 1]autorelease]];
            currentOfScore = [ofEnum nextObject];
        }
        else {
            [combinedArray addObject:[[[OFHighScore alloc] initWithGkScore:currentGkScore withRank:combinedArray.count + 1]autorelease]];
            currentGkScore = [gcEnum nextObject];
        }
    }

    //NOTE: you need to move clipping of the array until later because the entire list is being used for lookups to adjust the user's rank
    return [OFPaginatedSeries paginatedSeriesFromArray:combinedArray];
		
    
#endif
    return series;
}

namespace { 
#ifdef DUMP_PAGINATED_SERIES
    void dumpPaginatedSeries(OFPaginatedSeries* series) 
	{
        OFLog(@"Dump of paginated series %@", series);
        for(id item in series.objects) {
            if([item isKindOfClass:[OFTableSectionDescription class]]) 
			{
                OFTableSectionDescription*desc = item;
                OFLog(@"  TableSection %@ title:%@", desc, desc.title);
                
				for(OFHighScore* score in desc.page.objects) 
				{
                    OFLog(@"    Score %@ %@ (#%d)", score, score.resourceId, score.rank);
                }            
            } 
			else if([item isKindOfClass:[OFHighScore class]]) 
			{
                OFLog(@"  Score %@ %@ (#%d)", item, ((OFHighScore*)item).resourceId,((OFHighScore*)item).rank);
            } 
			else 
			{
                OFLog(@" Unknown item class %@", item);
            }
        }
    }
#endif
	
    NSDictionary*buildLookupFromPage(OFPaginatedSeries* page) {
        NSMutableDictionary*lookupDict = [NSMutableDictionary dictionaryWithCapacity:page.objects.count];
        for(OFHighScore* score in page.objects) {
            if(score.resourceId)
                [lookupDict setObject:[NSNumber numberWithInt:score.rank] forKey:score.resourceId];
            
        }
        return lookupDict;
    }
}

+(OFPaginatedSeries*) combinedGameCenterForLeaderboardId:(NSString*)leaderboardId timeScope:(NSUInteger) scopeInDays globals:(OFPaginatedSeries*) openFeintGlobal friends:(OFPaginatedSeries*) openFeintFriends;
{
	//	OFLog(@"GLOBAL");
	//	dumpPaginatedSeries(openFeintGlobal);
	//	OFLog(@"FRIEND");
	//	dumpPaginatedSeries(openFeintFriends);
    OFPaginatedSeries* combined = [OFPaginatedSeries paginatedSeriesFromSeries:openFeintGlobal];
	
    OpenFeint* instance = [OpenFeint sharedInstance];
    NSDictionary* lookupDict = nil;
    if(instance) {
        NSString*gcCategory = [[gameCenter.mappings objectForKey:@"Leaderboards"] objectForKey:leaderboardId];
        if(gcCategory && [gcCategory isEqual:gameCenter.currentCategory]) {
            //assuming that the first object is your score and the second the global list
            if(combined.objects.count > 1) {
                OFTableSectionDescription* globalDesc = [combined.objects objectAtIndex:1];
                OFPaginatedSeries* newSeries = [OpenFeint _combineGameCenterScope:scopeInDays IntoPaginatedSeries:globalDesc.page];
                lookupDict = buildLookupFromPage(newSeries);
                [combined.objects replaceObjectAtIndex:1 withObject:[OFTableSectionDescription sectionWithTitle:globalDesc.title andPage:newSeries]];
            }
            else {
                OFPaginatedSeries* newSeries = [OpenFeint _combineGameCenterScope:scopeInDays IntoPaginatedSeries:nil];
                lookupDict = buildLookupFromPage(newSeries); //this will be empty by definition...
                [combined.objects addObject:[OFTableSectionDescription sectionWithTitle:@"Everyone" andPage:newSeries]];
            }
        }
    }
    
    OFTableSectionDescription* friendsDesc = [OFTableSectionDescription new];
    friendsDesc.title = @"Friends";
    
    friendsDesc.page = [OFPaginatedSeries paginatedSeriesFromSeries:openFeintFriends];
    [combined.objects insertObject:friendsDesc atIndex:1];
	//    OFLog(@"BEFORE");
	//    dumpPaginatedSeries(combined);
	
    if(lookupDict) {
        OFTableSectionDescription* desc = [combined.objects objectAtIndex:0];
        for(OFHighScore* score in desc.page.objects) {
            NSNumber* lookup = [lookupDict objectForKey:score.resourceId];
            if(lookup) {
#ifdef __IPHONE_4_1
                [score setOverrideRank:[lookup intValue]];
#endif
            }
        }
    }
    
    [friendsDesc release];
	//    OFLog(@"AFTER");
	//    dumpPaginatedSeries(combined);

    //clip to page size, otherwise you run into issues where the combined list is missing scores:
    // OF:  100, 99, 87, 76, 65, 54, 43
    // GC:  70, 66, 20, 10, 5
    // SIZE: 5
    // combined list is 100, 99, 87, 76, 70, 66, 65, 20, 10, 5
    // if you showed them all, then the 54 would not show up even though it is > than the 20

    for(OFTableSectionDescription* desc in combined.objects) {
        NSMutableArray* objects = desc.page.objects;
        if(objects.count > HIGH_SCORE_PAGE_SIZE)
        {
            [objects removeObjectsInRange:NSMakeRange(HIGH_SCORE_PAGE_SIZE, objects.count - HIGH_SCORE_PAGE_SIZE)];
        }        
    }
    return combined;
    
}

#ifdef __IPHONE_4_1
+(void) submitAchievementToGameCenter:(NSString*)gameCenterAchievementId withPercentComplete:(double)percentComplete withHandler:(void(^)(NSError*))handler {
    GKAchievement* newAchievement = [[GKAchievement alloc] initWithIdentifier:gameCenterAchievementId];
    newAchievement.percentComplete = percentComplete;

	if (gameCenter.useCustomAsyncSubmission)
	{
		[GCDeferredSubmission submitAchievement:newAchievement andErrorHandler:handler];
	}
	else 
	{
		[newAchievement reportAchievementWithCompletionHandler:handler];
	}
	
	
	[newAchievement release];
}


+(NSDate*) submitScoreToGameCenter:(long long) score category:(NSString*) category withHandler:(void(^)(NSError*))handler {
    GKScore *gkScore = [[GKScore alloc] initWithCategory:category];
    NSDate *returnDate = gkScore.date;
    gkScore.value = score;
	
	if (gameCenter.useCustomAsyncSubmission)
	{
		[GCDeferredSubmission submitScore:gkScore andErrorHandler:handler];
	}
	else
	{
		[gkScore reportScoreWithCompletionHandler:^(NSError*error) {
			handler(error);
		}];
	}

	[gkScore release];
	
    return returnDate;
}

+(void) loadGameCenterPlayerName:(NSString*)gameCenterId withHandler:(void(^)(NSString* player, NSError* error))handler {
    [GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:gameCenterId] withCompletionHandler:^(NSArray* players, NSError*error) {
        GKPlayer* player = [players objectAtIndex:0];
        handler(player.alias, error);
    }];
}

#endif


@end
