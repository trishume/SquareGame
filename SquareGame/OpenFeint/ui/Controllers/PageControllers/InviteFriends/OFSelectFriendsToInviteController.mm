////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009 Aurora Feint, Inc.
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

#import "OFDependencies.h"
#import "OFSelectFriendsToInviteController.h"
#import "OFResourceControllerMap.h"
#import "OFFriendsService.h"
#import "OFUser.h"
#import "OFSelectableUserCell.h"
#import "OFTableSectionDescription.h"
#import "OpenFeint+UserOptions.h"
#import "OpenFeint+Settings.h"
#import "OpenFeint+Private.h"
#import "OFControllerLoader.h"
#import "OFUsersCredential.h"
#import "OFFullScreenImportFriendsMessage.h"
#import "OFChallengeDelegate.h"
#import "OFChallengeService+Private.h"
#import "OFChallenge.h"
#import "OFDefaultTextField.h"
#import "OFReachability.h"
#import "OFTableControllerHelper+Overridables.h"
#import "OFTableSequenceControllerHelper+ViewDelegate.h"
#import "OFTableSequenceControllerHelper+Overridables.h"
#import "OFInviteService.h"
#import "OFInviteDefinition.h"
#import "OFDeadEndErrorController.h"
#import "OFFramedNavigationController.h"
#import "OFSelectInviteTypeController.h"

uint kUserNotSelected = -1;

@interface OFSelectFriendsToInviteController ()

- (void) _refreshData;
- (void) _refreshDataNow;
- (uint) _userIsAtSelectedIndex:(OFUser*)user;

@end

@implementation OFSelectFriendsToInviteController

@synthesize inviteTypeController, selectedUsers;

// Loading screen is shown when (definitionDownloadOutstanding||friendsDownloadOutstanding),
// so we need to make sure we only hide it when both are false.
- (void)hideLoadingScreen
{
	if(!friendsDownloadOutstanding && !anyFriendsDownloadOutstanding)
	{
		[super hideLoadingScreen];
	}
}

// Make sure we set friendsDownloadOutstanding before trying to hide the loading screen.
- (void)_onDataLoadedWrapper:(OFPaginatedSeries*)resources isIncremental:(BOOL)isIncremental
{
	friendsDownloadOutstanding = NO;
	[super _onDataLoadedWrapper:resources isIncremental:isIncremental];
}

- (void)populateResourceMap:(OFResourceControllerMap*)resourceMap
{
	resourceMap->addResource([OFUser class], @"SelectableUser");
}

- (OFService*)getService
{
	return [OFFriendsService sharedInstance];
}

- (void)doIndexActionWithPage:(NSUInteger)pageIndex onSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure
{
	friendsDownloadOutstanding = YES;
	[OFFriendsService getInvitableFriends:pageIndex onSuccess:success onFailure:failure];
}

- (void)doIndexActionOnSuccess:(const OFDelegate&)success onFailure:(const OFDelegate&)failure;
{
	[self doIndexActionWithPage:1 onSuccess:success onFailure:failure];
    stallNextRefresh = YES;
}

- (bool)autoLoadData
{
	return false;
}

- (UIViewController*)getNoDataFoundViewController
{
	// @DANGER : if modal then we might have two modals?
    OFFullScreenImportFriendsMessage* noDataController = (OFFullScreenImportFriendsMessage*)OFControllerLoader::load(@"HeaderedFullscreenImportFriendsMessage");
	if (followingAnyone)
	{
		noDataController.messageLabel.text = [NSString stringWithFormat:OFLOCALSTRING(@"All of your friends have %@. You can make more friends by importing them from Facebook or Twitter or find friends by their OpenFeint name."), [OpenFeint applicationDisplayName]];
	}
	
    noDataController.owner = self;
    return noDataController;
}

- (NSString*)getNoDataFoundMessage
{
	// We don't actually use this, but if we don't override it, we'll crash.
	return @"";
}

- (NSString*)getDataNotLoadedYetMessage
{
	// This isn't used with the getNoDataFoundViewController - this is actually what shows while we're getting the invite definition.
	return OFLOCALSTRING(@"Loading Invitation...");
}

- (void)localUserFollowingAnyoneFail
{
	anyFriendsDownloadOutstanding = NO;
	[self hideLoadingScreen];
}

- (void)localUserFollowingAnyone:(NSNumber*)_followingAnyone
{
	anyFriendsDownloadOutstanding = NO;
	[self hideLoadingScreen];
	followingAnyone = [_followingAnyone boolValue];
	[self _refreshData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self showLoadingScreen];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// @TODO: we don't want to reload friends if we're just coming back from the send invite controller, but since we are,
	// let's not have our list of friends be inconsistent with the selected set.  To be fixed.
	//OFSafeRelease(selectedUsers);
	
	// Also, does user have any friends?
	[OFFriendsService isLocalUserFollowingAnyone:OFDelegate(self, @selector(localUserFollowingAnyone:)) onFailure:OFDelegate(self, @selector(localUserFollowingAnyoneFail))];
	anyFriendsDownloadOutstanding = YES;
	
}

- (bool)usePlainTableSectionHeaders
{
	//If we're not following anyone we don't need the table section header
	return true;
}

- (void)onSectionsCreated:(NSMutableArray*)sections
{
	OFTableSectionDescription* firstSection = [sections objectAtIndex:0];
	firstSection.title = OFLOCALSTRING(@"Friends To Invite");
}

- (void)toggleSelectionOfUser:(OFUser*)user
{
	if (selectedUsers == nil)
	{
		selectedUsers = [NSMutableArray new];
	}
	
	NSIndexPath* indexPath = [self getFirstIndexPathForResource:user];
	if (!indexPath)
	{
		return;
	}
	OFSelectableUserCell* userCell = (OFSelectableUserCell*)[self.tableView cellForRowAtIndexPath:indexPath];
	OFUser* userInTable = (OFUser*)[self getResourceAtIndexPath:indexPath]; 
	if (userInTable)
	{
		uint selectedIndex = [self _userIsAtSelectedIndex:userInTable];
		if(selectedIndex != kUserNotSelected)
		{
			userCell.checked = NO;
			[selectedUsers removeObjectAtIndex:selectedIndex];
		}
		else
		{
			userCell.checked = YES;
			[selectedUsers addObject:userInTable];
		}
	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)onCell:(OFTableCellHelper*)cell resourceChanged:(OFResource*)user
{
	if ([cell isKindOfClass:[OFSelectableUserCell class]])
	{
		((OFSelectableUserCell*)cell).checked = [self _userIsAtSelectedIndex:(OFUser*)user] != kUserNotSelected;
	}
}

- (void)onCellWasClicked:(OFResource*)cellResource indexPathInTable:(NSIndexPath*)indexPath
{
	if ([cellResource isKindOfClass:[OFUser class]])
	{
		UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
		if ([cell isKindOfClass:[OFSelectableUserCell class]])
		{	
			[self toggleSelectionOfUser:(OFUser*)cellResource];
		}
	}
}

- (NSString*)getUserMessage:(UITextField*)textField
{
	return (textField.text && ![textField.text isEqualToString:@""]) ? textField.text : textField.placeholder;
}

- (IBAction)cancel
{
	[[OpenFeint getRootController] dismissModalViewControllerAnimated:YES];
}

- (IBAction)done
{
	//Alert the InviteType controller of my selected users and pop myself off the nav view stack
	[inviteTypeController updateSelectedType:ESelectedPersonType_FEINT_FRIEND with:selectedUsers];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// Gotta make sure the loading screen clears
	friendsDownloadOutstanding = NO;
	anyFriendsDownloadOutstanding = NO;
	[super viewWillDisappear:animated];	
}

- (bool)canReceiveCallbacksNow
{
	return true;
}

- (BOOL)shouldAlwaysShowNavBar
{
	return YES;
}

- (void) _refreshData
{
    if (stallNextRefresh)
    {
        [self showLoadingScreen];
        [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(_refreshDataNow) userInfo:nil repeats:NO];
    }
    else
    {
        [self _refreshDataNow];
    }
}

- (void) _refreshDataNow
{
    [super _refreshData];
}

- (uint) _userIsAtSelectedIndex:(OFUser*)user
{	
	for(uint i = 0; i < [selectedUsers count]; i++)
	{
		OFUser* selectedUser = [selectedUsers objectAtIndex:i];
		if([selectedUser.userId isEqualToString:((OFUser*)user).userId])
		{
			return i;
		}
	}
	return kUserNotSelected;
}

- (void)dealloc
{
	OFSafeRelease(inviteTypeController);
	OFSafeRelease(selectedUsers);
	[super dealloc];
}

+ (OFSelectFriendsToInviteController*)inviteController:(OFSelectInviteTypeController*)_inviteTypeController withAlreadySelectedUsers:(NSArray*)selectedUsers
{
	OFSelectFriendsToInviteController* controller = (OFSelectFriendsToInviteController*)OFControllerLoader::load(@"SelectFriendsToInvite");
	controller.title = OFLOCALSTRING(@"Invite Friends");
	controller.inviteTypeController = _inviteTypeController;
	
	UIBarButtonItem* right = [[UIBarButtonItem alloc] initWithTitle:OFLOCALSTRING(@"Done") style:UIBarButtonItemStylePlain target:controller action:@selector(done)]; 
	controller.navigationItem.rightBarButtonItem = right;
	[right release];
	
	controller.navigationItem.hidesBackButton = YES;
	
	controller.selectedUsers = [[[NSMutableArray alloc] initWithArray:selectedUsers] autorelease];
	
	return controller;
}

@end

