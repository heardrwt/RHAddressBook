//
//  RHSource.h
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

#import "RHRecord.h"
#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
@class RHAddressBook;
@class RHPerson;
@class RHGroup;

@interface RHSource : RHRecord

//properties
@property (copy, readonly) NSString *name;
@property (readonly) ABSourceType type;

//access groups in the current source (this method just forwards to the equivalent method on RHAddressBook)
-(NSArray*)groups;

//access people in the current source
-(NSArray*)people;
-(NSArray*)peopleOrderedBySortOrdering:(ABPersonSortOrdering)ordering;
-(NSArray*)peopleOrderedByFirstName;
-(NSArray*)peopleOrderedByLastName;
-(NSArray*)peopleOrderedByUsersPreference;

//add (these methods just fwd to the equivalent convenience methods on RHAddressBook, including adding to the addressbook)
-(RHPerson*)newPerson; //returns nil on error (eg read only source)
-(RHGroup*)newGroup; //returns nil on error (eg read only source or does not support groups ex. exchange)

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

//add from vCard (iOS5+) (pre iOS5 these methods are no-ops)
-(NSArray*)addPeopleFromVCardRepresentation:(NSData*)representation; //returns an array of RHPerson objects

-(NSData*)vCardRepresentationForPeople;

#endif //end iOS5+

@end
