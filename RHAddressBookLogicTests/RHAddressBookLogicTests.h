//
//  RHAddressBookLogicTests.h
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

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "AddressBook.h"
#import "UIImage+RHComparingAdditions.h"
#import "RHARCSupport.h"

@interface RHAddressBookLogicTests : XCTestCase {
    RHAddressBook *_ab;
}

-(void)setUp;
-(void)tearDown;

#pragma mark - addressbook
-(void)testSaving;
-(void)testReverting;
-(void)testUnsavedChanges;
-(void)testForRecordRefMethods;
-(void)testUserPrefs; //sorting & display
-(void)testGroupsAndPeopleFromAnotherAddressBook;
-(void)testPassingNilToPublicMethods;

#pragma mark - sources
-(void)testSources;

#pragma mark - groups
-(void)testGroups; //create and delete. (in each source available.)
-(void)testGroupProperties;
-(void)testGroupForABRecordRefMethod;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
#pragma mark - vcards
-(void)testVCardSingleExport; //test both methods on RHAddressBook and on RHPerson.
-(void)testVCardMultipleExport;
-(void)testVCardSingleImport;
-(void)testVCardMultipleImport;
#endif //end iOS5+

#pragma mark - people
-(void)testPeople; //create and delete
-(void)testPeopleWithName;
-(void)testPersonProperties;
-(void)testPersonLocalization;
-(void)testPersonImage;
-(void)testLinkedPeople;
#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
-(void)testPersonGeocoding;
#endif //end iOS5+
#endif //end Geocoding
-(void)testPersonForABRecordRefMethod;


#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
#pragma mark - location services
-(void)testGeocoding;
#endif //end iOS5+
#endif //end Geocoding

#pragma mark - misc tests
-(void)testAddingPersonToGroupFromOtherAddressBook;
-(void)testWeakLinkedCache;
-(void)testWeakLinkedRefMap;
#if ARC_IS_NOT_ENABLED
-(void)testWeakLinkedCacheConcurrency;
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
#pragma mark - running on pre iOS5+ sanity
-(void)testCallingPostFiveAvailableMethodsOnPreFiveDevices;
#endif //end iOS5+

//helpers
-(void)populateObject:(id)object UsingDictionary:(NSDictionary*)dictionary;
-(void)validateObject:(id)object UsingDictionary:(NSDictionary*)dictionary;
-(void)populateAndValidateObject:(id)object UsingDictionary:(NSDictionary*)dictionary;

-(UIImage*)imageNamed:(NSString*)name;

//generators
-(NSDictionary*)randomPersonDictionary;

-(NSString*)randomString;
-(NSDate*)randomDate;

-(RHMultiStringValue*)randomMultiString;
-(RHMultiDateTimeValue*)randomMultiDateTime;

-(RHMultiDictionaryValue*)randomMultiDictionary;
-(RHMultiDictionaryValue*)randomMultiAddressDictionary;

-(id)ivar:(NSString*)ivarName forObject:(id)object;

//system versioning checks
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


@end
