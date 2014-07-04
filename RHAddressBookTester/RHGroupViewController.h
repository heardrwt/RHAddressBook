//
//  RHGroupViewController.h
//  RHAddressBook
//
//  Created by Richard Heard on 21/02/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RHGroupViewController : UITableViewController {
    RHGroup *_group;
    
    NSMutableArray *_members; //cache
}

@property (retain) RHGroup *group;

- (instancetype)initWithGroup:(RHGroup*)group NS_DESIGNATED_INITIALIZER;

@end
