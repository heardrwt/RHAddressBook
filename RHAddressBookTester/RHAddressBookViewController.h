//
//  RHAddressBookViewController.h
//  RHAddressBook
//
//  Created by Richard Heard on 20/02/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RHAddressBookViewControllerSections) {
    kRHAddressBookViewControllerSourcesSection,
    kRHAddressBookViewControllerGroupsSection,
    kRHAddressBookViewControllerPeopleSection,
    kRHAddressBookViewControllerLocationSection,
    kRHAddressBookViewControllerInfoSection,
    kRHAddressBookViewControllerNumberOfSections
} ;


#define kRHAddressBookViewControllerInfoCellsCount 2

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
#define kRHAddressBookViewControllerLocationCellsCount 4
#else
#define kRHAddressBookViewControllerLocationCellsCount 1
#endif


@interface RHAddressBookViewController : UITableViewController {

    RHAddressBook *_addressBook;
    
    //cache
    NSMutableArray *_sources;
    NSMutableArray *_groups;
    NSMutableArray *_people;

}

-(instancetype)initWithAddressBook:(RHAddressBook*)addressBook NS_DESIGNATED_INITIALIZER;

@property (retain, nonatomic) RHAddressBook *addressBook;


@end
