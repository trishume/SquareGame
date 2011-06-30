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

#import "OFDependencies.h"
#import "OFFormControllerHelper+Submit.h"
#import "OFFormControllerHelper+Overridables.h"

#import "OFViewDataGetter.h"
#import "OFHttpNestedQueryStringWriter.h"
#import "OFControllerLoader.h"
#import "OFViewHelper.h"
#import "OFXmlDocument.h"
#import "OFXmlElement.h"
#import "OFProvider.h"
#import "OpenFeint+Private.h"
#import "MPOAuthAPIRequestLoader.h"
#import "OFLoadingController.h"
#import "OFServerException.h"

static NSString* parseErrorXml(NSData* errorXml)
{
	NSMutableString* theWholeReason = [NSMutableString string];
	
	OFXmlDocument* doc = [OFXmlDocument xmlDocumentWithData:errorXml];
	[doc pushNextScope:"errors"];
	while(OFPointer<OFXmlElement> nextError = [doc readNextElement])
	{
		NSString* field = nextError->getAttributeNamed(@"field");
		NSString* reason = nextError->getAttributeNamed(@"reason");
		
        reason = [reason stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        reason = [reason stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        reason = [reason stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        
		if([field isEqualToString:@"base"])
		{
			[theWholeReason appendFormat:@"%@\n", reason];
		}
		else
		{
			[theWholeReason appendFormat:@"- %@: %@\n", field, reason];
		}
	}
	[doc popScope];
	
	return theWholeReason;
}

@interface OFFormControllerHelper ()
- (void) submitForm;
- (void)_requestErroredWithMessage:(NSString*)message;
@end

@implementation OFFormControllerHelper ( Submit )

- (void)_submitFormOFServer
{
	OFPointer<OFHttpNestedQueryStringWriter> queryStream = new OFHttpNestedQueryStringWriter;
	{
		OFISerializer::Scope resource(queryStream, [[self singularResourceName] UTF8String]);
		
		OFViewDataGetter getter(self.view, mViewDataMap);
		getter.serialize(queryStream);
	}
	
	[self addHiddenParameters:queryStream.get()];
	
	[self onBeforeFormSubmitted];
	
	[[OpenFeint provider] performAction:[self getFormSubmissionUrl]
						 withParameters:queryStream->getQueryParametersAsMPURLRequestParameters()
						 withHttpMethod:[self getHTTPMethod]
							withSuccess:OFDelegate(self, @selector(_requestRespondedBehavior:))
							withFailure:OFDelegate(self, @selector(_requestErroredBehavior:))
						withRequestType:OFActionRequestForeground
							 withNotice:[OFNotificationData foreGroundDataWithText:[self getLoadingScreenText]]
				requiringAuthentication:[self shouldUseOAuth]];
}

- (void)_submitFormXPServer
{
	[self onBeforeFormSubmitted];
	OFResourceRequest* request = [self getResourceRequest];
	
	[[request onRespondTarget:self selector:@selector(_requestRespondedBehaviorXP:)] execute];
}

- (void)submitForm
{
	if([self usesXP])
	{
		[self _submitFormXPServer];
	}
	else 
	{
		[self _submitFormOFServer];
	}
	[self onAfterFormSubmitted];
}

- (void)_requestRespondedBehaviorXP:(OFResourceRequest*)request
{
	mIsSubmitting = NO;
 	[self hideLoadingScreen];
	
	if(request.httpResponseCode >= 200 && request.httpResponseCode < 300)
	{
		[self onFormSubmitted:request.resources];
	}
	else
	{
		NSString* message = @"Server sent unknown error message";
		if([request.resources isKindOfClass:[OFServerException class]])
		{
			OFServerException* serverException = request.resources;
			message = serverException.message;
		}
		[self _requestErroredWithMessage:message];
	}

}

- (void)_requestRespondedBehavior:(MPOAuthAPIRequestLoader*)response
{
	mIsSubmitting = NO;
 	[self hideLoadingScreen];
	[self onFormSubmitted:nil];
}

- (void)_requestErroredBehavior:(MPOAuthAPIRequestLoader*)response
{
	NSString* message = parseErrorXml(response.data);
	if ([message length] == 0)
	{
		NSError* error = response.error;	
        OFLOCALIZECOMMENT("Error code formatting")
		message = [NSString stringWithFormat:OFLOCALSTRING(@"%@ (%d[%d])"), [error localizedDescription], error.domain, error.code];
	}
	[self _requestErroredWithMessage:message];
}

- (void)_requestErroredWithMessage:(NSString*)message
{
	[self hideLoadingScreen];
	[self onPresentingErrorDialog];
	
	NSString* okButtonTitle = OFLOCALSTRING(@"Ok");
	[[[[UIAlertView alloc] initWithTitle:OFLOCALSTRING(@"Oops! There was a problem:") 
								 message:message
								delegate:nil
					   cancelButtonTitle:okButtonTitle
					   otherButtonTitles:nil] autorelease] show];
	mIsSubmitting = NO;
}

- (IBAction)onSubmitForm:(UIView*)sender
{
	if (mIsSubmitting)
		return;
		
	if([self shouldShowLoadingScreenWhileSubmitting])
	{
		[self showLoadingScreen];
	}
	
	if([self shouldDismissKeyboardWhenSubmitting])
	{
		OFViewHelper::resignFirstResponder(self.view);			
	}

	mIsSubmitting = YES;
	[self submitForm];
}

@end
