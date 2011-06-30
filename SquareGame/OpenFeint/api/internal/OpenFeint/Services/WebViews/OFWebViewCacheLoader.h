////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2010 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol OFWebViewManifestDelegate;
@class OFWebViewManifestData;
@class OFRunLoopThread;

@interface OFWebViewCacheLoader : NSObject {
@private
    //config
    NSString* manifestApplication;
    NSObject<OFWebViewManifestDelegate>* delegate;
    NSString* rootPath;
    
    //manifests
    NSMutableDictionary* localManifest;
    OFWebViewManifestData* serverManifest;
    
    //loading processing
    NSMutableSet* pathsToLoad;
    NSMutableDictionary* tracked; // tracked is a map of NSString paths to NSMutableSets of OFWebViewManifestDelegates that care about that path
    NSMutableSet* globals;
    NSMutableSet* priority;
    
    //bookkeeping
    BOOL defaultCopied;
    BOOL abortedByReset;
    NSMutableDictionary* observers;
    NSLock *trackingLock;
    
    OFRunLoopThread* thread;
}

@property (assign) NSObject<OFWebViewManifestDelegate>* delegate; //note: this one is atomic!
@property (nonatomic, retain, readonly) NSString* rootPath;    

-(id)initForApplication:(NSString*) manifestApplication;
-(BOOL)trackPath:(NSString*)path forMe:(id<OFWebViewManifestDelegate>)caller;
-(void)prioritizePath:(NSString*)path;
-(BOOL)isPathLoaded:(NSString*)path;
-(BOOL)isPathValid:(NSString*)path;
-(void)enable;
-(void)disable;
-(void)resetToSeed;
-(void)getServerManifest;

@end
