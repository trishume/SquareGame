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


/*
 
    HighScores submitted in:
        setHighScore .........
            localSetHighScore does the check if we should submit, if so
                might send scores (unless deferred or offline)
                    dispatchSending => submitHighScoreBatch
            send notification

    Offline: sendPendingHS
        grab nulls
        some strange queries to only send one score
        build list, send to batchSetHighScores
            localSetHighScore for each
            blob updates
            submitHighScoreBatch with successDelegate to localSetHighScore, blob management
 
 
    submitHighScoreBatch
        actual server query
            
 
 
 */
#import "OFHighScoreBatchEntry.h"
@class OFRequestHandle;
@class OFPaginatedSeries;

@interface OFGameCenterHighScore : NSObject<OFCallbackable> {
    OFHighScoreBatchEntrySeries scores;
    BOOL silently;
    NSString* message;
    OFDelegate successDelegate;
    OFDelegate failureDelegate;
	OFDelegate uploadBlobDelegate;
    NSUInteger openFeintStatus;  //0=not used, 1=sending, 2=finished, 3=errored
    NSUInteger gameCenterStatus;
    NSUInteger gameCenterCount;
}

-(id)initWithSeries:(OFHighScoreBatchEntrySeries&) scores;
-(OFRequestHandle*)submitOnSuccess:(const OFDelegate&)onSuccess onFailure:(const OFDelegate&)onFailure onUploadBlob:(const OFDelegate&)onUploadBlobDelegate;
@property (nonatomic) BOOL silently;
@property (nonatomic, retain) NSString* message;

@end
