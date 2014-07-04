//
//  RHGroupViewController.m
//  RHAddressBook
//
//  Created by Richard Heard on 21/02/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//

#import "RHGroupViewController.h"

#import <AddressBookUI/AddressBookUI.h>

@interface RHGroupViewController ()

-(void)addNewPerson;

-(void)addressBookChanged:(NSNotification*)notification;

@end

@implementation RHGroupViewController

@synthesize group=_group;

- (instancetype)initWithGroup:(RHGroup*)group{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _group = [group retain];

        //set out title
        self.title = [_group compositeName];
    }
    return self;
}

#define RN(x) [x release]; x = nil;
- (void)dealloc {
    RN(_members);
    RN(_group);

    [[NSNotificationCenter defaultCenter] removeObserver:self]; //for the ab externally changed notifications 

    [super dealloc];
}
- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(addressBookChanged:) name:RHAddressBookExternalChangeNotification object:nil];

    self.tableView.allowsSelectionDuringEditing = YES;

}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.

    //discard our cached values
    RN(_members);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:RHAddressBookExternalChangeNotification object:nil];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
     
    if(editing) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Rename" style:UIBarButtonItemStylePlain target:self action:@selector(renameGroup)] autorelease];

    } else {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;

    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.

    return self.editing ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
    // Return the number of rows in the section.
    [_members release];
    _members = [[_group membersOrderedByUsersPreference] mutableCopy];
    
    // this is as good a place as any to update our title.
    self.title = [_group compositeName];
    
    return [_members count];
    } else if (section == 1 && self.editing){
        return 1;
    } else {
        return 0;
    }    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    
    if (indexPath.section == 0){
        RHPerson *person = [_members objectAtIndex:indexPath.row];
        cell.textLabel.text = person.compositeName;
        cell.imageView.image = person.thumbnail;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        //assume adding a new row
        cell.textLabel.text = NSLocalizedString(@"Add New Person...", nil);
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {;
    if (indexPath.section == 1) return UITableViewCellEditingStyleInsert;
    
    return UITableViewCellEditingStyleDelete;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        RHPerson *member = [_members objectAtIndex:indexPath.row];
        [_members removeObject:member];
        [_group removeMember:member];
        [_group save];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        [self addNewPerson];
    }   

}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        //TODO: push our own viewer view, for now just use the AB default one.
        RHPerson *person = [_members objectAtIndex:indexPath.row];
        
        ABPersonViewController *personViewController = [[[ABPersonViewController alloc] init] autorelease];   

        //setup (tell the view controller to use our underlying address book instance, so our person object is directly updated)
        [person.addressBook performAddressBookAction:^(ABAddressBookRef addressBookRef) {
            personViewController.addressBook =addressBookRef;
        } waitUntilDone:YES];

        personViewController.displayedPerson = person.recordRef;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
        personViewController.allowsActions = YES;
#endif
        personViewController.allowsEditing = YES;
        
        
        [self.navigationController pushViewController:personViewController animated:YES];
    } else {
        //assume adding a person.
        [self addNewPerson];
    }
}

#pragma mark - add
-(void)addNewPerson{
    RHPerson *person = [_group.addressBook newPersonInSource:_group.source];
    person.firstName = NSLocalizedString(@"New Person", nil);
    [_group addMember:person];
    [_group save];
    [_members addObject:person];
    [person release];
}

#pragma mark - edit

-(void)renameGroup{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rename group?" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
    if ([UIAlertView instancesRespondToSelector:@selector(setAlertViewStyle:)]){
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[alert textFieldAtIndex:0] setText:[_group name]];
    }
#endif
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1){
        if ([UIAlertView instancesRespondToSelector:@selector(setAlertViewStyle:)]){
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
            _group.name = [[alertView textFieldAtIndex:0] text];
            [_group save];        
#endif
        } else {
            _group.name = [NSString stringWithFormat:@"%@ R", _group.name];
            [_group save];        
        }
    }
}

#pragma mark - addressBookChangedNotification
-(void)addressBookChanged:(NSNotification*)notification{
    [self.tableView reloadData];
}


@end
