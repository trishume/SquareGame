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

#import <Foundation/Foundation.h>
#import "OFService.h"

//this needs to be an NSObject because it is called using performSelectorOnMainThread
@protocol OFWebViewManifestDelegate <NSObject>
-(void) webViewCacheItemReady:(NSString*) path;
@end

@interface OFWebViewManifestService : OFService {
}
OPENFEINT_DECLARE_AS_SERVICE(OFWebViewManifestService);

+(void) updateToManifest;   //called at initialization time, just after settings are loaded
+(BOOL) isPathLoaded:(NSString*) path;
+(BOOL) isPathValid:(NSString*) path; //returns YES if path is loaded or the system isn't set up yet.  A Yes means that if there's a file there, it can be used
+(BOOL) trackPath:(NSString*) path forMe:(id<OFWebViewManifestDelegate>)caller;  //returns YES if the item needs be loaded, the delegate will receive a notice when that item loads, otherwise you can use it
+(void) prioritizePath:(NSString*) path; //make this and any dependents load first, automatically done by trackPath
+(NSString*) rootPath;
+(void) enableLoad;
+(void) disableLoad;
+(void) setManifestApplication:(NSString*) manifestApplication;

+(void) resetCache;
+(void) startOver;
+(NSArray*) sha1Errors;
@end
