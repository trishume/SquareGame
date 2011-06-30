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

#import <Foundation/Foundation.h>

/**
    OFRunLoopThread - a utility class that will allow you to send performSelector that work on background threads
    Use code similar to the following:
 
    OFRunLoopThread* runLoopThread = [OFRunLoopThread runLoop];
    as long as that lives, you can do:
        [obj performSelector:@selector(stuff) onThread:runLoopThread.... etc
    you will still need to watch for concurrency collisions with the main thread
 
 */
@interface OFRunLoopThread : NSThread {
    id runLoopHolder;
}

+(id) runLoop;
-(id) initWithHolder:(id) holder;
-(void) terminateRunLoop;

@end
