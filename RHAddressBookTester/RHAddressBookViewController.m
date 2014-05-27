//
//  RHAddressBookViewController.m
//  RHAddressBook
//
//  Created by Richard Heard on 20/02/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//

#import "RHAddressBookViewController.h"
#import "RHGroupViewController.h"

#import <AddressBookUI/AddressBookUI.h>

@interface RHAddressBookViewController ()

-(void)configureCell:(UITableViewCell*)cell forInfoAtRow:(NSInteger)row;
-(void)configureCell:(UITableViewCell*)cell forLocationAtRow:(NSInteger)row;
-(void)configureCell:(UITableViewCell*)cell forSourceAtRow:(NSInteger)row;
-(void)configureCell:(UITableViewCell*)cell forGroupAtRow:(NSInteger)row;
-(void)configureCell:(UITableViewCell*)cell forPersonAtRow:(NSInteger)row;

-(void)addNewGroup;
-(void)addNewPerson;

-(void)addressBookChanged:(NSNotification*)notification;


@end

@implementation RHAddressBookViewController

@synthesize addressBook=_addressBook;

- (id)initWithAddressBook:(RHAddressBook *)addressBook {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"RHAddressBook", nil);
        _addressBook = [addressBook retain];
    }
    return self;
}

#define RN(x) [x release]; x = nil;
- (void)dealloc{
    RN(_addressBook);
    RN(_sources);
    RN(_groups);
    RN(_people);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self]; //for the ab externally changed notifications 
    
    [super dealloc];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(addressBookChanged:) name:RHAddressBookExternalChangeNotification object:nil];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.allowsSelectionDuringEditing = YES;

}

- (void)viewDidUnload {
    [super viewDidUnload];

    //discard our cached values
    RN(_sources);
    RN(_groups);
    RN(_people);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:RHAddressBookExternalChangeNotification object:nil];
     
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];

    NSArray* paths = [NSArray arrayWithObjects:
                      [NSIndexPath indexPathForRow:[_groups count] inSection:kRHAddressBookViewControllerGroupsSection],
                      [NSIndexPath indexPathForRow:[_people count] inSection:kRHAddressBookViewControllerPeopleSection],
                       nil];
        
    if(editing) {
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kRHAddressBookViewControllerNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kRHAddressBookViewControllerInfoSection){
        return kRHAddressBookViewControllerInfoCellsCount;
    } else if (section == kRHAddressBookViewControllerLocationSection){
        return kRHAddressBookViewControllerLocationCellsCount;
    } else if (section == kRHAddressBookViewControllerSourcesSection){
        [_sources release];
        _sources = [[_addressBook sources] mutableCopy];
        return [_sources count];
    } else if (section == kRHAddressBookViewControllerGroupsSection){
        [_groups release];
        _groups = [[_addressBook groups] mutableCopy];
        return [_groups count] + self.tableView.editing; //to allow for + button
    } else if (section == kRHAddressBookViewControllerPeopleSection){
        [_people release];
        _people = [[_addressBook peopleOrderedByUsersPreference] mutableCopy];
        return [_people count] + self.tableView.editing;  //to allow for + button
    } 
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"RHAddressBookViewControllerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
    }
    //reset
    cell.textLabel.text = nil;
    
    switch (indexPath.section) {
        case kRHAddressBookViewControllerInfoSection:    [self configureCell:cell forInfoAtRow:indexPath.row]; break;
        case kRHAddressBookViewControllerLocationSection:[self configureCell:cell forLocationAtRow:indexPath.row]; break;
        case kRHAddressBookViewControllerSourcesSection: [self configureCell:cell forSourceAtRow:indexPath.row]; break;
        case kRHAddressBookViewControllerGroupsSection:  [self configureCell:cell forGroupAtRow:indexPath.row]; break;
        case kRHAddressBookViewControllerPeopleSection:  [self configureCell:cell forPersonAtRow:indexPath.row]; break;
    }  
    
    return cell;
}

-(NSString*)titleForSection:(NSInteger)section {
    switch (section) {
        case kRHAddressBookViewControllerInfoSection:    return NSLocalizedString(@"Info", nil);
        case kRHAddressBookViewControllerSourcesSection: return NSLocalizedString(@"Sources", nil);
        case kRHAddressBookViewControllerGroupsSection:  return NSLocalizedString(@"Groups", nil);
        case kRHAddressBookViewControllerPeopleSection:  return NSLocalizedString(@"People", nil);
        case kRHAddressBookViewControllerLocationSection:  return NSLocalizedString(@"Location", nil);
            
        default: return nil;
    }
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [self titleForSection:section];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //groups and people can be edited    
    if (indexPath.section == kRHAddressBookViewControllerGroupsSection) return YES;
    if (indexPath.section == kRHAddressBookViewControllerPeopleSection) return YES;
    
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kRHAddressBookViewControllerGroupsSection && indexPath.row >= [_groups count]) return UITableViewCellEditingStyleInsert;
    if (indexPath.section == kRHAddressBookViewControllerPeopleSection && indexPath.row >= [_people count]) return UITableViewCellEditingStyleInsert;
    
    return UITableViewCellEditingStyleDelete;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.section == kRHAddressBookViewControllerGroupsSection) {
            RHGroup *group = [[_addressBook groups] objectAtIndex:indexPath.row];
            [group remove];
            [_addressBook save];
        } else if (indexPath.section == kRHAddressBookViewControllerPeopleSection) {
            RHPerson *person = [[_addressBook peopleOrderedByUsersPreference] objectAtIndex:indexPath.row];
            [person remove];
            [_addressBook save];
        }
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        if (indexPath.section == kRHAddressBookViewControllerGroupsSection) {
            [self addNewGroup];
        } else if (indexPath.section == kRHAddressBookViewControllerPeopleSection) {
            [self addNewPerson];
        }
    }   
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *pushController = nil;
    
    if (indexPath.section == kRHAddressBookViewControllerSourcesSection && indexPath.row < [_sources count]){
        
    } else if (indexPath.section == kRHAddressBookViewControllerGroupsSection && indexPath.row < [_groups count]) {
        RHGroup *group = [_groups objectAtIndex:indexPath.row];
        pushController = [[RHGroupViewController alloc] initWithGroup:group];
        
    } else if (indexPath.section == kRHAddressBookViewControllerPeopleSection && indexPath.row < [_people count]) {

        //TODO: push our own viewer view, for now just use the AB default one.
        RHPerson *person = [_people objectAtIndex:indexPath.row];
        
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

    } else if (indexPath.section == kRHAddressBookViewControllerLocationSection){
        //toggle location
#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
        [RHAddressBook setPreemptiveGeocodingEnabled:![RHAddressBook isPreemptiveGeocodingEnabled]];
#endif
#endif //end Geocoding
        
    [[self.tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
        [self.tableView reloadData];
        
    } else if (indexPath.section == kRHAddressBookViewControllerGroupsSection) { //fall through to creation
        [self addNewGroup];
    } else if (indexPath.section == kRHAddressBookViewControllerPeopleSection) {
        [self addNewPerson];
    }
    
    if (pushController){
        [self.navigationController pushViewController:pushController animated:YES];
        [pushController release];
    }
    
}

#pragma mark - cell config

-(void)configureCell:(UITableViewCell*)cell forInfoAtRow:(NSInteger)row{
    cell.textLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (row) {
            
        case 0: cell.textLabel.text = [NSString stringWithFormat:@"sortOrdering = %i", [RHAddressBook sortOrdering]]; break;
        case 1: cell.textLabel.text = [NSString stringWithFormat:@"compositeNameFormat = %i", [RHAddressBook compositeNameFormat]]; break;
        default: cell.textLabel.text = NSLocalizedString(@"-", nil);
    }
    
}

-(void)configureCell:(UITableViewCell*)cell forLocationAtRow:(NSInteger)row{
    cell.textLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    switch (row) {
            
#if RH_AB_INCLUDE_GEOCODING
        case 0: cell.textLabel.text = [NSString stringWithFormat:@"GeocodingSupported = %i", [RHAddressBook isGeocodingSupported]]; break;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
        case 2: cell.textLabel.text = [NSString stringWithFormat:@"GeocodingProgress = %f", [_addressBook preemptiveGeocodingProgress]]; break;
        case 1: cell.textLabel.text = [NSString stringWithFormat:@"GeocodingEnabled = %i", [RHAddressBook isPreemptiveGeocodingEnabled]]; break;
        case 3: cell.textLabel.text = @"Toggle Geocoding"; cell.selectionStyle = UITableViewCellSelectionStyleBlue; break;
#endif
        default: cell.textLabel.text = NSLocalizedString(@"-", nil);
#else
        default: cell.textLabel.text = NSLocalizedString(@"No Geo Support", nil);
#endif //end Geocoding
    }
    
}

-(void)configureCell:(UITableViewCell*)cell forSourceAtRow:(NSInteger)row{
    RHSource *source = [_sources objectAtIndex:row];
    
    if ([source isEqual:[_addressBook defaultSource]]){
        cell.textLabel.text = NSLocalizedString(@"Default Source", nil);
        
    } else {
        cell.textLabel.text = source.compositeName;
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
}
-(void)configureCell:(UITableViewCell*)cell forGroupAtRow:(NSInteger)row{
    if (row < [_groups count]){
        RHGroup *group = [_groups objectAtIndex:row];
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ - %lu Members",nil), group.compositeName, (unsigned long)[[group members] count]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    } else {
        //assume adding a new row
        cell.textLabel.text = NSLocalizedString(@"Add New Group...", nil); 
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
}
-(void)configureCell:(UITableViewCell*)cell forPersonAtRow:(NSInteger)row{
    if (row < [_people count]){
        RHPerson *person = [_people objectAtIndex:row];
        cell.textLabel.text = person.compositeName;
        cell.imageView.image = person.thumbnail;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    } else {
        //assume adding a new row
        cell.textLabel.text = NSLocalizedString(@"Add New Person...", nil);
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - add new objects
-(void)addNewGroup{
    RHGroup *group = [_addressBook newGroupInDefaultSource];
    group.name = NSLocalizedString(@"New Group", nil);
    [_addressBook save];
    [_groups addObject:group];
    [group release];
}

-(void)addNewPerson{
    RHPerson *person = [_addressBook newPersonInDefaultSource];
    person.firstName = NSLocalizedString(@"New Person", nil);
    [_addressBook save];
    [_people addObject:person];
    [person release];
}

#pragma mark - addressBookChangedNotification
-(void)addressBookChanged:(NSNotification*)notification{
    [_addressBook revert]; //so we pick up the remove changes
    [self.tableView reloadData];
}

@end


