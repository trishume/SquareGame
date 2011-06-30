///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  Copyright 2010 Aurora Feint, Inc.
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
// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "OFWebViewManifestData.h"

@implementation OFWebViewManifestItem
@synthesize path, serverHash, dependentObjects;

-(id) initWithPath:(NSString*) _path hash:(NSString*) hash {
    if((self = [super init])) {
        self.path = _path;
        self.serverHash = hash;
        self.dependentObjects = [NSMutableSet setWithCapacity:5];
    }
    return self;    
}

-(void)dealloc {
    self.path = nil;
    self.serverHash = nil;
    self.dependentObjects = nil;
    [super dealloc];
}

-(NSString*) description {
    return [NSString stringWithFormat:@"<OFWebViewManifestItem>{\"path\" = \"%@\" \"hash\" = \"%@\" \"deps\" = %@",
            self.path, self.serverHash, self.dependentObjects];
}
@end



@implementation OFWebViewManifestData
@synthesize objects, globalObjects;

-(id)init {
    if((self = [super init])) {
        self.objects = [NSMutableDictionary dictionaryWithCapacity:100];
        self.globalObjects = [NSMutableSet setWithCapacity:10];
    }
    return self;
}
-(void) dealloc {
    self.objects = nil;
    self.globalObjects = nil;
    [super dealloc];
}

-(void)populateWithData:(NSData*) data {
    NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
    NSArray*lines = [dataString componentsSeparatedByString:@"\n"];
    OFWebViewManifestItem* item = nil;
    for(NSString* line in lines) {
        //        OFLog(@"String is %@", line);
        NSString *stripped = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(![stripped length]) continue;
        switch([stripped characterAtIndex:0]) {
            case '#': //comment, do nothing
                break;
            case '-':   //dependency, add to the current object
                if(item) {
                    //extract the rest
                    NSString* path = [[stripped substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; 
                    [item.dependentObjects addObject:path];
                }
                else {
                    OFLog(@"Manifest syntax error: dependency without an item: %@", line);
                }
                break;
            default:
                NSArray *pieces = [stripped componentsSeparatedByString:@" "];
                if(pieces.count == 2) {
                    NSString* path = [pieces objectAtIndex:0];
                    if([path characterAtIndex:0] == '@') {
                        NSString* clipped = [path substringFromIndex:1];
                        item = [[OFWebViewManifestItem alloc] initWithPath:clipped hash:[pieces objectAtIndex:1]];
                        [self.globalObjects addObject:clipped];
                        [self.objects setObject:item forKey:clipped];
                    }
                    else {
                        item = [[OFWebViewManifestItem alloc] initWithPath:path hash:[pieces objectAtIndex:1]];
                        [self.objects setObject:item forKey:path];
                    }
                }
                else {
                    OFLog(@"Manifest sytax error %@:", line);
                }
        }    
    }
    //confirm that all dependencies exist?
}

@end

