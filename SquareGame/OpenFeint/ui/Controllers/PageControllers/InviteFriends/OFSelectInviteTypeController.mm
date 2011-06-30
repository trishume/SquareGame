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

#import "OFSelectInviteTypeController.h"
#import "OFSelectInviteTypeCell.h"
#import "OFControllerLoader.h"
#import "OFImageLoader.h"
#import "OFTableSectionDescription.h"
#import "OFInviteService.h"
#import "OFSelectFriendsToInviteController.h"
#import "OFSelectInviteTypeHeaderController.h"
#import "OFSelectContactsToInviteController.h"
#import "OFInviteDefinition.h"
#import "OFImageView.h"
#import "OpenFeint.h"
#import "OpenFeint+Private.h"
#import "OFFramedNavigationController.h"
#import "OFInviteFriendsController.h"
#import "UINavigationController+OpenFeint.h"
#import "NSInvocation+OpenFeint.h"

@interface OFSelectInviteTypeController (Private)
- (void) updateCell:(OFSelectInviteTypeCell*)cell withSelectedCount:(uint)count;
- (void) didGetInviteDefinition:(OFPaginatedSeries*)resources;
- (void) didFailGetInviteDefinition;
@end


@implementation OFSelectInviteTypeController

@synthesize inviteId, addedContacts;

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	//By this time we know our header at least exists, lets make the call to download the definition now.
	[self showLoadingScreen];
	
	OFDelegate success = OFDelegate(self, @selector(didGetInviteDefinition:));
	OFDelegate failure = OFDelegate(self, @selector(didFailGetInviteDefinition));
	
	//If this is not set, then they want the primary invite definition
	if(!self.inviteId)
	{
		[OFInviteService getDefaultInviteDefinitionForApplication:success 
														onFailure:failure];
	}
	else
	{
		[OFInviteService getInviteDefinition:self.inviteId
								   onSuccess:success 
								   onFailure:failure];
	}
}

+ (OFSelectInviteTypeController*)inviteTypeControllerWithInviteIdentifier:(NSString*)inviteId
{
	OFSelectInviteTypeController* controller = (OFSelectInviteTypeController*)OFControllerLoader::load(@"SelectInviteType");
	controller.title = @"Invite";
	
	UIBarButtonItem* right = [[UIBarButtonItem alloc] initWithTitle:@"Invite" style:UIBarButtonItemStylePlain target:controller action:@selector(advance)];
	controller.navigationItem.rightBarButtonItem = right;
	[right release];
	
	//If the string is empty, leave the inviteId as default - or nil value.
	if(![inviteId isEqualToString:@""])
	{
		controller.inviteId = inviteId;
	}
	
	return controller;
}

- (void)openAsModal
{
	UIBarButtonItem* left = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:[OpenFeint class] action:@selector(dismissDashboard)];
	self.navigationItem.leftBarButtonItem = left;
	[left release];
	OFFramedNavigationController* navController = [[[OFFramedNavigationController alloc] initWithRootViewController:self] autorelease];
	
	[OpenFeint presentRootControllerWithModal:navController];
}

- (void)openAsModalInDashboard
{
	UIBarButtonItem* left = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
	self.navigationItem.leftBarButtonItem = left;
	[left release];
	OFFramedNavigationController* navController = [[[OFFramedNavigationController alloc] initWithRootViewController:self] autorelease];
	
	[[OpenFeint getRootController] presentModalViewController:navController animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	OFTableSectionDescription* tableDescription = (OFTableSectionDescription*)[mSections objectAtIndex:section];
	tableDescription.headerView = [self createPlainTableSectionHeader:section];
	return tableDescription.headerView;
}

- (void) createCell:(NSMutableArray*)cellArray withType:(ESelectedPersonType)ePersonType withTitle:(NSString*)cellTitle andIconName:(NSString*)iconName andCreateSelector:(SEL)createSelector
{
	OFSelectInviteTypeCell* curCell = (OFSelectInviteTypeCell*)OFControllerLoader::loadCell(@"SelectInviteType");
	curCell.titleLabel.text = cellTitle;
	curCell.createControllerSelector = createSelector;
	curCell.iconView.image = iconName ? [OFImageLoader loadImage:iconName] : nil;
	[self updateCell:curCell withSelectedCount:0];
	
	OFAssert(ePersonType < ESelectedPersonType_COUNT, "Invalid enum type passed in to OFSelectInviteTypeController::createCell");
	cells[ePersonType] = curCell;
    
	[cellArray addObject:curCell];
}

- (NSMutableArray*) buildTableSectionDescriptions
{
	NSMutableArray* staticCells = [NSMutableArray arrayWithCapacity:2];
	
	[self createCell:staticCells withType:ESelectedPersonType_FEINT_FRIEND withTitle:@"Feint Friends" andIconName:@"OFSelectInviteTypeLeaf.png" andCreateSelector:@selector(inviteOpenFeintFriends)];
	[self createCell:staticCells withType:ESelectedPersonType_CONTACT withTitle:@"Contacts" andIconName:@"OFSelectInviteTypePhone.png" andCreateSelector:@selector(inviteContacts)];
	
	NSMutableArray* sections = [NSMutableArray arrayWithObject:[OFTableSectionDescription sectionWithTitle:@"Select Friends To Invite" andStaticCells:staticCells]];
	return sections;
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([mSections count] > 0)
	{
		NSMutableArray* staticCells = [[mSections objectAtIndex:0] staticCells];
		if (indexPath.row < [staticCells count])
		{
			OFSelectInviteTypeCell* cell = [staticCells objectAtIndex:indexPath.row];
			[self performSelector:cell.createControllerSelector];
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		}
	}
}

- (void)inviteOpenFeintFriends
{
	OFSelectFriendsToInviteController* controller = [OFSelectFriendsToInviteController inviteController:self withAlreadySelectedUsers:selected[ESelectedPersonType_FEINT_FRIEND]];
	[self.navigationController pushViewController:controller animated:YES];
}

- (void)inviteContacts
{
	
	OFSelectContactsToInviteController* controller = [OFSelectContactsToInviteController inviteController:self withAlreadyAddedContacts:addedContacts withAlreadySelectedContacts:selected[ESelectedPersonType_CONTACT]];
	[self.navigationController pushViewController:controller animated:YES];
}

- (void)advance
{
	if ([selected[ESelectedPersonType_FEINT_FRIEND] count] == 0 && [selected[ESelectedPersonType_CONTACT] count] == 0)
	{
		[[[[UIAlertView alloc] initWithTitle:@"No Friends Selected" 
									 message:@"You must select at least one friend to invite." 
									delegate:nil 
						   cancelButtonTitle:@"OK" 
						   otherButtonTitles:nil] autorelease] show];
		
	}
	else
	{
		uint capacity = 0;
		for(uint i = 0; i < ESelectedPersonType_COUNT; i++)
		{
			capacity += [selected[i] count];
		}
		
		NSMutableArray* allSelected = [[[NSMutableArray alloc] initWithCapacity:capacity] autorelease];
		
		for(uint i = 0; i < ESelectedPersonType_COUNT; i++)
		{
			[allSelected addObjectsFromArray:selected[i]];
		}
		
		OFInviteFriendsController* controller = (OFInviteFriendsController*)OFControllerLoader::load(@"InviteFriends");
		controller.selectedUsers = allSelected;
		controller.definition = mDefinition;
		
		// This is kind of crappy.  Copy our close button's behavior (which is set by how we're opened)
		// and let the new controller know how to close.
		if (self.navigationItem.leftBarButtonItem)
		{
			//Note: This code maybe dead - I'm not sure if any creators of this controller make a left button
			//but incase they do I'm not going to take this code out [Phil 7/10]
			SEL selector = self.navigationItem.leftBarButtonItem.action;
			id target = self.navigationItem.leftBarButtonItem.target;
			
			controller.closeInvocation = [NSInvocation invocationWithTarget:target andSelector:selector];
		}
		else
		{
			NSInvocation* invocation = nil;
			
			// do we have a parent?
			UIViewController* parent = [self.navigationController previousViewController:self];
			BOOL animated = YES;
			
			if (parent)
			{
				invocation = [NSInvocation invocationWithTarget:self.navigationController
													andSelector:@selector(popToViewController:animated:)
												   andArguments:&parent, &animated];
			}
			else
			{
				// If we have no parent, we should pop to root.
				invocation = [NSInvocation invocationWithTarget:self.navigationController
													andSelector:@selector(popToRootViewControllerAnimated:)
												   andArguments:&animated];
			}
			
			controller.closeInvocation = invocation;			
		}
		
		[self.navigationController pushViewController:controller animated:YES];
	}
}

// --------------------------------------------------------
// OFTableControllerHelper+Overridables
- (NSString*)getTableHeaderControllerName
{
	//Rename this
	return @"SelectInviteTypeHeader";
}

- (void)onTableHeaderCreated:(UIViewController*)tableHeader
{
	mHeader = (OFSelectInviteTypeHeaderController*)tableHeader;
	
	// clear out definition-dependent UI in case we haven't downloaded the definition yet
	mHeader.enticeLabel.text = @"";
}
// --------------------------------------------------------

- (void) updateSelectedType:(ESelectedPersonType)ePersonType with:(NSArray*)peopleSelected
{
	OFSafeRelease(selected[ePersonType]);
	selected[ePersonType] = [[NSMutableArray alloc] initWithArray:peopleSelected];
	[self updateCell:cells[ePersonType] withSelectedCount:[selected[ePersonType] count]];
}

- (NSArray*) getSelectedListForType:(ESelectedPersonType)ePersonType
{
	return selected[ePersonType];
}

- (void) updateCell:(OFSelectInviteTypeCell*)cell withSelectedCount:(uint)count
{
	cell.amountSelectedLabel.text = [NSString stringWithFormat:@"%d Friends Selected", count];
}

- (void) didGetInviteDefinition:(OFPaginatedSeries*)resources
{
	if ([resources count] > 0)
	{
		[self hideLoadingScreen];
		OFSafeRelease(mDefinition);
		mDefinition = [[resources.objects objectAtIndex:0] retain];
		
		//Get the image downloading
		if(mDefinition.inviteIconURL && ![mDefinition.inviteIconURL isEqualToString:@""])
		{
			mHeader.inviteIcon.imageUrl = mDefinition.inviteIconURL;
		}
		
		mHeader.enticeLabel.text = mDefinition.senderIncentiveText;
	}
	else
	{
		[self didFailGetInviteDefinition];
	}
}

- (void) didFailGetInviteDefinition
{
	[self hideLoadingScreen];
}

- (void)dealloc
{
	for(int i = 0; i < ESelectedPersonType_COUNT; i++)
	{
		OFSafeRelease(selected[i]);
	}
	
	OFSafeRelease(inviteId);
	OFSafeRelease(mDefinition);
	OFSafeRelease(addedContacts);
	[super dealloc];
}

@end
