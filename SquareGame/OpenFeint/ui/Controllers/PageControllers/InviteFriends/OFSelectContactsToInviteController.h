// 
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
// 

#import <AddressBook/AddressBook.h>
#import "OFTableSequenceControllerHelper.h"

@class OFSelectInviteTypeController;

@interface OFSelectContactsToInviteController : OFTableSequenceControllerHelper
{
	OFSelectInviteTypeController* inviteTypeController;
	NSMutableArray* selectedContacts;
	NSMutableArray* addedContacts;
}

@property (nonatomic, retain) OFSelectInviteTypeController* inviteTypeController;
@property (nonatomic, retain) NSMutableArray* selectedContacts;
@property (nonatomic, retain) NSMutableArray* addedContacts;

+ (OFSelectContactsToInviteController*)inviteController:(OFSelectInviteTypeController*)_inviteTypeController withAlreadyAddedContacts:(NSArray*)added withAlreadySelectedContacts:(NSArray*)selected;

- (IBAction)done;

- (void)addPersonWithId:(ABRecordID)recordId andName:(NSString*)name andImageData:(NSData*)imageData andEmail:(NSString*)email;
- (void)addPersonWithId:(ABRecordID)recordId andName:(NSString*)name andImageData:(NSData*)imageData andPhoneNumber:(NSString*)number;

@end
