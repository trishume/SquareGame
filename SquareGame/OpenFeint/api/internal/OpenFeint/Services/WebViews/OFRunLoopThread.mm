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

#import "OFRunLoopThread.h"


@interface OFRunLoopStarter : NSObject {
    BOOL terminate;
}
-(void) beginLoop;
-(void) setTerminate;
@end

@implementation OFRunLoopStarter
-(void) beginLoop {
    do {
        NSAutoreleasePool* pool = [NSAutoreleasePool new];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];        
        [pool release];
    } while(!terminate);
}

-(void)setTerminate {
    terminate = YES;
}

@end


@implementation OFRunLoopThread
+(id) runLoop {
    return [[[OFRunLoopThread alloc] initWithHolder:[[OFRunLoopStarter new] autorelease]] autorelease];
}

-(id) initWithHolder:(id) holder {
    if((self = [super initWithTarget:holder selector:@selector(beginLoop) object:nil])) {
        runLoopHolder = holder;
        [self start];
    }
    return self;
}



-(void) terminateRunLoop {
    [runLoopHolder setTerminate];
}



@end
