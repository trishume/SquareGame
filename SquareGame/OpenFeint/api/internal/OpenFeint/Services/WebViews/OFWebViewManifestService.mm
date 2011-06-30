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

#import "OFWebViewManifestService.h"
#import "OFService+Private.h"
#import "OFSettings.h"
#import "OFWebViewCacheLoader.h"
#import "OpenFeint+Private.h"
#import "sha1.h"

//left at file scope to avoid having to reference the instance all the time
namespace { 
    OFWebViewCacheLoader* loader;
    NSString *rootPath;
    NSString *manifestApplication;
}

OPENFEINT_DEFINE_SERVICE_INSTANCE(OFWebViewManifestService);

@implementation OFWebViewManifestService

+ (void)_start {
	loader = [[OFWebViewCacheLoader alloc] initForApplication:manifestApplication];
	rootPath = [loader.rootPath copy];
}

OPENFEINT_DEFINE_SERVICE(OFWebViewManifestService);
- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[[self class] _start];
	}
	return self;
}

- (void)dealloc
{
    OFSafeRelease(loader);
    OFSafeRelease(rootPath);
    OFSafeRelease(manifestApplication);
	[super dealloc];
}


- (void) populateKnownResources:(OFResourceNameMap*)namedResources
{
}


+(void) updateToManifest
{
    [loader getServerManifest];
}

+(BOOL) isPathLoaded:(NSString*) path {
    return [loader isPathLoaded:path];
}

+(BOOL) isPathValid:(NSString*) path {
    return [loader isPathValid:path];
}

+(BOOL) trackPath:(NSString*) path forMe:(id<OFWebViewManifestDelegate>)caller {
    return [loader trackPath:path forMe:(id<OFWebViewManifestDelegate>)caller];
}

+(void) prioritizePath:(NSString*) path {   
    [loader prioritizePath:path];
}

+(NSString*) rootPath {
    return rootPath;
}

+(void) enableLoad {
    [loader enable];
}

+(void)disableLoad {
    [loader disable];
}


+(void)setManifestApplication:(NSString*) app {
    manifestApplication = [app retain];
}

+(void) resetCache {
    [loader resetToSeed];
}

+(void) startOver {
	OFSafeRelease(loader);
	[self _start];
	[self updateToManifest];
}
	

//seems like someone should have already done this...
NSString* initStringFromDigest(const unsigned char *data, int size) {
    const char *charSet = "0123456789abcdef";
    NSMutableData* dataStore = [[NSMutableData alloc] initWithLength:size*2];
    char *pData = (char*) dataStore.bytes;
    for(int i=0; i<size; ++i) {
        *pData++ = charSet[(data[i] >> 4) & 0xf];
        *pData++ = charSet[data[i] & 0xf];
    }
    NSString* stringWithData = [[NSString alloc] initWithData:dataStore encoding:NSASCIIStringEncoding];
    [dataStore release];
    return stringWithData;
}



+(NSArray*) sha1Errors {
    //for every item in the client manifest, find the sha1 and compare it to the real sha1, returns an array of the differences
    NSMutableSet* errorSet = [NSMutableSet setWithCapacity:10];
    NSDictionary* localManifest = [NSDictionary dictionaryWithContentsOfFile:[self.rootPath stringByAppendingPathComponent:@"manifest.plist"]];
    unsigned char digest[20];
    SHA1_CTX ctx;
    
    for(NSString* path in localManifest) {
        NSString*absolutePath = [rootPath stringByAppendingPathComponent:path];
        NSData* fileData = [[NSData alloc] initWithContentsOfFile:absolutePath];
        SHA1Init(&ctx);
        SHA1Update(&ctx, (unsigned char*) fileData.bytes, fileData.length);
        SHA1Final(digest, &ctx);
        [fileData release];
        
        NSString* shaAsString = initStringFromDigest(digest, 20);
        if(![shaAsString isEqualToString:[localManifest objectForKey:path]]) {
            [errorSet addObject:path];
        }
        [shaAsString release];
    }
    return [errorSet allObjects];    
}

@end
