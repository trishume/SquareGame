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

#import "OFTableStaticControllerHelper.h"

@class OFSelectInviteTypeHeaderController;
@class OFInviteDefinition;
@class OFSelectInviteTypeCell;

enum ESelectedPersonType
{
	ESelectedPersonType_FEINT_FRIEND = 0,
	ESelectedPersonType_CONTACT,
	ESelectedPersonType_COUNT,
};

@interface OFSelectInviteTypeController : OFTableStaticControllerHelper 
{
	NSString* inviteId;
	OFSelectInviteTypeHeaderController* mHeader;
	OFInviteDefinition* mDefinition;
	
	NSMutableArray* selected[ESelectedPersonType_COUNT];
	OFSelectInviteTypeCell* cells[ESelectedPersonType_COUNT];
	
	NSArray* addedContacts;
}

@property (nonatomic, retain) NSString* inviteId;
@property (nonatomic, retain) NSArray* addedContacts;

//Pass nil to get the primary invite definition
+ (OFSelectInviteTypeController*)inviteTypeControllerWithInviteIdentifier:(NSString*)inviteId;

- (void) updateSelectedType:(ESelectedPersonType)ePersonType with:(NSArray*)peopleSelected;
- (NSArray*) getSelectedListForType:(ESelectedPersonType)ePersonType;

- (void)openAsModal;
- (void)openAsModalInDashboard;

@end
