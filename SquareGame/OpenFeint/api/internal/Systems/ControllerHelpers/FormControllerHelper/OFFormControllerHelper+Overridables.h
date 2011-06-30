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

#pragma once

#import "OFFormControllerHelper.h"
#import "OFResourceRequest.h"

@class MPOAuthAPIRequestLoader;

class OFISerializer;

@interface OFFormControllerHelper ( Overridables )

//-------------------------------------------------------
// Global
- (void)registerActionsNow;

// Optional
- (void)onBeforeFormSubmitted;
- (void)onAfterFormSubmitted;
- (bool)shouldShowLoadingScreenWhileSubmitting;
- (bool)shouldDismissKeyboardWhenSubmitting;
- (BOOL)usesXP;
- (void)onFormSubmitted:(id)resources;
- (void)onPresentingErrorDialog;

//-------------------------------------------------------
//OFServer call, use these
- (NSString*)singularResourceName;
- (NSString*)getFormSubmissionUrl;
//Optional
- (void)populateViewDataMap:(OFViewDataMap*)dataMap;
- (void)addHiddenParameters:(OFISerializer*)parameterStream;
- (bool)shouldUseOAuth;
- (NSString*)getHTTPMethod;

//-------------------------------------------------------
//XPServer call, use these
- (OFResourceRequest*)getResourceRequest;
	
@end
