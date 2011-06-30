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

#import "OFWebUICrashReporter.h"
#import "OFWebViewManifestService.h"
#import "OFXPRequest.h"

@implementation OFWebUICrashReporter
-(id) initWithDelegate:(id<OFWebUICrashReporterDelegate>)_delegate  {
    if((self = [super init])) {
        delegate = _delegate;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Feint initialization failed" 
                                                        message:@"Unable to display the screen. Send crash information to Feint?" 
                                                       delegate:self 
                                              cancelButtonTitle:@"No" 
                                              otherButtonTitles:@"Yes", nil];
        [alert show];
        [alert release];        
    }
    return self;
}

#pragma mark UIAlertViewDelegate
-(void) alertView:(UIAlertView *)alertView  clickedButtonAtIndex:(NSInteger) buttonIndex {
    if(buttonIndex == 1) {
        NSArray* sha1Errors = [OFWebViewManifestService sha1Errors];
        OFXPRequest *req = [OFXPRequest postRequestWithPath:@"/webui/crash_report" andBody:[NSDictionary dictionaryWithObject:sha1Errors forKey:@"bad_sha1"]];
        [req execute];
    }
   
    //not sure we want to enable this just yet
    [OFWebViewManifestService resetCache];
    [delegate crashReporterFinished];
}


@end
