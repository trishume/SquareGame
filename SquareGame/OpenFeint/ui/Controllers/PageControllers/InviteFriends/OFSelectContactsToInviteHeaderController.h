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


#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "OFTableControllerHeader.h"

@class OFSelectContactsToInviteController;

@interface OFSelectContactsToInviteHeaderController : UIViewController<OFTableControllerHeader, ABPeoplePickerNavigationControllerDelegate> 
{
@private
	UIImageView* addContactIcon;
	UILabel* addContactLabel;
	UIButton* addContactButton;
# ifdef __IPHONE_3_2
	UIPopoverController* peoplePickerPopover;
# endif
	OFSelectContactsToInviteController* contactInviteController;
}

@property (nonatomic, retain) IBOutlet UIImageView* addContactIcon;
@property (nonatomic, retain) IBOutlet UILabel* addContactLabel;
@property (nonatomic, retain) IBOutlet UIButton* addContactButton;
# ifdef __IPHONE_3_2
@property (nonatomic, retain) UIPopoverController* peoplePickerPopover;
#endif
@property (nonatomic, retain) OFSelectContactsToInviteController* contactInviteController;

- (IBAction)addContact;

@end
