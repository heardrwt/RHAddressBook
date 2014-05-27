//
//  RHAddressBookLogicTests.m
//  RHAddressBookLogicTests
//
//  Created by Richard Heard on 13/11/11.
//  Copyright (c) 2011 Richard Heard. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "RHAddressBookLogicTests.h"

#import "AddressBook.h"
#import <objc/runtime.h>

@implementation RHAddressBookLogicTests

-(void)setUp
{
    [super setUp];
    
    // Set-up code here.
    _ab = [[RHAddressBook alloc] init];
    XCTAssertNotNil(_ab, @"Could not create addressbook instance");

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"__IPHONE_OS_VERSION_MIN_REQUIRED = %i", __IPHONE_OS_VERSION_MIN_REQUIRED);
        NSLog(@"__IPHONE_OS_VERSION_MAX_ALLOWED = %i", __IPHONE_OS_VERSION_MAX_ALLOWED);
        NSLog(@"CURRENT VERSION = %@", [[UIDevice currentDevice] systemVersion]);
    });
}

-(void)tearDown
{
    // Tear-down code here.    
    [_ab release];
    _ab = nil;
    [super tearDown];
}

#pragma mark - addressbook
-(void)testSaving{

    //init
    [_ab revert];
    XCTAssertFalse([_ab hasUnsavedChanges], @"AB reports it has unsaved changes after a revert");

    
    //setup 
    NSUInteger groupsCount = [[_ab groups] count];
    NSUInteger peopleCount = [[_ab people] count];
    NSError *error = nil;

    
    
    //===== ADD
    
    //add group
    RHGroup *newGroup = [_ab newGroupInDefaultSource];
    newGroup.name = @"Unit Test GroupD";
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.1 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"7.1.0")) {
        XCTAssertTrue(groupsCount + 1 == [[_ab groups] count], @"groups count failed to increment pre save");
        XCTAssertTrue([[_ab groups] containsObject:newGroup], @"new group not in array of groups");
    }
    //add person
    RHPerson *newPerson = [_ab newPersonInDefaultSource];
    NSDictionary *personDict = [self randomPersonDictionary];
    [self populateObject:newPerson UsingDictionary:personDict];
    
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.1 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"7.1.0")) {
        XCTAssertTrue(peopleCount + 1 == [[_ab people] count], @"people count failed to increment pre save");
        XCTAssertTrue([[_ab people] containsObject:newPerson], @"new person not in array of people");
    }

    XCTAssertTrue([_ab hasUnsavedChanges], @"AB reports it does not have unsaved changes");
    
    //save
    error = nil;
    XCTAssertTrue([_ab saveWithError:&error], @"AB save returned false");
    XCTAssertNil(error, @"error was set by the AB save operation");
    
    //test
    XCTAssertTrue(groupsCount + 1 == [[_ab groups] count], @"groups count failed to increment post save");
    XCTAssertTrue(peopleCount + 1 == [[_ab people] count], @"people count failed to increment post save");

    //===== REMOVE

    
    //remove group
    error = nil;
    XCTAssertTrue([_ab removeGroup:newGroup error:&error], @"AB remove group returned false");
    XCTAssertNil(error, @"error was set by the AB remove group operation");
    XCTAssertTrue(groupsCount == [[_ab groups] count], @"groups count failed to decrement pre save");
    XCTAssertFalse([[_ab groups] containsObject:newGroup], @"removed group should not be in array of groups");

    //remove person
    error = nil;
    XCTAssertTrue([_ab removePerson:newPerson error:&error], @"AB remove person returned false");
    XCTAssertNil(error, @"error was set by the AB remove person operation");
    XCTAssertTrue(peopleCount == [[_ab people] count], @"person count failed to decrement pre save");
    XCTAssertFalse([[_ab people] containsObject:newPerson], @"removed person should not be in array of people");

    XCTAssertTrue([_ab hasUnsavedChanges], @"AB reports it does not have unsaved changes");

    //save
    error = nil;
    XCTAssertTrue([_ab saveWithError:&error], @"AB save returned false");
    XCTAssertNil(error, @"error was set by the AB save operation");
    
    //test
    XCTAssertTrue(groupsCount == [[_ab groups]count], @"groups count failed to decrement post save");
    XCTAssertTrue(peopleCount == [[_ab people] count], @"people count failed to decrement post save");

    //===== misc
    
    //attempt to remove the already removed group and person. 
    // this should not explode / be mean...

    //remove group
    error = nil;
    XCTAssertTrue([_ab removeGroup:newGroup error:&error], @"AB remove already removed group returned false");
    XCTAssertNil(error, @"error was set by the AB remove  already removed group operation");
    XCTAssertTrue(groupsCount == [[_ab groups] count], @"groups count changed when removing an already removed group");
    XCTAssertFalse([[_ab groups] containsObject:newGroup], @"removed group should not be in array of groups");

    //remove person
    error = nil;
    XCTAssertTrue([_ab removePerson:newPerson error:&error], @"AB remove  already removed person returned false");
    XCTAssertNil(error, @"error was set by the AB remove  already removed person operation");
    XCTAssertTrue(peopleCount == [[_ab people] count], @"people count changed when removing an already removed group");
    XCTAssertFalse([[_ab people] containsObject:newPerson], @"removed person should not be in array of people");

    //save
    error = nil;
    XCTAssertTrue([_ab saveWithError:&error], @"AB save returned false");
    XCTAssertNil(error, @"error was set by the AB save operation");

    
    //test saving with no changes.
    XCTAssertFalse([_ab hasUnsavedChanges], @"AB reports it does has unsaved changes after a save");
    
    error = nil;
    XCTAssertTrue([_ab saveWithError:&error], @"AB save returned false");
    XCTAssertNil(error, @"error was set by the AB save operation");
    

    
    //cleanup
    [newGroup release];
    [newPerson release];
    
    
}


-(void)testReverting{
    //init
    [_ab revert];
    XCTAssertFalse([_ab hasUnsavedChanges], @"AB reports it has unsaved changes after a revert");
    
    
    //setup 
    NSUInteger groupsCount = [[_ab groups] count];
    NSUInteger peopleCount = [[_ab people] count];
    NSError *error = nil;

    
    //===== Revert additions
    
    //add group
    RHGroup *newGroup = [_ab newGroupInDefaultSource];
    newGroup.name = @"Unit Test GroupE";
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.1 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"7.1.0")) {
        XCTAssertTrue(groupsCount + 1 == [[_ab groups] count], @"groups count failed to increment pre revert");
        XCTAssertTrue([[_ab groups] containsObject:newGroup], @"new group not in array of groups");
    }    
    //add person
    RHPerson *newPerson = [_ab newPersonInDefaultSource];
    NSDictionary *personDict = [self randomPersonDictionary];
    [self populateObject:newPerson UsingDictionary:personDict];
    
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.1 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"7.1.0")) {
        XCTAssertTrue(peopleCount + 1 == [[_ab people] count], @"people count failed to increment pre revert");
        XCTAssertTrue([[_ab people] containsObject:newPerson], @"new person not in array of people");
    }
    
    XCTAssertTrue([_ab hasUnsavedChanges], @"AB reports it does not have unsaved changes after adding a person and group");
    
    //revert
    [_ab revert];

    XCTAssertFalse([_ab hasUnsavedChanges], @"AB reports has unsaved changes after adding a person and group then reverting");


    //test
    XCTAssertTrue(groupsCount == [[_ab groups] count], @"groups count changed post revert");
    XCTAssertTrue(peopleCount == [[_ab people] count], @"people count changed post revert");
    XCTAssertFalse([[_ab groups] containsObject:newGroup], @"new group should not be in array of groups after revert");
    XCTAssertFalse([[_ab people] containsObject:newPerson], @"new person should not be in array of people after revert");

    
    
    
    //===== REMOVE
        
    
    [_ab addGroup:newGroup];
    [_ab addPerson:newPerson];
    error = nil;
    XCTAssertTrue([_ab saveWithError:&error], @"AB save returned false");
    XCTAssertNil(error, @"error was set by the AB save operation");
    XCTAssertFalse([_ab hasUnsavedChanges], @"AB reports has unsaved changes after adding a person and group then saving");
    XCTAssertTrue([[_ab groups] containsObject:newGroup], @"new group should be in array of groups after addGroup: operation");
    XCTAssertTrue([[_ab people] containsObject:newPerson], @"new person should be in array of people after addPerson: operation");

    
    
    //setup counts
    groupsCount = [[_ab groups] count];
    peopleCount = [[_ab people] count];
    


    //remove group
    error = nil;
    XCTAssertTrue([_ab removeGroup:newGroup error:&error], @"AB remove group returned false");
    XCTAssertNil(error, @"error was set by the AB remove group operation");
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 5.0 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"5.0")) {
        XCTAssertTrue(groupsCount - 1 == [[_ab groups] count], @"groups count failed to decrement pre revert");
        XCTAssertFalse([[_ab groups] containsObject:newGroup], @"new group should not be in array of groups after removeGroup: operation");
    }
    
    //remove person
    error = nil;
    XCTAssertTrue([_ab removePerson:newPerson error:&error], @"AB remove person returned false");
    XCTAssertNil(error, @"error was set by the AB remove person operation");
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 5.0 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"5.0")) {
        XCTAssertTrue(peopleCount - 1 == [[_ab people] count], @"person count failed to decrement pre revert");
        XCTAssertFalse([[_ab people] containsObject:newPerson], @"new person not be in array of people after removePerson: operation");
    }
    XCTAssertTrue([_ab hasUnsavedChanges], @"AB reports it does not have unsaved changes");

    //revert
    [_ab revert];
    
    XCTAssertFalse([_ab hasUnsavedChanges], @"AB reports it has unsaved changes after reverting a person and group delete");
    
    
    //test
    XCTAssertTrue(groupsCount == [[_ab groups] count], @"groups count changed post revert");
    XCTAssertTrue(peopleCount == [[_ab people] count], @"people count changed post revert");
    XCTAssertTrue([[_ab groups] containsObject:newGroup], @"new group should be in array of groups after revert");
    XCTAssertTrue([[_ab people] containsObject:newPerson], @"new person should be in array of people after revert");


    //cleanup
    //remove group
    error = nil;
    XCTAssertTrue([_ab removeGroup:newGroup error:&error], @"AB remove group returned false");
    XCTAssertNil(error, @"error was set by the AB remove group operation");
    XCTAssertTrue(groupsCount - 1 == [[_ab groups] count], @"failed to remove test group");
    
    //remove person
    error = nil;
    XCTAssertTrue([_ab removePerson:newPerson error:&error], @"AB remove  already removed person returned false");
    XCTAssertNil(error, @"error was set by the AB remove  already removed person operation");
    XCTAssertTrue(peopleCount - 1 == [[_ab people] count], @"people count changed when removing an already removed group");

    
    //save
    error = nil;
    XCTAssertTrue([_ab saveWithError:&error], @"AB save returned false");
    XCTAssertNil(error, @"error was set by the AB save operation");
    
    
    //make sure we have no unsaved changes
    XCTAssertFalse([_ab hasUnsavedChanges], @"AB reports it does has unsaved changes after a save");

    //cleanup
    [newGroup release];
    [newPerson release];

}

-(void)testUnsavedChanges{
    XCTAssertFalse([_ab hasUnsavedChanges], @"AB reports it has unsaved changes");
    //This is mostly covered in the save and revert comprehensive tests
    
}

-(void)testForRecordRefMethods{
    //setup
    //add group
    RHGroup *newGroup = [_ab newGroupInDefaultSource];
    newGroup.name = @"Unit Test GroupF";
  
    //add person
    RHPerson *newPerson = [_ab newPersonInDefaultSource];
    NSDictionary *personDict = [self randomPersonDictionary];
    [self populateObject:newPerson UsingDictionary:personDict];
    
    XCTAssertTrue([_ab hasUnsavedChanges], @"AB reports it does not have unsaved changes after adding a person and group");
    
    
    //test pre-save refs
    XCTAssertTrue([newGroup isEqual:[_ab groupForABRecordRef:newGroup.recordRef]], @"group for unsaved groupRef did not match");
    XCTAssertTrue([newPerson isEqual:[_ab personForABRecordRef:newPerson.recordRef]], @"person for unsaved personRef did not match");
    
    
    [_ab save];
    
    //test post-save refs
    XCTAssertTrue([newGroup isEqual:[_ab groupForABRecordRef:newGroup.recordRef]], @"group for saved groupRef did not match");
    XCTAssertTrue([newPerson isEqual:[_ab personForABRecordRef:newPerson.recordRef]], @"person for saved personRef did not match");
    
    //negative tests (personRef from another addressbook should not have their objects match)
    RHAddressBook *_ab2 = [[RHAddressBook alloc] init];
    XCTAssertFalse([newGroup isEqual:[_ab2 groupForABRecordRef:newGroup.recordRef]], @"group for saved groupRef in another ab did match");
    XCTAssertFalse([newPerson isEqual:[_ab2 personForABRecordRef:newPerson.recordRef]], @"person for saved personRef in another ab did match");
    
    //but their recordIDs should
    XCTAssertTrue(newGroup.recordID == [_ab2 groupForABRecordRef:newGroup.recordRef].recordID , @"group recordID for saved groupRef in another ab did not match");
    XCTAssertTrue(newPerson.recordID == [_ab2 personForABRecordRef:newPerson.recordRef].recordID, @"person recordID for saved personRef in another ab did not match");
    
    
    //cleanup
    [_ab removeGroup:newGroup];
    [_ab removePerson:newPerson];
    [_ab save];

    [_ab2 release];
    [newGroup release];
    [newPerson release];

}

-(void)testUserPrefs{
    //test sort order
    XCTAssertTrue([RHAddressBook orderByFirstName] != [RHAddressBook orderByLastName], @"order by should never match");

    //test display order
    XCTAssertTrue([RHAddressBook compositeNameFormatFirstNameFirst] != [RHAddressBook compositeNameFormatLastNameFirst], @"display by should never match");

}

-(void)testGroupsAndPeopleFromAnotherAddressBook{
    
    //test adding an existing group and a person to the addressbook
    //we should test to make sure adding addressbook objects from one addressbook fails if attempted to add to another addressbook.

    //setup
    RHAddressBook *_ab2 = [[RHAddressBook alloc] init];
    RHGroup *newGroup = [_ab2 newGroupInDefaultSource];
    newGroup.name = @"Unit Test GroupG";
    RHPerson *newPerson = [_ab2 newPersonInDefaultSource];
    XCTAssertNotNil(newGroup, @"group should not be nil");
    XCTAssertNotNil(newPerson, @"person should not be nil");
    
    //revert to make sure _ab2 no longer refs the _ab
    [_ab2 revert];
    
    //test
    XCTAssertThrows([_ab addPerson:newPerson], @"should prevent adding a person from another ab");
    XCTAssertThrows([_ab addGroup:newGroup], @"should prevent adding a group from another ab");
    
    //cleanup
    [newGroup release];
    [newPerson release];
    [_ab2 release];
    
}

-(void)testPassingNilToPublicMethods{

//TODO: add these methods at some point
//    -(RHSource*)sourceForABRecordRef:(ABRecordRef)sourceRef; //returns nil if ref not found in the current ab, eg unsaved record from another ab. if the passed recordRef does not belong to the current addressbook, the returned person objects underlying personRef will differ from the passed in value. This is required in-order to maintain thread safety for the underlying AddressBook instance.
//    -(NSArray*)groupsInSource:(RHSource*)source;
//    -(RHGroup*)groupForABRecordRef:(ABRecordRef)groupRef; //returns nil if ref not found in the current ab, eg unsaved record from another ab. if the passed recordRef does not belong to the current addressbook, the returned person objects underlying personRef will differ from the passed in value. This is required in-order to maintain thread safety for the underlying AddressBook instance.
//    -(NSArray*)peopleWithName:(NSString*)name;
//    -(RHPerson*)personForABRecordRef:(ABRecordRef)personRef; //returns nil if ref not found in the current ab, eg unsaved record from another ab. if the passed recordRef does not belong to the current addressbook, the returned person objects underlying personRef will differ from the passed in value. This is required in-order to maintain thread safety for the underlying AddressBook instance.
//    
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
//    //add people from vCard to the current addressbook (iOS5+ : pre iOS5 these methods are no-ops)
//    -(NSArray*)addPeopleFromVCardRepresentationToDefaultSource:(NSData*)representation; //returns an array of newly created RHPerson objects, nil on error
//    -(NSArray*)addPeopleFromVCardRepresentation:(NSData*)representation toSource:(RHSource*)source;
//    -(NSData*)vCardRepresentationForPeople:(NSArray*)people;
//#endif //end iOS5+
//
//    -(RHPerson*)newPersonInSource:(RHSource*)source;
//    -(RHGroup*)newGroupInSource:(RHSource*)source;


    XCTAssertFalse([_ab removePerson:nil], @"should log and return NO when passed nil.");
    XCTAssertFalse([_ab removeGroup:nil], @"should log and return NO when passed nil.");
    
    XCTAssertFalse([_ab addPerson:nil], @"should log and return NO when passed nil.");
    XCTAssertFalse([_ab addGroup:nil], @"should log and return NO when passed nil.");
    
}

#pragma mark - sources
-(void)testSources{
    //sources are static on the device, so we just test to make sure we get atleast one back.
    NSArray *sources = [_ab sources];
    XCTAssertNotNil(sources, @"sources was nil");
    XCTAssertTrue([sources count] > 0, @"empty sources array");    
 
    //validate default source is one of the returned sources
    XCTAssertTrue([sources containsObject:[_ab defaultSource]], @"default source not in returned sources");

    RHSource *source = [sources lastObject];
    
    XCTAssertTrue([source isKindOfClass:[RHSource class]], @"source is not of class source");
    
    //test source name and type
    XCTAssertNoThrow([source name], @"source name threw exception");
    XCTAssertNoThrow([source type], @"source type threw exception");
    
    
    
    //test groups
    XCTAssertTrue([[source groups] isEqualToArray:[_ab groupsInSource:source]], @"groups array for source and from _ab are different");
        
    //test people accessors
    XCTAssertNotNil([source people]);
    XCTAssertNotNil([source peopleOrderedBySortOrdering:kABPersonSortByFirstName]);
    XCTAssertNotNil([source peopleOrderedBySortOrdering:kABPersonSortByLastName]);
    XCTAssertNotNil([source peopleOrderedByFirstName]);
    XCTAssertNotNil([source peopleOrderedByLastName]);
    XCTAssertNotNil([source peopleOrderedByUsersPreference]);
    

    //test the pass through methods on RHSource
    RHGroup *newGroup = [source newGroup];
    newGroup.name = @"Unit Test GroupH";
    XCTAssertNotNil(newGroup);
    [newGroup release];
    
    RHPerson *newPerson = [source newPerson];
    XCTAssertNotNil(newPerson);
    [newPerson release];
    
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
    //vcard
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
        XCTAssertNotNil([source vCardRepresentationForPeople]);
    }    
#endif //end iOS5+
    
    
    //cleanup
    [_ab revert];
    
}


#pragma mark - groups
-(void)testGroups{

    XCTAssertNotNil([_ab groups], @"groups should return an array");
    XCTAssertNotNil([_ab groupsInSource:[_ab defaultSource]], @"groups should return an array");
    XCTAssertNotNil([[_ab defaultSource] groups], @"groups should return an array");
    
    
    RHGroup *newGroup = [_ab newGroupInDefaultSource];
    newGroup.name = @"Unit Test GroupI";

    //pre save 
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.1 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"7.1")) {
        XCTAssertTrue([[_ab groups] containsObject:newGroup], @"array should contain newGroup");
        XCTAssertTrue([[_ab groupsInSource:[_ab defaultSource]] containsObject:newGroup], @"array should contain newGroup");
        XCTAssertTrue([[[_ab defaultSource] groups] containsObject:newGroup], @"array should contain newGroup");
    }

    //save
    XCTAssertTrue([_ab save], @"save ab should return true");
    
    //post save
    XCTAssertTrue([[_ab groups] containsObject:newGroup], @"array should contain newGroup");
    XCTAssertTrue([[_ab groupsInSource:[_ab defaultSource]] containsObject:newGroup], @"array should contain newGroup");
    XCTAssertTrue([[[_ab defaultSource] groups] containsObject:newGroup], @"array should contain newGroup");


    //test removing group
    XCTAssertTrue([_ab removeGroup:newGroup], @"removeGroup should return true");

    //pre save 
    XCTAssertFalse([[_ab groups] containsObject:newGroup], @"array should not contain newGroup");
    XCTAssertFalse([[_ab groupsInSource:[_ab defaultSource]] containsObject:newGroup], @"array should contain newGroup");
    XCTAssertFalse([[[_ab defaultSource] groups] containsObject:newGroup], @"array should contain newGroup");
    
    //revert revert
    [_ab revert];
    
    XCTAssertTrue([[_ab groups] containsObject:newGroup], @"array should contain newGroup");
    XCTAssertTrue([[_ab groupsInSource:[_ab defaultSource]] containsObject:newGroup], @"array should contain newGroup");
    XCTAssertTrue([[[_ab defaultSource] groups] containsObject:newGroup], @"array should contain newGroup");

    
    //try again 
    [_ab removeGroup:newGroup];

    //save
    XCTAssertTrue([_ab save], @"save ab should return true");
    
    //post save
    XCTAssertFalse([[_ab groups] containsObject:newGroup], @"array should not contain newGroup");
    XCTAssertFalse([[_ab groupsInSource:[_ab defaultSource]] containsObject:newGroup], @"array should not contain newGroup");
    XCTAssertFalse([[[_ab defaultSource] groups] containsObject:newGroup], @"array should not contain newGroup");
    
    //cleanup
    [newGroup release];
    
}

-(void)testGroupProperties{
    RHGroup *newGroup = [_ab newGroupInDefaultSource];
    NSString *newName = @"Unit Test GroupJ";

    //test name
    XCTAssertNoThrow(newGroup.name = newName, @"setting name should not throw an exception");
    XCTAssertTrue([newGroup.name isEqualToString:newName], @"name should match");
    
    //test source 
    XCTAssertTrue(newGroup.source == [_ab defaultSource], @"should be part of the default source");

    //test count
    XCTAssertTrue(newGroup.count == 0, @"group should be empty");
    
    //cleanup
    [_ab removeGroup:newGroup];
    [newGroup release];

    [_ab save];
}

-(void)testGroupForABRecordRefMethod{

    //need to make sure that we always get a valid result returned for all the edge cases to do with the weak cache and adding and reverting groups additions and removals
    
    //create a new group
    RHGroup *newGroup = [_ab newGroupInDefaultSource];  
    newGroup.name = @"Unit Test GroupA";
    XCTAssertTrue([_ab groupForABRecordRef:newGroup.recordRef] == newGroup, @"groupobject should be returned from the cache for the given recordRef");
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.1 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"7.1.0")) {
        XCTAssertTrue([[_ab groups] containsObject:newGroup], @"array should contain newGroup");
    }
    
    //revert the addition
    [_ab revert];
    XCTAssertTrue([_ab groupForABRecordRef:newGroup.recordRef] == newGroup, @"groupobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab groupForABRecordID:newGroup.recordID] == nil, @"groupobject should not be returned from the cache for the given recordID");
    XCTAssertFalse([[_ab groups] containsObject:newGroup], @"array should not contain newGroup");
    
    // re-add the group 
    XCTAssertTrue([_ab addGroup:newGroup], @"add group should return true");
    XCTAssertTrue([_ab groupForABRecordRef:newGroup.recordRef] == newGroup, @"groupobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab groupForABRecordID:newGroup.recordID] == nil, @"groupobject should not be returned from the cache for the given recordID");
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.1 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"7.1.0")) {
        XCTAssertTrue([[_ab groups] containsObject:newGroup], @"array should contain newGroup");
     }
    
    //save
    XCTAssertTrue([_ab save], @"save ab should return true");
    XCTAssertTrue([_ab groupForABRecordRef:newGroup.recordRef] == newGroup, @"groupobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab groupForABRecordID:newGroup.recordID] == newGroup, @"groupobject should be returned from the cache for the given recordID");
    XCTAssertTrue([[_ab groups] containsObject:newGroup], @"array should contain newGroup");
    
    // remove group 
    //?? should the group be in the cache at this point? i think yes... they wont actually be vended because the ab methods wont return their recordRef
    XCTAssertTrue([_ab removeGroup:newGroup], @"remove group should return true");
    XCTAssertTrue([_ab groupForABRecordRef:newGroup.recordRef] == newGroup, @"groupobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab groupForABRecordID:newGroup.recordID] == nil, @"groupobject should not be returned from the cache for the given recordID");
    XCTAssertFalse([[_ab groups] containsObject:newGroup], @"array should not contain newGroup");
    
    //revert removal 
    [_ab revert];
    XCTAssertTrue([_ab groupForABRecordRef:newGroup.recordRef] == newGroup, @"groupobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab groupForABRecordID:newGroup.recordID] == newGroup, @"groupobject should be returned from the cache for the given recordID");
    XCTAssertTrue([[_ab groups] containsObject:newGroup], @"array should contain newGroup");
    
    // remove again 
    XCTAssertTrue([_ab removeGroup:newGroup], @"remove group should return true");
    XCTAssertTrue([_ab groupForABRecordRef:newGroup.recordRef] == newGroup, @"groupobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab groupForABRecordID:newGroup.recordID] == nil, @"groupobject should not be returned from the cache for the given recordID");
    XCTAssertFalse([[_ab groups] containsObject:newGroup], @"array should not contain newGroup");
    
    //save
    XCTAssertTrue([_ab save], @"save ab should return true");
    XCTAssertFalse([[_ab groups] containsObject:newGroup], @"array should not contain newGroup");
    XCTAssertTrue([_ab groupForABRecordRef:newGroup.recordRef] == newGroup, @"groupobject should still be returned from the cache for the given recordRef, as it has a +1 retain count atm");
    XCTAssertTrue([_ab groupForABRecordID:newGroup.recordID] == nil, @"groupobject should not be returned from the cache for the given recordID");
    
    //we test to make sure the group is removed from the weak cache in the testWeakLinkedCache test
    
    //cleanup
    [_ab removeGroup:newGroup];
    [_ab save];
    [newGroup release];
        
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
#pragma mark - vcards
-(void)testVCardSingleExport{
    //setup
    RHPerson *person = [_ab newPersonInDefaultSource];
    NSDictionary *personDict = [self randomPersonDictionary];
    [self populateObject:person UsingDictionary:personDict];

    //test
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
        XCTAssertTrue([[person vCardRepresentation] length] > 0, @"pre-save vCard Representation was empty data.");
    } else {
        XCTAssertNil([person vCardRepresentation], @"pre-save vCard Representation should be nil when run on less than 5.0.");    
    }
    //save
    [_ab save];

    //test post save
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
        XCTAssertTrue([[person vCardRepresentation] length] > 0, @"post-save vCard Representation was empty data.");
    } else {
        XCTAssertNil([person vCardRepresentation], @"ost-save vCard Representation should be nil when run on less than 5.0.");    
    }
    
    //cleanup
    [_ab removePerson:person];
    [_ab save];

    [person release];
}

-(void)testVCardMultipleExport{
    //setup
    RHPerson *person = [_ab newPersonInDefaultSource];
    RHPerson *person2 = [_ab newPersonInDefaultSource];
    NSDictionary *personDict = [self randomPersonDictionary];
    [self populateObject:person UsingDictionary:personDict];
    [self populateObject:person2 UsingDictionary:personDict];
    
    //test
    NSData *data = [_ab vCardRepresentationForPeople:[NSArray arrayWithObjects:person, person2, nil]];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
        XCTAssertTrue([data length] > 0, @"pre-save vCard Representation was empty data.");
    } else {
        XCTAssertNil(data, @"pre-save vCard Representation should be nil when run on less than 5.0.");    
    }
    //save
    [_ab save];
    
    //test post save
    data = [_ab vCardRepresentationForPeople:[NSArray arrayWithObjects:person, person2, nil]];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
        XCTAssertTrue([data length] > 0, @"post-save vCard Representation was empty data.");
    } else {
        XCTAssertNil(data, @"pre-save vCard Representation should be nil when run on less than 5.0.");    
    }
    
    //cleanup
    [_ab removePerson:person];
    [_ab removePerson:person2];
    [_ab save];
    
    [person release];
    [person2 release];
}

-(void)testVCardSingleImport{
    if (SYSTEM_VERSION_LESS_THAN(@"5.0")) return; //iOS5+ feature.

    //setup
    RHPerson *person = [_ab newPersonInDefaultSource];
    NSDictionary *personDict = [self randomPersonDictionary];
    [self populateObject:person UsingDictionary:personDict];
    
    //test
    NSData *data = [person vCardRepresentation];
    XCTAssertTrue([data length] > 0, @" vCard Representation was empty data.");

    //revert
    [_ab revert];
    [_ab removePerson:person];
    [_ab save];
    [person release];

    //test import    
    NSArray *addedPeople = [_ab addPeopleFromVCardRepresentationToDefaultSource:data];    
    XCTAssertTrue([addedPeople count] == 1, @"1 person should have been added to the AB");

    //test import from source
    NSArray *addedPeople2 = [[_ab defaultSource] addPeopleFromVCardRepresentation:data];    
    XCTAssertTrue([addedPeople2 count] == 1, @"1 person should have been added to the AB");

    //save
    [_ab save];
    
    //make sure the person is still there.
    XCTAssertTrue([[[_ab defaultSource] people] containsObject:[addedPeople lastObject]], @"default source does not contain newly added vcard person");
    XCTAssertTrue([[[_ab defaultSource] people] containsObject:[addedPeople2 lastObject]], @"default source does not contain newly added vcard person");

    
    //cleanup
    for (RHPerson *person in addedPeople) {
        [_ab removePerson:person];
    }

    for (RHPerson *person in addedPeople2) {
        [_ab removePerson:person];
    }

    [_ab save];    
    
}

-(void)testVCardMultipleImport{
    if (SYSTEM_VERSION_LESS_THAN(@"5.0")) return; //iOS5+ feature.


    //setup
    RHPerson *person = [_ab newPersonInDefaultSource];
    RHPerson *person2 = [_ab newPersonInDefaultSource];
    NSDictionary *personDict = [self randomPersonDictionary];
    [self populateObject:person UsingDictionary:personDict];
    [self populateObject:person2 UsingDictionary:personDict];
    
    //test
    NSData *data = [_ab vCardRepresentationForPeople:[NSArray arrayWithObjects:person, person2, nil]];
    XCTAssertTrue([data length] > 0, @"vCard Representation was empty data.");

    
    //revert
    [_ab revert];
    [_ab removePerson:person];
    [_ab removePerson:person2];
    [_ab save];
    [person release];
    [person2 release];

    
    //test import 
    NSArray *addedPeople = [_ab addPeopleFromVCardRepresentation:data toSource:[_ab defaultSource]];
    
    XCTAssertTrue([addedPeople count] == 2, @"2 people should have been added to the AB");
    
    //cleanup
    for (RHPerson *person in addedPeople) {
        [_ab removePerson:person];
    }
    [_ab save];
    
}
#endif //end iOS5+


#pragma mark - people

-(void)testPeople{

    XCTAssertNotNil([_ab people], @"people should return an array");
    XCTAssertNotNil([_ab peopleOrderedByFirstName], @"people should return an array");
    XCTAssertNotNil([_ab peopleOrderedByLastName], @"people should return an array");
    XCTAssertNotNil([_ab peopleOrderedByUsersPreference], @"people should return an array");

    XCTAssertNotNil([[_ab defaultSource] people], @"people should return an array");
    XCTAssertNotNil([[_ab defaultSource] peopleOrderedByFirstName], @"people should return an array");
    XCTAssertNotNil([[_ab defaultSource] peopleOrderedByLastName], @"people should return an array");
    XCTAssertNotNil([[_ab defaultSource] peopleOrderedByUsersPreference], @"people should return an array");
    
    //add a person
    RHPerson *newPerson = [_ab newPersonInDefaultSource];
    NSDictionary *personDict = [self randomPersonDictionary];
    [self populateObject:newPerson UsingDictionary:personDict];

    //add a group
    RHGroup *newGroup = [_ab newGroupInDefaultSource];
    newGroup.name = @"Unit Test GroupB";

    //save
    XCTAssertTrue([newPerson save], @"save should be true");

    //add person to group
    XCTAssertTrue([newGroup addMember:newPerson], @"add person to groupshould return true");
    XCTAssertTrue([newPerson save], @"save should be true");
    
    
    XCTAssertTrue([[newGroup members] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[newGroup membersOrderedByFirstName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[newGroup membersOrderedByLastName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[newGroup membersOrderedByUsersPreference] containsObject:newPerson], @"array should contain newPerson");
    
    XCTAssertTrue([newPerson save], @"save should be true");

    //test post save
    XCTAssertTrue([[_ab people] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[_ab peopleOrderedByFirstName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[_ab peopleOrderedByLastName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[_ab peopleOrderedByUsersPreference] containsObject:newPerson], @"array should contain newPerson");
    
    XCTAssertTrue([[[_ab defaultSource] people] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[[_ab defaultSource] peopleOrderedByFirstName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[[_ab defaultSource] peopleOrderedByLastName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[[_ab defaultSource] peopleOrderedByUsersPreference] containsObject:newPerson], @"array should contain newPerson");
    
    XCTAssertTrue([[newGroup members] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[newGroup membersOrderedByFirstName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[newGroup membersOrderedByLastName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[newGroup membersOrderedByUsersPreference] containsObject:newPerson], @"array should contain newPerson");

    
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.0.3 hence the conditional)
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"7.0.3")) {
        [_ab performAddressBookAction:^(ABAddressBookRef addressBookRef) {
            ABAddressBookRevert(addressBookRef);
        } waitUntilDone:YES];
    }
        
    // removing a person should remove them from the source
    XCTAssertTrue([_ab removePerson:newPerson], @"remove person should return true");
    
    //test
    XCTAssertFalse([[_ab people] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[_ab peopleOrderedByFirstName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[_ab peopleOrderedByLastName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[_ab peopleOrderedByUsersPreference] containsObject:newPerson], @"array should not contain newPerson");
    
    XCTAssertFalse([[[_ab defaultSource] people] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[[_ab defaultSource] peopleOrderedByFirstName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[[_ab defaultSource] peopleOrderedByLastName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[[_ab defaultSource] peopleOrderedByUsersPreference] containsObject:newPerson], @"array should not contain newPerson");
    
    XCTAssertFalse([[newGroup members] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[newGroup membersOrderedByFirstName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[newGroup membersOrderedByLastName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[newGroup membersOrderedByUsersPreference] containsObject:newPerson], @"array should not contain newPerson");

    XCTAssertTrue([newPerson hasBeenRemoved], @"person should report themselves as having been removed");

    //reverting the removal should add them back to the source / group
    [_ab revert];

    
    XCTAssertTrue([[_ab people] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[_ab peopleOrderedByFirstName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[_ab peopleOrderedByLastName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[_ab peopleOrderedByUsersPreference] containsObject:newPerson], @"array should contain newPerson");
    
    XCTAssertTrue([[[_ab defaultSource] people] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[[_ab defaultSource] peopleOrderedByFirstName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[[_ab defaultSource] peopleOrderedByLastName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[[_ab defaultSource] peopleOrderedByUsersPreference] containsObject:newPerson], @"array should contain newPerson");
    
    XCTAssertTrue([[newGroup members] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[newGroup membersOrderedByFirstName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[newGroup membersOrderedByLastName] containsObject:newPerson], @"array should contain newPerson");
    XCTAssertTrue([[newGroup membersOrderedByUsersPreference] containsObject:newPerson], @"array should contain newPerson");

    
    //now remove and actually save, still should be removed
    XCTAssertTrue([newPerson remove], @"remove person should return true");
    XCTAssertTrue([newPerson save], @"save person should return true");
    
    //test
    XCTAssertFalse([[_ab people] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[_ab peopleOrderedByFirstName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[_ab peopleOrderedByLastName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[_ab peopleOrderedByUsersPreference] containsObject:newPerson], @"array should not contain newPerson");
    
    XCTAssertFalse([[[_ab defaultSource] people] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[[_ab defaultSource] peopleOrderedByFirstName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[[_ab defaultSource] peopleOrderedByLastName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[[_ab defaultSource] peopleOrderedByUsersPreference] containsObject:newPerson], @"array should not contain newPerson");
    
    XCTAssertFalse([[newGroup members] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[newGroup membersOrderedByFirstName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[newGroup membersOrderedByLastName] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertFalse([[newGroup membersOrderedByUsersPreference] containsObject:newPerson], @"array should not contain newPerson");

    XCTAssertTrue([newPerson hasBeenRemoved], @"person should report themselves as having been removed");

    //cleanup
    [_ab removeGroup:newGroup];
    [_ab removePerson:newPerson];
    [_ab save];
}

-(void)testPeopleWithName{
    NSString *testName = @"test me";
    RHPerson *newPerson = [_ab newPersonInDefaultSource];
    newPerson.firstName = testName;
    [_ab save];    
    
    XCTAssertTrue([[_ab peopleWithName:testName] containsObject:newPerson], @"person should be found by name");
    
    [newPerson remove];
    
    XCTAssertFalse([[_ab peopleWithName:testName] containsObject:newPerson], @"person should not be found by name");
    
    [_ab save]; 
    
    XCTAssertFalse([[_ab peopleWithName:testName] containsObject:newPerson], @"person should not be found by name");
    
    //cleanup
    [_ab removePerson:newPerson];
    [newPerson release];

    [_ab save];
    
}

-(void)testPeopleWithEmail{
    NSString *testEmail = @"test@me.com";
    RHPerson *newPerson = [_ab newPersonInDefaultSource];
    
    RHMutableMultiStringValue *multi = [[[RHMutableMultiStringValue alloc] initWithType:kABMultiStringPropertyType] autorelease];
    [multi addValue:testEmail withLabel:@"testLabel"];
    newPerson.emails = multi;
    [_ab save];
    
    XCTAssertTrue([[_ab peopleWithEmail:testEmail] containsObject:newPerson], @"person should be found by email");
    
    [newPerson remove];
    
    XCTAssertFalse([[_ab peopleWithEmail:testEmail] containsObject:newPerson], @"person should not be found by email");
    
    [_ab save];
    
    XCTAssertFalse([[_ab peopleWithEmail:testEmail] containsObject:newPerson], @"person should not be found by email");
    
    //cleanup
    [_ab removePerson:newPerson];
    [newPerson release];
    
    [_ab save];
    
}

-(void)testPersonProperties{
    //setup
    RHPerson *newPerson = [_ab newPersonInDefaultSource];
    NSDictionary *personDict = [self randomPersonDictionary];
    NSDictionary *personDict2 = [self randomPersonDictionary];
    [self populateObject:newPerson UsingDictionary:personDict];
    
    //test pre save
    [self validateObject:newPerson UsingDictionary:personDict];

    //save
    XCTAssertTrue([_ab save], @"save ab should return true");

    //test post save
    [self validateObject:newPerson UsingDictionary:personDict];
    
    //modify
    [self populateObject:newPerson UsingDictionary:personDict2];

    [self validateObject:newPerson UsingDictionary:personDict2];

    //test post revert, pre save
    [_ab revert];
    [self validateObject:newPerson UsingDictionary:personDict];

    //post save
    XCTAssertTrue([_ab save], @"save ab should return true");
    [self validateObject:newPerson UsingDictionary:personDict];

    //modify & save
    [self populateObject:newPerson UsingDictionary:personDict2];

    //test post save
    XCTAssertTrue([_ab save], @"save ab should return true");
    [self validateObject:newPerson UsingDictionary:personDict2];

    //cleanup
    [_ab removePerson:newPerson error:nil];
    [_ab save];
    [newPerson release];
    
}

-(void)testPersonLocalization{

    //no match found    
    XCTAssertTrue([[RHPerson localizedLabel:@"unit_test"] isEqualToString:@"unit_test"], @"localizedLabel: should return same string if failed to loc.");
    
    //match found
    XCTAssertTrue([[RHPerson localizedLabel:RHPersonPhoneIPhoneLabel] isEqualToString:@"iPhone"], @"localizedLabel: should return localized string.");

    //property names
    XCTAssertTrue([[RHPerson localizedPropertyName:kABPersonNicknameProperty] isEqualToString:@"Nickname"], @"localizedPropertyName: did failed to return loc. property name");
}

-(void)testPersonImage{
    //new person
    RHPerson *newPerson = [_ab newPersonInDefaultSource];    
    
    //should always return an array with self in it.
    XCTAssertFalse([newPerson hasImage], @"RHPerson hasImage should be false on init");
    XCTAssertNil([newPerson thumbnail], @"RHPerson thumbnail should be nil on init");
    XCTAssertNil([newPerson originalImage], @"RHPerson originalImage should be nil on init");

    
    UIImage *personImage1 = [self imageNamed:@"unit_test_person_image_1.jpg"];  
    UIImage *personImage1Thumb = [self imageNamed:@"unit_test_person_image_1_thumb.jpg"];  
    UIImage *personImage2 = [self imageNamed:@"unit_test_person_image_2.jpg"];  
    UIImage *personImage2Thumb = [self imageNamed:@"unit_test_person_image_2_thumb.jpg"];
    XCTAssertNotNil(personImage1, @"Could not find image unit_test_person_image.jpg");
    XCTAssertNotNil(personImage1Thumb, @"Could not find image unit_test_person_image.jpg");
    XCTAssertNotNil(personImage2, @"Could not find image unit_test_person_image.jpg");
    XCTAssertNotNil(personImage2Thumb, @"Could not find image unit_test_person_image.jpg");

    
    //add an image
    XCTAssertTrue([newPerson setImage:personImage1], @"set image returned false");

    XCTAssertTrue([personImage1 percentageDifferenceBetweenImage:[newPerson originalImage] withTolerance:0.1f andScaleIfImageSizesMismatched:YES] < 0.1f, @"original image returned from unsaved person does not match");
    // only iOS4.1+ supports returning the thumbnail
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
    if (SYSTEM_VERSION_GREATER_THAN(@"4.1")){
        XCTAssertTrue([personImage1Thumb percentageDifferenceBetweenImage:[newPerson thumbnail] withTolerance:0.2f andScaleIfImageSizesMismatched:YES] < 0.2f, @"thumbnail image returned from unsaved person does not match");
    } else{
#endif
        XCTAssertTrue([personImage1 percentageDifferenceBetweenImage:[newPerson thumbnail] withTolerance:0.37f andScaleIfImageSizesMismatched:YES] < 0.2f, @"thumbnail image returned from unsaved person does not match");
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
    }
#endif


    //save the image
    [newPerson save];

    XCTAssertTrue([personImage1 percentageDifferenceBetweenImage:[newPerson originalImage] withTolerance:0.1f andScaleIfImageSizesMismatched:YES] < 0.1f, @"original image returned from unsaved person does not match");
    // only iOS4.1+ supports returning the thumbnail
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
    if (SYSTEM_VERSION_GREATER_THAN(@"4.1")){
        XCTAssertTrue([personImage1Thumb percentageDifferenceBetweenImage:[newPerson thumbnail] withTolerance:0.2f andScaleIfImageSizesMismatched:YES] < 0.2f, @"thumbnail image returned from unsaved person does not match");
    } else{
#endif
        XCTAssertTrue([personImage1 percentageDifferenceBetweenImage:[newPerson thumbnail] withTolerance:0.37f andScaleIfImageSizesMismatched:YES] < 0.2f, @"thumbnail image returned from unsaved person does not match");
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
    }
#endif
    //[UIImageJPEGRepresentation([newPerson thumbnail], 100) writeToFile:@"out1.jpg" atomically:YES];
    
    //overwrite the image
    XCTAssertTrue([newPerson setImage:personImage2], @"set image returned false");
    
    XCTAssertTrue([personImage2 percentageDifferenceBetweenImage:[newPerson originalImage] withTolerance:0.1f andScaleIfImageSizesMismatched:YES] < 0.1f, @"original image returned from unsaved person does not match");
    // only iOS4.1+ supports returning the thumbnail
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
        if (SYSTEM_VERSION_GREATER_THAN(@"4.1")){
        XCTAssertTrue([personImage2Thumb percentageDifferenceBetweenImage:[newPerson thumbnail] withTolerance:0.1f andScaleIfImageSizesMismatched:YES] < 0.1f, @"thumbnail image returned from unsaved person does not match");
    } else{
#endif
        XCTAssertTrue([personImage2 percentageDifferenceBetweenImage:[newPerson thumbnail] withTolerance:0.2f andScaleIfImageSizesMismatched:YES] < 0.15f, @"thumbnail image returned from unsaved person does not match");
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
    }
#endif
    //[UIImageJPEGRepresentation([newPerson thumbnail], 100) writeToFile:@"out2.jpg" atomically:YES];

    
    //save the image
    [newPerson save];
    
    XCTAssertTrue([personImage2 percentageDifferenceBetweenImage:[newPerson originalImage] withTolerance:0.1f andScaleIfImageSizesMismatched:YES] < 0.1f, @"original image returned from unsaved person does not match");
    // only iOS4.1+ supports returning the thumbnail
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
            if (SYSTEM_VERSION_GREATER_THAN(@"4.1")){
            XCTAssertTrue([personImage2Thumb percentageDifferenceBetweenImage:[newPerson thumbnail] withTolerance:0.1f andScaleIfImageSizesMismatched:YES] < 0.1f, @"thumbnail image returned from unsaved person does not match");
        } else{
#endif
            XCTAssertTrue([personImage2 percentageDifferenceBetweenImage:[newPerson thumbnail] withTolerance:0.2f andScaleIfImageSizesMismatched:YES] < 0.15f, @"thumbnail image returned from unsaved person does not match");
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
        }
#endif
    XCTAssertTrue([newPerson hasImage], @"person hasImage should be YES");
    
    
    //test removing images
    [newPerson removeImage];
    
    XCTAssertNil([newPerson originalImage], @"image should be nil after removing image");
    XCTAssertNil([newPerson thumbnail], @"image should be nil after removing image");
    
    //also test after save
    [newPerson save];
    
    XCTAssertFalse([newPerson hasImage], @"person hasImage should be NO");

    XCTAssertNil([newPerson originalImage], @"image should be nil after removing image");
    XCTAssertNil([newPerson thumbnail], @"image should be nil after removing image");

    
    //cleanup
    [_ab removePerson:newPerson];
    [_ab save];
    [newPerson release];
}

-(void)testLinkedPeople{
    //make sure self is always returned if available.
    RHPerson *newPerson = [_ab newPersonInDefaultSource];    

    //if available
    if (ABPersonCopyArrayOfAllLinkedPeople != NULL){
        //should always return an array with self in it.
        XCTAssertTrue([[newPerson linkedPeople] containsObject:newPerson], @"self not included in linked people array");
        //not sure what else we can test here
    } else {
        //not available
        XCTAssertNil([newPerson linkedPeople], @"linkedPeople not available, yet we didn't return nil");
    }
    
    //cleanup
    [newPerson release];
}

#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

#import <CoreLocation/CoreLocation.h>
-(void)testPersonGeocoding{
    if (![RHAddressBook isGeocodingSupported]){
        NSLog(@"Geo Not Available");
        return;
    }

    //----- DISABLED
    //disable geocoding
    [RHAddressBook setPreemptiveGeocodingEnabled:NO];
    STAssertFalse([RHAddressBook isPreemptiveGeocodingEnabled], @"geocode should return false when disabled");

    //add person with known addresses
    
    RHPerson *newPerson1 = [_ab newPersonInDefaultSource];
    newPerson1.organization = @"Busaba Eathai";
    newPerson1.kind = RHPersonKindOrganization;
    //Busaba Eathai, 35 Panton Street, City of Westminster, London SW1Y 4EA UK (51.509431,-0.131997)
    NSDictionary *address1 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"35 Panton Street", RHPersonAddressStreetKey,
                              @"City of Westminster", RHPersonAddressCityKey,
                              @"London", RHPersonAddressStateKey,
                              @"SW1Y 4EA", RHPersonAddressZIPKey,
                              @"UK", RHPersonAddressCountryKey,
                              @"uk", RHPersonAddressCountryCodeKey,
                              nil];
    RHMutableMultiValue *multiValue1 = [[[RHMutableMultiValue alloc] initWithType:kABMultiDictionaryPropertyType] autorelease];
    [multiValue1 insertValue:address1 withLabel:RHWorkLabel atIndex:0];
    newPerson1.addresses = multiValue1;
    CLLocation *location1 = [[[CLLocation alloc] initWithLatitude:+51.50978520 longitude:-0.13198050] autorelease];

    
    RHPerson *newPerson2 = [_ab newPersonInDefaultSource];
    newPerson2.organization = @"Ezard";
    newPerson2.kind = RHPersonKindPerson;
    //Ezard, 187 Flinders Ln Melbourne VIC 3000, Australia (-37.816334,144.968371)
    NSDictionary *address2 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"187 Flinders Ln", RHPersonAddressStreetKey,
                              @"Melbourne", RHPersonAddressCityKey,
                              @"VIC", RHPersonAddressStateKey,
                              @"3000", RHPersonAddressZIPKey,
                              @"Australia", RHPersonAddressCountryKey,
                              @"au", RHPersonAddressCountryCodeKey,
                              nil];
    RHMutableMultiValue *multiValue2 = [[[RHMutableMultiValue alloc] initWithType:kABMultiDictionaryPropertyType] autorelease];
    [multiValue2 insertValue:address2 withLabel:RHWorkLabel atIndex:0];
    newPerson2.addresses = multiValue2;
    CLLocation *location2 = [[[CLLocation alloc] initWithLatitude:-37.81619800 longitude:+144.96828900] autorelease];

    
    // save person
    STAssertTrue([_ab save], @"save ab should return true");
    
    //wait 5s
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];

    //verify all addresses are nil points
    STAssertNil([newPerson1 placemarkForAddressID:[multiValue1 identifierAtIndex:0]], @"placemark should be nil");
    STAssertNil([newPerson1 locationForAddressID:[multiValue1 identifierAtIndex:0]], @"location should be nil");
    STAssertNil([newPerson2 placemarkForAddressID:[multiValue2 identifierAtIndex:0]], @"placemark should be nil");
    STAssertNil([newPerson2 locationForAddressID:[multiValue2 identifierAtIndex:0]], @"location should be nil");
    
    //enable
    [RHAddressBook setPreemptiveGeocodingEnabled:YES];
    STAssertTrue([RHAddressBook isPreemptiveGeocodingEnabled], @"geocode should return true when enabled");

    //wait 15s
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:15]];
    
    //verify each of the addresses has been geocoded
    STAssertNotNil([newPerson1 placemarkForAddressID:[multiValue1 identifierAtIndex:0]], @"placemark should not be nil");
    STAssertNotNil([newPerson2 placemarkForAddressID:[multiValue2 identifierAtIndex:0]], @"placemark should not be nil");
    
    CLLocation *generatedLocation1 = [newPerson1 locationForAddressID:[multiValue1 identifierAtIndex:0]];
    CLLocation *generatedLocation2 = [newPerson2 locationForAddressID:[multiValue2 identifierAtIndex:0]];
    STAssertNotNil(generatedLocation1, @"location should not be nil");
    STAssertNotNil(generatedLocation2, @"location should not be nil");
    
    //make sure its not more than 500m off. 
    STAssertTrue([location1 distanceFromLocation:generatedLocation1] < 500.0, @"location should not be more than 500m away");
    STAssertTrue([location2 distanceFromLocation:generatedLocation2] < 500.0, @"location should not be more than 500m away");

    //cleanup 
    [_ab removePerson:newPerson1];
    [_ab removePerson:newPerson2];

    [newPerson1 release];
    [newPerson2 release];
    
    [_ab save];
}
#endif //end iOS5+
#endif //end Geocoding


-(void)testPersonForABRecordRefMethod{
    //need to make sure that we always get a valid result returned for all the edge cases to do with the weak cache and adding and reverting people additions and removals

    //create a new person
    RHPerson *newPerson = nil;
    newPerson = [_ab newPersonInDefaultSource];  
    XCTAssertTrue([_ab personForABRecordRef:newPerson.recordRef] == newPerson, @"personobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab personForABRecordID:newPerson.recordID] == nil, @"personobject should not be returned from the cache for the given recordID");
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.1 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"7.1.0")) {
        XCTAssertTrue([[_ab people] containsObject:newPerson], @"array should contain newPerson");
    }
    
    //revert the addition
    [_ab revert];
    XCTAssertTrue([_ab personForABRecordRef:newPerson.recordRef] == newPerson, @"personobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab personForABRecordID:newPerson.recordID] == nil, @"personobject should not be returned from the cache for the given recordID");
    XCTAssertFalse([[_ab people] containsObject:newPerson], @"array should not contain newPerson");

    // re-add the person 
    XCTAssertTrue([_ab addPerson:newPerson], @"add person should return true");
    XCTAssertTrue([_ab personForABRecordRef:newPerson.recordRef] == newPerson, @"personobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab personForABRecordID:newPerson.recordID] == nil, @"personobject should not returned from the cache for the given recordID");
    //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.1 hence the conditional)
    if (SYSTEM_VERSION_GREATER_THAN(@"7.1.0")) {
        XCTAssertTrue([[_ab people] containsObject:newPerson], @"array should contain newPerson");
    }
    
    //save
    XCTAssertTrue([_ab save], @"save ab should return true");
    XCTAssertTrue([_ab personForABRecordRef:newPerson.recordRef] == newPerson, @"personobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab personForABRecordID:newPerson.recordID] == newPerson, @"personobject should be returned from the cache for the given recordID");
    XCTAssertTrue([[_ab people] containsObject:newPerson], @"array should contain newPerson");

    // remove person 
    //?? should the person be in the cache at this point? i think yes... they wont actually be vended because the ab methods wont return their recordRef
    XCTAssertTrue([_ab removePerson:newPerson], @"remove person should return true");
    XCTAssertTrue([_ab personForABRecordRef:newPerson.recordRef] == newPerson, @"personobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab personForABRecordID:newPerson.recordID] == nil, @"personobject should not be returned from the cache for the given recordID");
    XCTAssertFalse([[_ab people] containsObject:newPerson], @"array should not contain newPerson");
    
    //revert removal
    [_ab revert];
    XCTAssertTrue([_ab personForABRecordRef:newPerson.recordRef] == newPerson, @"personobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab personForABRecordID:newPerson.recordID] == newPerson, @"personobject should be returned from the cache for the given recordID");
    XCTAssertTrue([[_ab people] containsObject:newPerson], @"array should contain newPerson");
    
    // remove again 
    XCTAssertTrue([_ab removePerson:newPerson], @"remove person should return true");
    XCTAssertTrue([_ab personForABRecordRef:newPerson.recordRef] == newPerson, @"personobject should be returned from the cache for the given recordRef");
    XCTAssertTrue([_ab personForABRecordID:newPerson.recordID] == nil, @"personobject should not be returned from the cache for the given recordID");
    XCTAssertFalse([[_ab people] containsObject:newPerson], @"array should not contain newPerson");
    
    //save
    XCTAssertTrue([_ab save], @"save ab should return true");
    XCTAssertFalse([[_ab people] containsObject:newPerson], @"array should not contain newPerson");
    XCTAssertTrue([_ab personForABRecordRef:newPerson.recordRef] == newPerson, @"personobject should still be returned from the cache for the given recordRef, as it has a +1 retain count atm");
    XCTAssertTrue([_ab personForABRecordID:newPerson.recordID] == nil, @"personobject should not be returned from the cache for the given recordID");

    //we test to make sure the person is removed from the weak cache in the testWeakLinkedCache test

    //cleanup
    [_ab removePerson:newPerson];
    [_ab save];
    [newPerson release];
    
}


#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
#pragma mark - location services
-(void)testGeocoding{
    if ([RHAddressBook isGeocodingSupported]){
        
        
        //disable 
        [RHAddressBook setPreemptiveGeocodingEnabled:NO];
        STAssertFalse([RHAddressBook isPreemptiveGeocodingEnabled], @"geocode should return false when disabled");

        //setup        
        RHPerson *newPerson1 = [_ab newPersonInDefaultSource];
        newPerson1.organization = @"Busaba Eathai";
        newPerson1.kind = RHPersonKindOrganization;
        //Busaba Eathai, 35 Panton Street, City of Westminster, London SW1Y 4EA UK (+51.50978520,-0.13198050)
        NSDictionary *address1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"35 Panton Street", RHPersonAddressStreetKey,
                                  @"City of Westminster", RHPersonAddressCityKey,
                                  @"London", RHPersonAddressStateKey,
                                  @"SW1Y 4EA", RHPersonAddressZIPKey,
                                  @"UK", RHPersonAddressCountryKey,
                                  @"uk", RHPersonAddressCountryCodeKey,
                                  nil];
        RHMutableMultiValue *multiValue1 = [[[RHMutableMultiValue alloc] initWithType:kABMultiDictionaryPropertyType] autorelease];
        [multiValue1 insertValue:address1 withLabel:RHWorkLabel atIndex:0];
        newPerson1.addresses = multiValue1;
        CLLocation *location1 = [[[CLLocation alloc] initWithLatitude:+51.50978520 longitude:-0.13198050] autorelease];

        RHPerson *newPerson2 = [_ab newPersonInDefaultSource];
        newPerson2.organization = @"Ezard";
        newPerson2.kind = RHPersonKindPerson;
        //Ezard, 187 Flinders Ln Melbourne VIC 3000, Australia (-37.81619800,+144.96828900)
        NSDictionary *address2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"187 Flinders Ln", RHPersonAddressStreetKey,
                                  @"Melbourne", RHPersonAddressCityKey,
                                  @"VIC", RHPersonAddressStateKey,
                                  @"3000", RHPersonAddressZIPKey,
                                  @"Australia", RHPersonAddressCountryKey,
                                  @"au", RHPersonAddressCountryCodeKey,
                                  nil];
        RHMutableMultiValue *multiValue2 = [[[RHMutableMultiValue alloc] initWithType:kABMultiDictionaryPropertyType] autorelease];
        [multiValue2 insertValue:address2 withLabel:RHWorkLabel atIndex:0];
        newPerson2.addresses = multiValue2;
        CLLocation *location2 = [[[CLLocation alloc] initWithLatitude:-37.81619800 longitude:+144.96828900] autorelease];

        //save
        [_ab save];
        
        //wait 5
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];

        //verify all addresses are nil points
        STAssertNil([_ab placemarkForPerson:newPerson1 addressID:[multiValue1 identifierAtIndex:0]], @"placemark should be nil");
        STAssertNil([_ab locationForPerson:newPerson1 addressID:[multiValue1 identifierAtIndex:0]], @"location should be nil");
        STAssertNil([_ab placemarkForPerson:newPerson2 addressID:[multiValue2 identifierAtIndex:0]], @"placemark should be nil");
        STAssertNil([_ab locationForPerson:newPerson2 addressID:[multiValue2 identifierAtIndex:0]], @"location should be nil");
        
        //enable 
        [RHAddressBook setPreemptiveGeocodingEnabled:YES];
        STAssertTrue([RHAddressBook isPreemptiveGeocodingEnabled], @"geocode should return true when enabled");

        //sleep 15 
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:15]];

        //verify each of the addresses has been geocoded (if this is failing for you, make sure your addressbook is empty before you begin testing, timing only takes into account time needed to geocode the current number of addresses added)
        STAssertNotNil([_ab placemarkForPerson:newPerson1 addressID:[multiValue1 identifierAtIndex:0]], @"placemark should not be nil");
        STAssertNotNil([_ab placemarkForPerson:newPerson2 addressID:[multiValue2 identifierAtIndex:0]], @"placemark should not be nil");
        CLLocation *generatedLocation1 = [_ab locationForPerson:newPerson1 addressID:[multiValue1 identifierAtIndex:0]];
        CLLocation *generatedLocation2 = [_ab locationForPerson:newPerson2 addressID:[multiValue2 identifierAtIndex:0]];
        STAssertNotNil(generatedLocation1, @"location should not be nil");
        STAssertNotNil(generatedLocation2, @"location should not be nil");
        
        //make sure its not more than 500m off. 
        STAssertTrue([location1 distanceFromLocation:generatedLocation1] < 500.0, @"location should not be more than 500m away");
        STAssertTrue([location2 distanceFromLocation:generatedLocation2] < 500.0, @"location should not be more than 500m away");
        
        //-----------------------------------------------------------------
        //test reverse geo, while we have 2 lovely geocoded people
        
        //test ab
        STAssertTrue([_ab personClosestToLocation:location1 distanceOut:nil] == newPerson1, @"person should be returned via reverse lookup");
        STAssertTrue([_ab personClosestToLocation:location1] == newPerson1, @"person should be returned via reverse lookup");
        STAssertTrue([[_ab peopleWithinDistance:5000 ofLocation:location1] containsObject:newPerson1], @"person should be returned via reverse lookup");

        STAssertTrue([_ab personClosestToLocation:location2 distanceOut:nil] == newPerson2, @"person should be returned via reverse lookup");
        STAssertTrue([_ab personClosestToLocation:location2] == newPerson2, @"person should be returned via reverse lookup");
        STAssertTrue([[_ab peopleWithinDistance:5000 ofLocation:location2] containsObject:newPerson2], @"person should be returned via reverse lookup");

        
        STAssertFalse([[_ab peopleWithinDistance:5000 ofLocation:location1] containsObject:newPerson2], @"person should not be returned via reverse lookup if out of range");

        
        //test group
        
        RHGroup *newGroup = [_ab newGroupInDefaultSource];
        STAssertTrue([[newGroup membersWithinDistance:5000 ofLocation:location1] count] == 0, @"un-added group should return empty array");
        [_ab save];
        
        //pre add.. empty
        STAssertTrue([[newGroup membersWithinDistance:5000 ofLocation:location1] count] == 0, @"un-added group should return empty array");

        //add
        [newGroup addMember:newPerson1];
        //rdar://10898970 AB: created+added personRef is not returned by ABAddressBookCopyArrayOfAllPeople (issue exists on atleast up to 7.0.3 hence the conditional)
        if (SYSTEM_VERSION_GREATER_THAN(@"7.0.3")) {
            STAssertTrue([[newGroup membersWithinDistance:5000 ofLocation:location1] containsObject:newPerson1], @"person should be returned via reverse lookup");
        }
        [_ab save];
        
        //post add single
        STAssertTrue([[newGroup membersWithinDistance:5000 ofLocation:location1] containsObject:newPerson1], @"person should be returned via reverse lookup");
        STAssertFalse([[newGroup membersWithinDistance:DBL_MAX ofLocation:location1] containsObject:newPerson2], @"person2 should not be returned via reverse lookup as its not in the group");
        
        //cleanup 
        [_ab removePerson:newPerson1];
        [_ab removePerson:newPerson2];
        
        [newPerson1 release];
        [newPerson2 release];
        
        [newGroup remove];
        [newGroup release];
        
        [_ab save];
    } 

}

#endif //end iOS5+
#endif //end Geocoding



#pragma mark - misc tests

-(void)testAddingPersonToGroupFromOtherAddressBook{
    //this is not supported, test to make sure we dont do anything bad.
    RHGroup *newGroup = [_ab newGroupInDefaultSource];
    [_ab save];
    
    RHAddressBook *_ab2 = [[RHAddressBook alloc] init];
    RHPerson *newPerson = [_ab2 newPersonInDefaultSource];
    [_ab2 save];
    
    
    //test adding a member from another ab instance, this should fail.
    XCTAssertFalse([newGroup addMember:newPerson], @"adding a person from another ab instance should fail");

    
    //cleanup
    [_ab removeGroup:newGroup];
    [newGroup release];
    [_ab save];
    
    [_ab2 removePerson:newPerson];
    [newPerson release];

    [_ab2 save];
    [_ab2 release];
}


-(void)testWeakLinkedCache{

    //setup (get ivar refs)
    NSMutableSet *_groups = [self ivar:@"_groups" forObject:_ab];
    NSMutableSet *_people = [self ivar:@"_people" forObject:_ab];

    //add a group, make sure its added to cache
    RHGroup *newGroup = nil;
    RHPerson *newPerson = nil;
    @autoreleasepool {
        newGroup = [_ab newGroupInDefaultSource];
        newGroup.name = @"Unit Test GroupC";
        newPerson = [_ab newPersonInDefaultSource];
    }
    XCTAssertTrue([_groups containsObject:newGroup], @"_groups does not contain weak ref to newGroup");
    XCTAssertTrue([_people containsObject:newPerson], @"_people does not contain weak ref to newPerson");
    
    //release group make sure its removed
    [newGroup release];
    [newPerson release];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
    XCTAssertFalse([_groups containsObject:newGroup], @"_groups still contains weak ref to newGroup after release");
    XCTAssertFalse([_people containsObject:newPerson], @"_people still contains weak ref to newPerson after release");
    
    //cleanup
    [_ab revert];
}


-(void)testWeakLinkedRefMap{
    
    //setup (get ivar refs)
    CFMutableDictionaryRef _refToRecordMap = (CFMutableDictionaryRef)[self ivar:@"_refToRecordMap" forObject:_ab];
    
    if (_refToRecordMap){

        //add a group, make sure its added to map
        RHGroup *newGroup = nil;
        RHPerson *newPerson = nil;
        @autoreleasepool {
            newGroup = [_ab newGroupInDefaultSource];
            newGroup.name = @"Unit Test GroupC";
            newPerson = [_ab newPersonInDefaultSource];
        }
        XCTAssertTrue(CFDictionaryGetValue(_refToRecordMap, newGroup.recordRef) != NULL, @"_refToRecordMap does not contain weak ref to newGroup");
        XCTAssertTrue(CFDictionaryGetValue(_refToRecordMap, newPerson.recordRef) != NULL, @"_refToRecordMap does not contain weak ref to newPerson");
        
        //release group make sure its removed from map
        ABRecordRef newGroupRef = newGroup.recordRef;
        ABRecordRef newPersonRef = newPerson.recordRef;
        
        [newGroup release];
        [newPerson release];

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
        XCTAssertFalse(CFDictionaryGetValue(_refToRecordMap, newGroupRef) != NULL, @"_refToRecordMap still contains weak ref to newGroup");
        XCTAssertFalse(CFDictionaryGetValue(_refToRecordMap, newPersonRef) != NULL, @"_refToRecordMap still contains weak ref to newPerson");
    }
    //cleanup
    [_ab revert];
}

#if ARC_IS_NOT_ENABLED
//this only works when not built with ARC currently. Long discussion in https://github.com/heardrwt/RHAddressBook/issues/23
-(void)testWeakLinkedCacheConcurrency{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:2];
    
    if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined){
        
        //request authorization
        [_ab requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
        }];
    }

    //if this fails, we will likely crash, hence the test is only available with ARC disabled.
    for(int i = 0; i < 100; i++) {
        [queue addOperationWithBlock:^{
            NSArray *people = _ab.people;
            NSLog(@" %i people = %@",i, people);
        }];
    }

    [queue waitUntilAllOperationsAreFinished];
    
    NSAssert(true, @"If we get to here, we passed our test!");

}
#endif

//we only want these tests to run if linked against 5.0+ hence the defines and also, only if we are running on less that 5.0
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
#pragma mark - running on pre iOS5+ sanity
-(void)testCallingPostFiveAvailableMethodsOnPreFiveDevices{
    //we only want these tests to run if linked against 5.0+ hence the defines and also, only if we are running on less that 5.0
    if (SYSTEM_VERSION_LESS_THAN(@"5.0")){
    
        //setup
        RHGroup *newGroup = [_ab newGroupInDefaultSource];
        [_ab save];
        
        RHPerson *newPerson = [_ab newPersonInDefaultSource];
        [_ab save];
        
        XCTAssertTrue([newGroup addMember:newPerson], @"adding a person should return true");
        [_ab save];

        
        
        //sanity vcard methods:
        //ab
        XCTAssertNoThrow([_ab addPeopleFromVCardRepresentationToDefaultSource:[NSData data]], @"pre iOS5 this should do nothing");
        XCTAssertNoThrow([_ab addPeopleFromVCardRepresentation:[NSData data] toSource:[_ab defaultSource]], @"pre iOS5 this should do nothing");
        XCTAssertNil([_ab vCardRepresentationForPeople:[NSArray arrayWithObject:newPerson]], @"pre iOS5 this should return nil");

        //person
        XCTAssertNil([newPerson vCardRepresentation], @"pre iOS5 this should return nil");
        XCTAssertNil([RHPerson vCardRepresentationForPeople:[NSArray arrayWithObject:newPerson]], @"pre iOS5 this should return nil");
        
        //group
        XCTAssertNil([newGroup vCardRepresentationForMembers], @"pre iOS5 this should return nil");

        //source
        XCTAssertNil([[_ab defaultSource] vCardRepresentationForPeople], @"pre iOS5 this should return nil");
        [[_ab defaultSource] addPeopleFromVCardRepresentation:[NSData data]];

        
        
        
#if RH_AB_INCLUDE_GEOCODING

        //sanity geocode person methods:
        //ab
        CLLocation *location = [[[CLLocation alloc] initWithLatitude:122.0 longitude:-5.0] autorelease];
        STAssertNil([_ab placemarkForPerson:newPerson addressID:0], @"pre iOS5 this should return nil");
        STAssertNil([_ab locationForPerson:newPerson addressID:0], @"pre iOS5 this should return nil");
        
        STAssertTrue([[_ab peopleWithinDistance:50000 ofLocation:location] count] == 0, @"pre iOS5 this should return nil");
        STAssertNil([_ab personClosestToLocation:location], @"pre iOS5 this should return nil");
        STAssertNil([_ab personClosestToLocation:location distanceOut:nil], @"pre iOS5 this should return nil");

        //person
        STAssertNil([newPerson placemarkForAddressID:0], @"pre iOS5 this should return nil");
        STAssertNil([newPerson locationForAddressID:0], @"pre iOS5 this should return nil");

        //group
        STAssertTrue([[newGroup membersWithinDistance:50000 ofLocation:location] count] == 0, @"pre iOS5 this should return nil");

#endif //end Geocoding

        
        //sanity social person property
        XCTAssertNil([newPerson socialProfiles], @"pre iOS5 this should return nil");
        XCTAssertNoThrow([newPerson setSocialProfiles:[[[RHMutableMultiDictionaryValue alloc] initWithType:kABMultiDictionaryPropertyType] autorelease]], @"pre iOS5 this should do nothing");
        
        
        
        //cleanup
        [_ab removeGroup:newGroup];
        [newGroup release];
        
        [_ab removePerson:newPerson];
        [newPerson release];
        
        [_ab save];

    }
}
#endif //end iOS5+

#pragma mark - helpers

-(void)populateObject:(id)object UsingDictionary:(NSDictionary*)dictionary{
    for (NSString *key in [dictionary allKeys]) {
        NSString *capitalisedKey = [key stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[key  substringToIndex:1] capitalizedString]];
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"set%@:", capitalisedKey]);
        
        id newValue = [dictionary objectForKey:key];
        
        XCTAssertNoThrow([object performSelector:selector withObject:newValue], @"object:%@ failed to set value:%@ for key:%@", object, newValue, key);
    }
}

-(void)validateObject:(id)object UsingDictionary:(NSDictionary*)dictionary{
    XCTAssertNotNil(object, @"failed to validate nil object");

    for (NSString *key in [dictionary allKeys]) {
        SEL selector = NSSelectorFromString(key);

        id expectedValue = [dictionary objectForKey:key];
        id actualValue = [object performSelector:selector];
        
        XCTAssertEqualObjects(expectedValue, actualValue, @"object:%@ value:%@ for key:%@ not equal to expected value:%@", object, actualValue, key, expectedValue);
        
    }
}

-(void)populateAndValidateObject:(id)object UsingDictionary:(NSDictionary*)dictionary{
    [self populateAndValidateObject:object UsingDictionary:dictionary];
    [self validateObject:object UsingDictionary:dictionary];
}

-(UIImage*)imageNamed:(NSString*)name{
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:nil];
    return [UIImage imageWithContentsOfFile:path];
}

-(NSDictionary*)randomPersonDictionary{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    //skip image

    //personal properties
    [result setValue:@"Unit Test" forKey:@"firstName"];    
    [result setValue:[self randomString] forKey:@"lastName"];    
    [result setValue:[self randomString] forKey:@"middleName"];    
    [result setValue:[self randomString] forKey:@"prefix"];    
    [result setValue:[self randomString] forKey:@"suffix"];    
    [result setValue:[self randomString] forKey:@"nickname"];    
    
    [result setValue:[self randomString] forKey:@"firstNamePhonetic"];    
    [result setValue:[self randomString] forKey:@"lastNamePhonetic"];    
    [result setValue:[self randomString] forKey:@"middleNamePhonetic"];    

    [result setValue:[self randomString] forKey:@"organization"];    
    [result setValue:[self randomString] forKey:@"jobTitle"];    
    [result setValue:[self randomString] forKey:@"department"];    

    [result setValue:[self randomMultiString] forKey:@"emails"];
    [result setValue:[self randomDate] forKey:@"birthday"];    
    [result setValue:[self randomString] forKey:@"note"];    

    [result setValue:[self randomDate] forKey:@"birthday"];    
    [result setValue:[self randomDate] forKey:@"birthday"];    

    
    //addresses
    [result setValue:[self randomMultiAddressDictionary] forKey:@"addresses"];


    //Dates
    [result setValue:[self randomMultiDateTime] forKey:@"dates"];


    //Kind NSNumber either kABPersonKindOrganization or kABPersonKindPerson
    switch (rand()%2) {
        case 0: [result setValue:[NSNumber numberWithInt:[(NSNumber*)kABPersonKindPerson intValue]] forKey:@"kind"]; break;
        case 1: [result setValue:[NSNumber numberWithInt:[(NSNumber*)kABPersonKindOrganization intValue]] forKey:@"kind"]; break;
    }
    
    
    //Phone numbers
    [result setValue:[self randomMultiString] forKey:@"phoneNumbers"];
        
    //IM 
    [result setValue:[self randomMultiDictionary] forKey:@"instantMessageServices"];
    
    //URLs
    [result setValue:[self randomMultiString] forKey:@"urls"];
    
    //Related Names (Relationships)
    [result setValue:[self randomMultiString] forKey:@"relatedNames"];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
    //Social Profile (iOS5 +)
    if (&kABPersonSocialProfileProperty){
        [result setValue:[self randomMultiDictionary] forKey:@"socialProfiles"];
    }
#endif //end iOS5+    
    
    return [NSDictionary dictionaryWithDictionary:result];
}
     
     
-(NSString*)randomString{
    char* letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-+@()";
            
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        srand((unsigned)time(NULL));
    });
    
    NSInteger length = rand()%30;
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
        
    for (int i=0; i<length; i++) {
        [randomString appendFormat: @"%c", letters[rand() % strlen(letters)]];
    }
             
    return [NSString stringWithString:randomString];
}


-(NSDate*)randomDate{
    return [NSDate dateWithTimeIntervalSince1970:rand()%(60*60*24*365*55)];
}
     
-(RHMultiStringValue*)randomMultiString{
    RHMutableMultiValue *multiValue = [[[RHMutableMultiValue alloc] initWithType:kABMultiStringPropertyType] autorelease];
    
    NSInteger count = rand()%22;
    
    for (int i=0; i<count; i++) {
        [multiValue insertValue:[self randomString] withLabel:[self randomString] atIndex:i];        
    }

    //also test the basic addValueForKey & inset at random index
    [multiValue addValue:[self randomString] withLabel:[self randomString]];
    [multiValue insertValue:[self randomString] withLabel:[self randomString] atIndex:1];        
    
    return multiValue;
}
-(RHMultiDateTimeValue*)randomMultiDateTime{
    RHMutableMultiValue *multiValue = [[[RHMutableMultiValue alloc] initWithType:kABMultiDateTimePropertyType] autorelease];
    
    NSInteger count = rand()%22;
    
    for (int i=0; i<count; i++) {
        [multiValue insertValue:[self randomDate] withLabel:[self randomString] atIndex:i];        
    }
    
    //also test the basic addValueForKey & inset at random index
    [multiValue addValue:[self randomDate] withLabel:[self randomString]];
    [multiValue insertValue:[self randomDate] withLabel:[self randomString] atIndex:1];        
    
    return multiValue;

}
     
-(RHMultiDictionaryValue*)randomMultiDictionary{
    RHMutableMultiValue *multiValue = [[[RHMutableMultiValue alloc] initWithType:kABMultiDateTimePropertyType] autorelease];
    
    NSInteger count = rand()%22;
    
    for (int i=0; i<count; i++) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        NSInteger entries = rand()%11;
        for (int i=0; i<entries; i++) {
            [dict setValue:[self randomString] forKey:[self randomString]];
        }
        [multiValue insertValue:dict withLabel:[self randomString] atIndex:i];
    }
    
    //also test the basic addValueForKey & inset at random index
    [multiValue addValue:[NSDictionary dictionaryWithObject:[self randomString] forKey:[self randomString]] withLabel:[self randomString]];        
    [multiValue insertValue:[NSDictionary dictionaryWithObject:[self randomString] forKey:[self randomString]] withLabel:[self randomString] atIndex:1];        
    
    return multiValue;
}
-(RHMultiDictionaryValue*)randomMultiAddressDictionary{
    RHMutableMultiValue *multiValue = [[[RHMutableMultiValue alloc] initWithType:kABMultiDateTimePropertyType] autorelease];
    
    NSInteger count = rand()%22;
    
    for (int i=0; i<count; i++) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];

        [dict setValue:[self randomString] forKey:RHPersonAddressStreetKey];
        [dict setValue:[self randomString] forKey:RHPersonAddressCityKey];
        [dict setValue:[self randomString] forKey:RHPersonAddressStateKey];
        [dict setValue:[self randomString] forKey:RHPersonAddressZIPKey];
        [dict setValue:[self randomString] forKey:RHPersonAddressCountryKey];
        [dict setValue:@"us" forKey:RHPersonAddressCountryCodeKey]; //must be in 2 letter country code, so assume usa
        
        [multiValue insertValue:dict withLabel:[self randomString] atIndex:i];
    }
        
    return multiValue;
}

-(id)ivar:(NSString*)ivarName forObject:(id)object{
    Ivar tmpIvar = class_getInstanceVariable([object class], [ivarName UTF8String]);
    return object_getIvar(object, tmpIvar);
}


@end
