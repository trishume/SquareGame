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


#import "OFTableSectionDescription.h"
#import "OFControllerLoader.h"
#import "OFSelectInviteTypeController.h"
#import "OFDeviceContact.h"
#import "OFSelectableContactCell.h"
#import "OFSelectContactsToInviteHeaderController.h"
#import "OFSelectContactsToInviteController.h"


@interface OFSelectContactsToInviteController (Private)
@end

@implementation OFSelectContactsToInviteController

@synthesize inviteTypeController, selectedContacts, addedContacts;

//call _refreshData once we get a new contact added, in turn this will call doIndexActionOnSuccess:onFailure:

- (void)populateResourceMap:(OFResourceControllerMap*)resourceMap
{
	resourceMap->addResource([OFDeviceContact class], @"SelectableContact");
}

- (void)doIndexActionOnSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure;
{
	//Create the "dummy" resources from the contacts added and send them through
	OFPaginatedSeries* resources = [OFPaginatedSeries paginatedSeriesFromArray:addedContacts];
	success.invoke(resources);
}

- (void)doIndexActionWithPage:(unsigned int)oneBasedPageNumber onSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{
	//Do nothing - needed for no assert
}

/*- (UIViewController*)getNoDataFoundViewController
{
	//Add a contact controller needed.
	return nil;
}*/

- (NSString*)getNoDataFoundMessage
{
	return @"";
}

- (bool)shouldDisplayEmptyDataSet
{
	//Don't show any controller for the empty data set, because combine with the header, it looks ugly.
	return false;
}

- (NSString*)getDataNotLoadedYetMessage
{
	// This isn't used with the getNoDataFoundViewController - this is actually what shows while we're getting the invite definition.
	return @"Loading Contacts...";
}

- (NSString*)getTableHeaderControllerName
{
	return @"SelectContactsToInviteHeader";
}

- (bool)usePlainTableSectionHeaders
{
	return true;
}

- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{
	((OFSelectContactsToInviteHeaderController*)tableHeader).contactInviteController = self;
}

- (void)onSectionsCreated:(NSMutableArray*)sections
{
	OFTableSectionDescription* firstSection = [sections objectAtIndex:0];
	firstSection.title = @"Contacts To Invite";
}

- (void)onCell:(OFTableCellHelper*)cell resourceChanged:(OFResource*)contact
{
	if([cell isKindOfClass:[OFSelectableContactCell class]])
	{
		((OFSelectableContactCell*)cell).checked = ([selectedContacts indexOfObject:contact] != NSNotFound);
	}
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if([cellResource isKindOfClass:[OFDeviceContact class]])
	{
		UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
		if([cell isKindOfClass:[OFSelectableContactCell class]])
		{
			OFSelectableContactCell* contactCell = (OFSelectableContactCell*)cell;
			
			NSUInteger selectedContactsIndex = [selectedContacts indexOfObject:cellResource];
			if(selectedContactsIndex != NSNotFound)
			{
				contactCell.checked = NO;
				[selectedContacts removeObjectAtIndex:selectedContactsIndex];
			}
			else
			{
				contactCell.checked = YES;
				[selectedContacts addObject:cellResource];
			}
		}
		//This call seems broken on ipad?
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (IBAction)done
{
	//Alert the InviteType controller of my selected users and pop myself off the nav view stack
	[inviteTypeController updateSelectedType:ESelectedPersonType_CONTACT with:selectedContacts];
	inviteTypeController.addedContacts = addedContacts;
	[self.navigationController popViewControllerAnimated:YES];	
}
	 
- (void)addPersonWithId:(ABRecordID)recordId andName:(NSString*)name andImageData:(NSData*)imageData andEmail:(NSString*)email
{	
	if(!addedContacts)
	{
		addedContacts = [NSMutableArray new];
	}
	
	if(!selectedContacts)
	{
		selectedContacts = [NSMutableArray new];
	}
	
	OFDeviceContact* contactToSelect = nil;
	
	BOOL contactIsAlreadyAdded = NO;
	for(uint i = 0; i < [addedContacts count]; i++)
	{
		//If the contact is already added, just update its number and email.
		OFDeviceContact* contact = [addedContacts objectAtIndex:i];
		if(contact.recordId == recordId)
		{
			contact.number = nil;
			contact.email = email;
			contactToSelect = contact;
			contactIsAlreadyAdded = YES;
			break;
		}
	}
	
	if(!contactIsAlreadyAdded)
	{
		OFDeviceContact* newContactToAdd = [[[OFDeviceContact alloc] init] autorelease];
		newContactToAdd.recordId = recordId;
		newContactToAdd.name = name;
		newContactToAdd.imageData = imageData;
		newContactToAdd.number = nil;
		newContactToAdd.email = email;
		contactToSelect = newContactToAdd;
		
		[addedContacts addObject:newContactToAdd];
	}
	
	if([selectedContacts indexOfObject:contactToSelect] == NSNotFound)
	{
		[selectedContacts addObject:contactToSelect];
	}

	[self _refreshData];
}
	 
- (void)addPersonWithId:(ABRecordID)recordId andName:(NSString*)name andImageData:(NSData*)imageData andPhoneNumber:(NSString*)number
{	
	if(!addedContacts)
	{
		addedContacts = [NSMutableArray new];
	}
	
	if(!selectedContacts)
	{
		selectedContacts = [NSMutableArray new];
	}
	
	OFDeviceContact* contactToSelect = nil;
	
	BOOL contactIsAlreadyAdded = NO;
	for(uint i = 0; i < [addedContacts count]; i++)
	{
		//If the contact is already added, just update its number and email.
		OFDeviceContact* contact = [addedContacts objectAtIndex:i];
		if(contact.recordId == recordId)
		{
			contact.number = number;
			contact.email = nil;
			contactToSelect = contact;
			contactIsAlreadyAdded = YES;
			break;
		}
	}
	
	if(!contactIsAlreadyAdded)
	{
		OFDeviceContact* newContactToAdd = [[[OFDeviceContact alloc] init] autorelease];
		newContactToAdd.recordId = recordId;
		newContactToAdd.name = name;
		newContactToAdd.imageData = imageData;
		newContactToAdd.number = number;
		newContactToAdd.email = nil;
		contactToSelect = newContactToAdd;
		[addedContacts addObject:newContactToAdd];
	}
	
	if([selectedContacts indexOfObject:contactToSelect] == NSNotFound)
	{
		[selectedContacts addObject:contactToSelect];
	}
	
	[self _refreshData];
}

- (BOOL)shouldAlwaysShowNavBar
{
	return YES;
}

- (void)dealloc
{
	OFSafeRelease(addedContacts);
	OFSafeRelease(selectedContacts);
	[super dealloc];
}

+ (OFSelectContactsToInviteController*)inviteController:(OFSelectInviteTypeController*)_inviteTypeController withAlreadyAddedContacts:(NSArray*)added withAlreadySelectedContacts:(NSArray*)selected;
{
	OFSelectContactsToInviteController* controller = (OFSelectContactsToInviteController*)OFControllerLoader::load(@"SelectContactsToInvite");
	controller.title = @"Invite Contacts";
	controller.inviteTypeController = _inviteTypeController;
	
	UIBarButtonItem* right = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:controller action:@selector(done)]; 
	controller.navigationItem.rightBarButtonItem = right;
	[right release];
	
	controller.navigationItem.hidesBackButton = YES;
	
	controller.addedContacts = [[[NSMutableArray alloc] initWithArray:added] autorelease];
	controller.selectedContacts = [[[NSMutableArray alloc] initWithArray:selected] autorelease];
	
	return controller;
}

@end
