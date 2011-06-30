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

#import "OFResource.h"
#import <AddressBook/AddressBook.h>

//This is a dummy resource.  We don't actually get this information from the server,
//but from the device itself.  The reason it is a resource is because OFTableSequenceControllerHelper
//must deal with OFResources in paginated series.
@interface OFDeviceContact : OFResource 
{
@private
	ABRecordID recordId;
	NSString* name;
	NSString* number;
	NSString* email;
	NSData* imageData;
}

@property (nonatomic, assign) ABRecordID recordId;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* number;
@property (nonatomic, retain) NSString* email;
@property (nonatomic, retain) NSData* imageData;

+ (NSString*)getResourceName;

@end
