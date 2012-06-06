//
//  RHAddressBook.m
//  RHAddressBook
//
//  Created by Richard Heard on 11/11/11.
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

#import "RHAddressBook.h"

#import "RHRecord.h"
#import "RHRecord_Private.h"

#import "RHSource.h"
#import "RHGroup.h"
#import "RHPerson.h"
#import "RHAddressBookSharedServices.h"
#import "RHAddressBookGeoResult.h"
#import "NSThread+RHBlockAdditions.h"
#import "RHAddressBookThreadMain.h"
#import "RHAddressBook_private.h"

NSString * const RHAddressBookExternalChangeNotification = @"RHAddressBookExternalChangeNotification";
NSString * const RHAddressBookPersonAddressGeocodeCompleted = @"RHAddressBookPersonAddressGeocodeCompleted";

//private
@interface RHAddressBook ()
@property (readonly) NSThread *addressBookThread; // we could possibly make this public... any use?
-(NSArray*)sourcesForABRecordRefs:(CFArrayRef)sourceRefs; //bulk performer
-(NSArray*)groupsForABRecordRefs:(CFArrayRef)groupRefs; //bulk performer
-(NSArray*)peopleForABRecordRefs:(CFArrayRef)peopleRefs; //bulk performer

-(void)addressBookExternallyChanged:(NSNotification*)notification; //notification on external changes. (revert if no local changes so always up-to-date)

@end

@implementation RHAddressBook {
    
    RHAddressBookSharedServices *_sharedServices; //single instance
    
    ABAddressBookRef _addressBookRef;
    NSThread *_addressBookThread; //do all work on the same thread. ABAddressBook is not thread safe. :(
    
    //cache sets, (if a record subclass is alive and associated with the current addressbook we maintain a weak pointer to it in one of the below sets)
    NSMutableSet *_sources; //set of RHSource objects, non retaining, weak references
    NSMutableSet *_groups;  //set of RHGroup objects, non retaining, weak references
    NSMutableSet *_people;  //set of RHPerson objects, non retaining weak references
    
    /*
     Basic weakly linked cache implementation:
     Whenever objects are requested, we do a real time query of the current addressbookRef. 
     For all the refs we get back from the query, we pass through the corresponding *forRef: method.
     This method, if it finds an entry in the cache returns a [retain] autorelease] version so as to persist the object for at-least the next cycle.
     If it does not find and entry in the cache a new object of correct type in created and added to the cache weakly.
     This object is then returned autoreleased to the user.
     
     Whenever a RHRecord subclass in created, it checks in with its associated addressBook which stores in its cache a weak pointer to the object.
     Whenever a RHRecord subclass is dealloc'd, it checks out with its associated addressBook which removes its weak pointer from the cache set.

     RHRecord objects strongly link their corresponding addressbook for their entire life.
     
     This system means that objects are persisted for the client between sessions if the client is holding onto an instance of them, 
     while also ensuring that unused instances are dealloc'd quickly.
     
     Finally, while you hold onto an RHRecord object you are also keeping the corresponding addressbook alive.
     (We need to do this because various methods associated with RHRecord subclasses use their associated 
     addressbook for functionality that would break if the addressbook went away)
     
     */

}

@synthesize addressBookThread=_addressBookThread;

-(id)retain{
    return [super retain];
}


-(id)init{
    self = [super init];
    if (self){
        
        //do all our work on a single thread.
        //because NSThread retains its target, we use a placeholder object that contains the threads main method
        RHAddressBookThreadMain *threadMain = [[[RHAddressBookThreadMain alloc] init] autorelease];
        _addressBookThread = [[NSThread alloc] initWithTarget:threadMain selector:@selector(threadMain:) object:nil];
        [_addressBookThread setName:[NSString stringWithFormat:@"RHAddressBookInstanceThread for instance %p", self]];
        [_addressBookThread start];

        _sharedServices = [RHAddressBookSharedServices sharedInstance]; //pointer to singleton (this causes the geo cache to be rebuilt if needed)
                
//        //setup
        [_addressBookThread performBlock:^{
            _addressBookRef = ABAddressBookCreate();

            //weak linking mutable sets
            _sources = (NSMutableSet *)CFSetCreateMutable(nil, 0, nil);
            _groups = (NSMutableSet *)CFSetCreateMutable(nil, 0, nil);
            _people = (NSMutableSet *)CFSetCreateMutable(nil, 0, nil);
            
        }];
        
    }
    
    return self;
}

-(void)dealloc{
    _sharedServices = nil; //just throw away our pointer (its a singleton)

    [_addressBookThread cancel]; //notify the thread that it is no longer needed
    [_addressBookThread release]; _addressBookThread = nil;
    
    if (_addressBookRef) CFRelease(_addressBookRef); _addressBookRef = NULL;
    
    
    [_sources release]; _sources = nil;
    [_groups release]; _groups = nil;
    [_people release]; _people = nil;
 
    [super dealloc];
}

#pragma mark - threads

-(void)performAddressBookAction:(void (^)(ABAddressBookRef addressBookRef))actionBlock waitUntilDone:(BOOL)wait{
    CFRetain(_addressBookRef);
    [_addressBookThread performBlock:^{
        actionBlock(_addressBookRef);
        CFRelease(_addressBookRef);
    } waitUntilDone:wait];
}


#pragma mark - access

-(NSArray*)sources{
    __block NSArray *result = nil;
    [_addressBookThread performBlock:^{
        CFArrayRef sourceRefs = ABAddressBookCopyArrayOfAllSources(_addressBookRef);
        if (sourceRefs){
            result = [[self sourcesForABRecordRefs:sourceRefs] retain];
            if (sourceRefs) CFRelease(sourceRefs);
        }
    }];
    return [result autorelease];
}

-(RHSource*)defaultSource{
    __block RHSource* source = nil;
    [_addressBookThread performBlock:^{
        ABRecordRef sourceRef = ABAddressBookCopyDefaultSource(_addressBookRef);
        source = [[self sourceForABRecordRef:sourceRef] retain];
        if (sourceRef) CFRelease(sourceRef);
    }];
    return [source autorelease];
}

-(RHSource*)sourceForABRecordRef:(ABRecordRef)sourceRef{

    if (sourceRef == NULL) return nil; //bail
    
    
    //if we find the exact ref in the current cache its safe to return that object, however its not save to add a ref directly if not found, instead we use the recordID
    // (this allows us to return not yet saved, newly created objects that have invalid RecordIDs without breaking the multiple ab barrier)
    // these not yet saved objects are added to the cache via the weak record check in / out system when they are created / dealloc'd 
    
    //search for an exact match using recordRef
    __block RHSource *source = nil;
    [_addressBookThread performBlock:^{
        //look in the cache
        for (RHSource *entry in _sources) {
            //compare using ref
            if (sourceRef == entry.recordRef){
                source = [entry retain];
                break;
            }
        }
    }];
    
    if (source) return [source autorelease];
    

    
    //get the sourceID
    __block ABRecordID sourceID = kABRecordInvalidID;
    [_addressBookThread performBlock:^{
        sourceID = ABRecordGetRecordID(sourceRef);
    }];
    
    if (sourceID == kABRecordInvalidID) return nil; //bail

    
    //search for the actual source
    [_addressBookThread performBlock:^{
        
        //look in the cache
        for (RHSource *entry in _sources) {
            //compare using ID not ref
            if (sourceID == entry.recordID){
                source = [entry retain];
                break;
            }
        }
        
        //if not in the cache, create and add a new one
        if (! source){
            //we don't use the sourceRef directly so as to ensure we are using the correct _addressBook
            ABRecordRef sourceRef = ABAddressBookGetSourceWithRecordID(_addressBookRef, sourceID);
            
            if (sourceRef){
                source = [[RHSource alloc] initWithAddressBook:self recordRef:sourceRef];
                //cache it
                if (source) [_sources addObject:source];
            }
        }
            
    }];
    if (!source) RHLog(@"Source lookup miss");
    return [source autorelease];
}

-(NSArray*)sourcesForABRecordRefs:(CFArrayRef)sourceRefs{
    CFRetain(sourceRefs);
    NSMutableArray *sources = [NSMutableArray array];
    
    [_addressBookThread performBlock:^{
        
        for (CFIndex i = 0; i < CFArrayGetCount(sourceRefs); i++) {
            ABRecordRef sourceRef = CFArrayGetValueAtIndex(sourceRefs, i);
            
            RHSource *source = [self sourceForABRecordRef:sourceRef];
            if (source) [sources addObject:source];
        }
    }];
    CFRelease(sourceRefs);
    return [NSArray arrayWithArray:sources];
}

-(RHSource*)sourceForABRecordID:(ABRecordID)sourceID{
    __block ABRecordRef recordRef = NULL;
    
    [_addressBookThread performBlock:^{
        recordRef = ABAddressBookGetSourceWithRecordID(_addressBookRef, sourceID);
    }];    
    
    return [self sourceForABRecordRef:recordRef];
}


-(NSArray*)groups{
    __block NSArray *result = nil;
    [_addressBookThread performBlock:^{
        CFArrayRef groupRefs = ABAddressBookCopyArrayOfAllGroups(_addressBookRef);
        if (groupRefs){
            result = [[self groupsForABRecordRefs:groupRefs] retain];
            CFRelease(groupRefs);
        }
    }];
    return [result autorelease];
}

-(NSArray*)groupsInSource:(RHSource*)source{
    __block NSArray *result = nil;
    [_addressBookThread performBlock:^{
        CFArrayRef groupRefs = ABAddressBookCopyArrayOfAllGroupsInSource(_addressBookRef, source.recordRef);
        if (groupRefs){
            result = [[self groupsForABRecordRefs:groupRefs] retain];
            CFRelease(groupRefs);
        }
    }];
    return [result autorelease];
}

-(RHGroup*)groupForABRecordRef:(ABRecordRef)groupRef{
    
    if (groupRef == NULL) return nil; //bail
    
    
    //if we find the exact ref in the current cache its safe to return that object, however its not save to add a ref directly if not found, instead we use the recordID
    // (this allows us to return not yet saved, newly created objects that have invalid RecordIDs without breaking the multiple ab barrier)
    // these not yet saved objects are added to the cache via the weak record check in / out system when they are created / dealloc'd 
    
    //search for an exact match using recordRef
    __block RHGroup *group = nil;
    [_addressBookThread performBlock:^{
        //look in the cache
        for (RHGroup *entry in _groups) {
            //compare using ref
            if (groupRef == entry.recordRef){
                group = [entry retain];
                break;
            }
        }
    }];
    
    if (group) return [group autorelease];
    
    
    //if no direct match found, try using recordID
    __block ABRecordID groupID = kABRecordInvalidID;
    [_addressBookThread performBlock:^{
        groupID = ABRecordGetRecordID(groupRef);
    }];
    
    //is valid ?
    if (groupID == kABRecordInvalidID) return nil; //invalid
    
    
    //search for the actual group via recordID
    [_addressBookThread performBlock:^{


        //look in the cache
        for (RHGroup *entry in _groups) {
            //compare using ID not ref
            if (groupID == entry.recordID){
                group = [entry retain];
                break;
            }
        }

        //if not in the cache, create and add a new one
        if (! group){
            
            //we don't use the groupRef directly to ensure we are using the correct _addressBook
            __block ABRecordRef groupRef = ABAddressBookGetGroupWithRecordID(_addressBookRef, groupID);

            if (groupRef){
                group = [[RHGroup alloc] initWithAddressBook:self recordRef:groupRef];
                //cache it
                if (group) [_groups addObject:group];
            }
        }
        
    }];
    
    return [group autorelease];
}

-(NSArray*)groupsForABRecordRefs:(CFArrayRef)groupRefs{
    NSMutableArray *groups = [NSMutableArray array];
    
    [_addressBookThread performBlock:^{
        
        for (CFIndex i = 0; i < CFArrayGetCount(groupRefs); i++) {
            ABRecordRef groupRef = CFArrayGetValueAtIndex(groupRefs, i);
            
            RHGroup *group = [self groupForABRecordRef:groupRef];
            if (group){ [groups addObject:group];} else {
                RHLog(@"failed to find group for %@", groupRef);
            }
        }
    }];
    return [NSArray arrayWithArray:groups];
}

-(RHGroup*)groupForABRecordID:(ABRecordID)groupID{

    __block ABRecordRef recordRef = NULL;
    
    [_addressBookThread performBlock:^{
        recordRef = ABAddressBookGetGroupWithRecordID(_addressBookRef, groupID);
    }];    
    
    return [self groupForABRecordRef:recordRef];
}


-(NSArray*)people{
    __block NSArray *result = nil;
    [_addressBookThread performBlock:^{
        CFArrayRef peopleRefs = ABAddressBookCopyArrayOfAllPeople(_addressBookRef);
        if (peopleRefs){
            result = [[self peopleForABRecordRefs:peopleRefs] retain];
            CFRelease(peopleRefs);
        }
    }];
    return [result autorelease];
}

-(NSArray*)peopleOrderedBySortOrdering:(ABPersonSortOrdering)ordering{
    __block NSArray *result = nil;
    [_addressBookThread performBlock:^{
        
        CFArrayRef peopleRefs = ABAddressBookCopyArrayOfAllPeople(_addressBookRef);
        if (peopleRefs){

            CFMutableArrayRef mutablePeopleRefs = CFArrayCreateMutableCopy(kCFAllocatorDefault, CFArrayGetCount(peopleRefs), peopleRefs);
            if (mutablePeopleRefs){

                //sort 
                CFArraySortValues(mutablePeopleRefs, CFRangeMake(0, CFArrayGetCount(mutablePeopleRefs)), (CFComparatorFunction) ABPersonComparePeopleByName, (void*) ordering);
                result = [[self peopleForABRecordRefs:mutablePeopleRefs] retain];
                CFRelease(mutablePeopleRefs);
                
            }
            
        CFRelease(peopleRefs);
            
        }
    }];
    
    return [result autorelease];
}

-(NSArray*)peopleOrderedByUsersPreference{
    return [self peopleOrderedBySortOrdering:[RHAddressBook sortOrdering]];
}
-(NSArray*)peopleOrderedByFirstName{
    return [self peopleOrderedBySortOrdering:kABPersonSortByFirstName];
}
-(NSArray*)peopleOrderedByLastName{
    return [self peopleOrderedBySortOrdering:kABPersonSortByLastName];
}

-(NSArray*)peopleWithName:(NSString*)name{
    __block NSArray *result = nil;
    [_addressBookThread performBlock:^{
        CFArrayRef peopleRefs = ABAddressBookCopyPeopleWithName(_addressBookRef, (CFStringRef)name);
        if (peopleRefs) {
            result = [[self peopleForABRecordRefs:peopleRefs] retain];
            CFRelease(peopleRefs);
        }
    }];
    return [result autorelease];
}

-(RHPerson*)personForABRecordRef:(ABRecordRef)personRef{
    
    if (personRef == NULL) return nil; //bail

    //if we find the exact ref in the current cache its safe to return that object, however its not save to add a ref directly if not found, instead we use the recordID
    // (this allows us to return not yet saved, newly created objects that have invalid RecordIDs without breaking the multiple ab barrier)
    // these not yet saved objects are added to the cache via the weak record check in / out system when they are created / dealloc'd 
    
    //search for an exact match using recordRef
    __block RHPerson *person = nil;
    [_addressBookThread performBlock:^{
        //look in the cache
        for (RHPerson *entry in _people) {
            //compare ref directly
            if (personRef == entry.recordRef){
                person = [entry retain];
                break;
            }
        }
    }];
    
    if (person) return [person autorelease];
    
    
    //if exact matching failed, look using recordID;
    __block ABRecordID personID = kABRecordInvalidID;
    [_addressBookThread performBlock:^{
        personID = ABRecordGetRecordID(personRef);
    }];
    
    //is valid ?
    if (personID == kABRecordInvalidID) return nil; //invalid
    
    
    //search for the actual person using recordID
    
    [_addressBookThread performBlock:^{
        
        //look in the cache
        for (RHPerson *entry in _people) {
            //compare using ID not ref
            if (personID == entry.recordID){
                person = [entry retain];
                break;
            }
        }
        
        //if not in the cache, create and add a new one
        if (! person){
            
            //we don't use the personRef directly to ensure we are using the correct _addressBook
            __block ABRecordRef personRef = ABAddressBookGetPersonWithRecordID(_addressBookRef, personID);
            
            if (personRef){
                person = [[RHPerson alloc] initWithAddressBook:self recordRef:personRef];
                //cache it
                if (person) [_people addObject:person];
            }
        }
        
    }];
    
    return [person autorelease];

}

-(NSArray*)peopleForABRecordRefs:(CFArrayRef)peopleRefs{
    NSMutableArray *people = [NSMutableArray array];

    [_addressBookThread performBlock:^{

        for (CFIndex i = 0; i < CFArrayGetCount(peopleRefs); i++) {
            ABRecordRef personRef = CFArrayGetValueAtIndex(peopleRefs, i);
            
            RHPerson *person = [self personForABRecordRef:personRef];
            if (person) [people addObject:person];
        }
    }];
    return [NSArray arrayWithArray:people];
}

-(RHPerson*)personForABRecordID:(ABRecordID)personID{

    __block ABRecordRef recordRef = NULL;
    
    [_addressBookThread performBlock:^{
        recordRef = ABAddressBookGetPersonWithRecordID(_addressBookRef, personID);
    }];    
    
    return [self personForABRecordRef:recordRef];
}

#pragma mark - add
-(RHPerson*)newPersonInDefaultSource{
    RHPerson *newPerson = [RHPerson newPersonInSource:[self defaultSource]];
    [self addPerson:newPerson];
    return newPerson;
}

-(RHPerson*)newPersonInSource:(RHSource*)source{
    
    //make sure the passed source is actually associated with self
    if (self != source.addressBook) [NSException raise:NSInvalidArgumentException format:@"Error: RHSource object does not belong to this addressbook instance."];
    
    RHPerson *newPerson = [RHPerson newPersonInSource:source];
    [self addPerson:newPerson];
    return newPerson;
}

-(BOOL)addPerson:(RHPerson *)person{
    __block BOOL result = NO;
    //first check to make sure person has not already been added to another addressbook, if so bail;
    if (person.addressBook != nil && person.addressBook != self) [NSException raise:NSInvalidArgumentException format:@"Person has already been added to another addressbook."];
    [_addressBookThread performBlock:^{
        
        CFErrorRef errorRef = NULL;
        result = ABAddressBookAddRecord(_addressBookRef, person.recordRef, &errorRef);
        if (!result){
            RHLog(@"Error: Failed to add RHPerson to AddressBook: error: %@", (NSError*)errorRef);
        } else {
            if (![_people containsObject:person])[_people addObject:person];
        }
    }];
    return result;
}


#pragma mark - add groups
-(RHGroup*)newGroupInDefaultSource{
    RHGroup *newGroup = [RHGroup newGroupInSource:[self defaultSource]];
    [self addGroup:newGroup];
    return newGroup;
}

-(RHGroup*)newGroupInSource:(RHSource*)source{
    
    //make sure the passed source is actually associated with self
    if (self != source.addressBook) [NSException raise:NSInvalidArgumentException format:@"Error: RHSource object does not belong to this addressbook instance."];
    
    RHGroup *newGroup = [RHGroup newGroupInSource:source];
    [self addGroup:newGroup];
    return newGroup;
}

-(BOOL)addGroup:(RHGroup *)group{
    __block BOOL result = NO;
    //first check to make sure group has not already been added to another addressbook, if so bail;
    if (group.addressBook != nil && group.addressBook != self) [NSException raise:NSInvalidArgumentException format:@"Group has already been added to another addressbook."];
    [_addressBookThread performBlock:^{
        
        CFErrorRef errorRef = NULL;
        result = ABAddressBookAddRecord(_addressBookRef, group.recordRef, &errorRef);
        if (!result){
            RHLog(@"Error: Failed to add RHGroup to AddressBook: error: %@", (NSError*)errorRef);
        } else {
            if (![_groups containsObject:group])[_groups addObject:group];
        }
    }];
    return result;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

#pragma mark - add from vCard (iOS5+)
-(NSArray*)addPeopleFromVCardRepresentationToDefaultSource:(NSData*)representation{
    return [self addPeopleFromVCardRepresentation:representation toSource:[self defaultSource]];
}

-(NSArray*)addPeopleFromVCardRepresentation:(NSData*)representation toSource:(RHSource*)source{
    if (!ABPersonCreatePeopleInSourceWithVCardRepresentation) return nil; //availability check

    NSMutableArray *newPeople = [NSMutableArray array];

    [_addressBookThread performBlock:^{

        CFArrayRef peopleRefs = ABPersonCreatePeopleInSourceWithVCardRepresentation(source.recordRef, (CFDataRef)representation);
        for (CFIndex i = 0; i < CFArrayGetCount(peopleRefs); i++) {
            ABRecordRef personRef = CFArrayGetValueAtIndex(peopleRefs, i);
            if (personRef){
                BOOL success = ABAddressBookAddRecord(_addressBookRef, personRef, NULL);

                if (success){
                    RHPerson *person = [[[RHPerson alloc] initWithAddressBook:self recordRef:personRef] autorelease];
                    if (person)[newPeople addObject:person];
                }
            }
        }
        if (peopleRefs) CFRelease(peopleRefs);
    }];
   return newPeople;
}

-(NSData*)vCardRepresentationForPeople:(NSArray*)people{
    if (!ABPersonCreateVCardRepresentationWithPeople) return nil; //availability check

    CFMutableArrayRef refs = CFArrayCreateMutable(NULL, 0, NULL);
    
    for (RHPerson*person in people) {
        CFArrayAppendValue(refs, person.recordRef);
    }
    
    NSData *result = (NSData*)ABPersonCreateVCardRepresentationWithPeople(refs);
    CFRelease(refs);
    return [result autorelease];
}

#endif //end iOS5+


#pragma mark - remove
-(BOOL)removePerson:(RHPerson*)person{
    return [self removePerson:person error:nil];
}

-(BOOL)removePerson:(RHPerson*)person error:(NSError**)error{
    //need to make sure it is actually part of the current addressbook
    if (person.addressBook != self) [NSException raise:NSInvalidArgumentException format:@"Person does not belong to this addressbook instance."];
    
    __block BOOL result = YES;
    __block CFErrorRef cfError = NULL;
    
    [_addressBookThread performBlock:^{
        result = ABAddressBookRemoveRecord(_addressBookRef, person.recordRef, &cfError);
        //if (result)[_people removeObject:person]; //we shouldn't actually remove this object from the cache on removal.. all accesses go via AB record methods so removing now just means the same object is not returned by the cache if the user reverts the removal.
    }];

    if (error) *error = (NSError*)cfError;
    return result;
}

-(BOOL)removeGroup:(RHGroup*)group{
    return [self removeGroup:group error:nil];
}

-(BOOL)removeGroup:(RHGroup*)group error:(NSError**)error{
    //make sure it is actually part of the current addressbook
    if (group.addressBook != self) [NSException raise:NSInvalidArgumentException format:@"Group does not belong to this addressbook instance."];

    __block BOOL result = YES;
    __block CFErrorRef cfError = NULL;
    
    [_addressBookThread performBlock:^{
        result = ABAddressBookRemoveRecord(_addressBookRef, group.recordRef, &cfError);
        //if (result)[_groups removeObject:group]; //we shouldn't actually remove this object from the cache on removal.. all accesses go via AB record methods so removing now just means the same object is not returned by the cache if the user reverts the removal.

    }];

    if (error) *error = (NSError*)cfError;
    
    return result;
}


#pragma mark - save
-(BOOL)save{
    NSError *error = nil;
    BOOL result = [self save:&error];
    if (!result) {
        RHLog(@"RHAddressBook: Error saving: %@", error);
    }
    return result;
}

-(BOOL)save:(NSError**)error{
    __block BOOL result = YES;
    __block CFErrorRef cfError = NULL;
    
    [_addressBookThread performBlock:^{
        if ([self hasUnsavedChanges]) {
            result = ABAddressBookSave(_addressBookRef, &cfError);
        }
    }];
    if (error) *error = (NSError*)cfError;
    return result;
}

-(BOOL)hasUnsavedChanges{
    __block BOOL result;
    [_addressBookThread performBlock:^{
    result = ABAddressBookHasUnsavedChanges(_addressBookRef);
    }];
    
    return result;
}

-(void)revert{
    [_addressBookThread performBlock:^{
        ABAddressBookRevert(_addressBookRef);
    }];
}

-(void)addressBookExternallyChanged:(NSNotification*)notification{
//notification on external changes. (revert if no local changes so always up-to-date)
    if (![self hasUnsavedChanges]){
        [self revert];
    } else {
        RHLog(@"Not auto-reverting on notification of external address book changes as we have unsaved local changes.");
    }

}

#pragma mark - prefs
+(ABPersonSortOrdering)sortOrdering{
    return ABPersonGetSortOrdering();
}
+(BOOL)orderByFirstName{
    return [RHAddressBook sortOrdering] == kABPersonSortByFirstName;
}
+(BOOL)orderByLastName{
    return [RHAddressBook sortOrdering] == kABPersonSortByLastName;
}

+(ABPersonCompositeNameFormat)compositeNameFormat{
    return ABPersonGetCompositeNameFormat();
}

+(BOOL)compositeNameFormatFirstNameFirst{
    return [RHAddressBook compositeNameFormat] == kABPersonCompositeNameFormatFirstNameFirst;
}
+(BOOL)compositeNameFormatLastNameFirst{
    return [RHAddressBook compositeNameFormat] == kABPersonCompositeNameFormatLastNameFirst;
}


+(BOOL)isGeocodingSupported{
    return [RHAddressBookSharedServices isGeocodingSupported];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

#pragma mark - geocoding (iOS5+)
//cache
+(BOOL)isPreemptiveGeocodingEnabled{
    return [RHAddressBookSharedServices isPreemptiveGeocodingEnabled];
}

+(void)setPreemptiveGeocodingEnabled:(BOOL)enabled{
    [RHAddressBookSharedServices setPreemptiveGeocodingEnabled:enabled];
}
-(float)preemptiveGeocodingProgress{
    return [_sharedServices preemptiveGeocodingProgress];
}

//forward
-(CLPlacemark*)placemarkForPerson:(RHPerson*)person addressID:(ABMultiValueIdentifier)addressID{
    return [_sharedServices placemarkForPersonID:person.recordID addressID:addressID];
}

-(CLLocation*)locationForPerson:(RHPerson*)person addressID:(ABMultiValueIdentifier)addressID{
    return [_sharedServices locationForPersonID:person.recordID addressID:addressID];
}

//reverse geo
-(NSArray*)peopleWithinDistance:(double)distance ofLocation:(CLLocation*)location{
    NSArray *results = [_sharedServices geoResultsWithinDistance:distance ofLocation:location];
    NSMutableArray *array = [NSMutableArray array];
    if (results){
        [_addressBookThread performBlock:^{
            for (RHAddressBookGeoResult *result in results) {
                RHPerson *person = [self personForABRecordRef:ABAddressBookGetPersonWithRecordID(_addressBookRef, result.personID)];
                if (person) [array addObject:person];
            }
        }];
    }
    return [NSArray arrayWithArray:array];
}

-(RHPerson*)personClosestToLocation:(CLLocation*)location{
    RHAddressBookGeoResult *result = [_sharedServices geoResultClosestToLocation:location];
    __block RHPerson *person = nil;
    if (result){
        [_addressBookThread performBlock:^{
            person = [[self personForABRecordRef:ABAddressBookGetPersonWithRecordID(_addressBookRef, result.personID)] retain];
        }];
    }
    return [person autorelease];
    
}

-(RHPerson*)personClosestToLocation:(CLLocation*)location distanceOut:(double*)distanceOut{
    RHAddressBookGeoResult *result = [_sharedServices geoResultClosestToLocation:location distanceOut:distanceOut];
    __block RHPerson *person = nil;
    if (result){
        [_addressBookThread performBlock:^{
            person = [[self personForABRecordRef:ABAddressBookGetPersonWithRecordID(_addressBookRef, result.personID)] retain];
        }];
    }
    return [person autorelease];
}

#endif //end iOS5+


#pragma mark - private

//used to implement the weak linking cache 
-(void)_recordCheckIn:(RHRecord*)record{
    if (!record) return;

    [record retain]; //keep it around for a while

    [_addressBookThread performBlock:^{

        //if source, add to _sources
        if ([record isKindOfClass:[RHSource class]]){
            if (![_sources containsObject:record]) [_sources addObject:record];
        }    

        //if group, add to _groups
        if ([record isKindOfClass:[RHGroup class]]){
            if (![_groups containsObject:record]) [_groups addObject:record];
        }
        
        //if person, add to _people
        if ([record isKindOfClass:[RHPerson class]]){
            if (![_people containsObject:record]) [_people addObject:record];
        }    
    }];
    
    [record release];
}

-(void)_recordCheckOut:(RHRecord*)record{
    //called from inside records dealloc method, so not safe to use any instance variables implemented below RHRecord.
    if (!record) return;
    
    __block RHRecord *_safeRecord = record;
    
    [_addressBookThread performBlock:^{
        
        //if source, remove from _sources
        if ([_safeRecord isKindOfClass:[RHSource class]]){
            if ([_sources containsObject:_safeRecord]) [_sources removeObject:_safeRecord];
        }    
        
        //if group, remove from _groups
        if ([_safeRecord isKindOfClass:[RHGroup class]]){
            if ([_groups containsObject:_safeRecord]) [_groups removeObject:_safeRecord];
        }
        
        //if person, remove from _people
        if ([_safeRecord isKindOfClass:[RHPerson class]]){
            if ([_people containsObject:_safeRecord]) [_people removeObject:_safeRecord];
        }    
    }];
    
}
@end
