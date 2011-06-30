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

#import "OFFramedNavigationController.h"
#import "OpenFeint+Private.h"
#import "OFSelectContactsToInviteController.h"

#import "OFSelectContactsToInviteHeaderController.h"

@interface OFSelectContactsToInviteHeaderController (Private)
	- (void)_dismissPeoplePicker;
@end

@implementation OFSelectContactsToInviteHeaderController

@synthesize addContactIcon, addContactLabel, addContactButton, contactInviteController;

# ifdef __IPHONE_3_2
@synthesize peoplePickerPopover;
#endif

- (void)resizeView:(UIView*)parentView
{
	UIView* lastElement = self.addContactLabel;
	CGPoint pericynthion = CGPointMake(0, lastElement.frame.origin.y + lastElement.frame.size.height);
	CGPoint perihelion = [lastElement.superview convertPoint:pericynthion toView:self.view];
	CGRect myRect = CGRectMake(0.0f, 0.0f, parentView.frame.size.width, perihelion.y + 20.f);

	self.view.frame = myRect;
	[self.view layoutSubviews];
}

- (IBAction)addContact
{
    ABPeoplePickerNavigationController *picker =
	[[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
	picker.displayedProperties = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:kABPersonEmailProperty], [NSNumber numberWithInt:kABPersonPhoneProperty], nil];
	
	if([OpenFeint isLargeScreen])
	{
# ifdef __IPHONE_3_2
		self.peoplePickerPopover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:picker] autorelease];
		[self.peoplePickerPopover presentPopoverFromRect:addContactButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
#else
        // This should never happen...
        [NSException raise:@"Unsupported OS Version" format:@"Popover controllers require 3.2 OS or greater."];
#endif		
	}
	else
	{
		[[OpenFeint getRootController] presentModalViewController:picker animated:YES];
	}
	
    [picker release];
}

- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker 
{
	[self _dismissPeoplePicker];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
	[self _dismissPeoplePicker];
	
	//Get the id of the address book record
	ABRecordID id = ABRecordGetRecordID(person);
	
	//either an email or a phone number
	BOOL isEmail = (property == kABPersonEmailProperty);
	ABMutableMultiValueRef multiValueRef = ABRecordCopyValue(person, property);
	CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRef, identifier);
	NSString* sendDataThrough = (NSString*)ABMultiValueCopyValueAtIndex(multiValueRef, index);
	
	NSData* profileImageData = nil;
	if(ABPersonHasImageData(person))
	{
		profileImageData = (NSData*)ABPersonCopyImageData(person);
	}
	
	//Construct the name
	NSString* firstName = (NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
	NSString* lastName = (NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
	
	BOOL hasLastName = (lastName && ![lastName isEqualToString:@""]);
	BOOL hasFirstName = (firstName && ![firstName isEqualToString:@""]);
	
	NSString * name;
	if(hasFirstName && hasLastName)
	{
		name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
	}
	else if(hasFirstName && !hasLastName)
	{
		name = [NSString stringWithFormat:@"%@", firstName];
	}
	else if(!hasFirstName && hasLastName)
	{
		name = [NSString stringWithFormat:@"%@", lastName];
	}
	else
	{
		name = [NSString stringWithString:sendDataThrough];
	}
	
	if(isEmail)
	{
		[contactInviteController addPersonWithId:id andName:name andImageData:profileImageData andEmail:sendDataThrough];
	}
	else
	{
		[contactInviteController addPersonWithId:id andName:name andImageData:profileImageData andPhoneNumber:sendDataThrough];
	}
			
    return NO;
}

- (void)_dismissPeoplePicker
{
	if([OpenFeint isLargeScreen])
	{
#ifdef __IPHONE_3_2
		[self.peoplePickerPopover dismissPopoverAnimated:YES];
		self.peoplePickerPopover = nil;
#endif
	}
	else
	{
		[[OpenFeint getRootController] dismissModalViewControllerAnimated:YES];
	}
}

@end
