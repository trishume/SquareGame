////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2011 Aurora Feint, Inc.
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

#import "NSString+OpenFeint.h"
#import "sha1.h"

@implementation NSString (OpenFeint)

- (NSString*) sha1 {
    const char *cString = [self UTF8String];
    unsigned char output[20];
    
    SHA1_CTX ctx;
    SHA1Init(&ctx);
    SHA1Update(&ctx, (unsigned char*)cString, strlen(cString));
    SHA1Final(output, &ctx);
    
    unsigned char printableOutput[41];
    const char hexString[] = "0123456789abcdef";
    for(int i=0; i<20; ++i) {
        printableOutput[2*i] = hexString[(output[i]>>4)&15];
        printableOutput[2*i+1] = hexString[(output[i])&15];
    }
    printableOutput[40] = 0;
    
    NSString *result = [NSString stringWithCString:(const char*)printableOutput encoding:NSUTF8StringEncoding];
    return result;
}

@end
