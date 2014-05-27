//
//  RHAppDelegate.m
//  RHAddressBookTester
//
//  Created by Richard Heard on 13/11/11.
//  Copyright (c) 2011 Richard Heard. All rights reserved.
//


#define PERF_TEST_SETUP 0
#define PERF_TEST 1

#import "RHAppDelegate.h"

#import "RHAddressBookViewController.h"

#import <RHAddressBook/AddressBook.h>

@implementation RHAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;

-(void)dealloc
{
    [_window release];
    [_navigationController release];
    [super dealloc];
}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.

    //perf setup. 5000 contacts
#if PERF_TEST_SETUP
    RHAddressBook *sab = [[[RHAddressBook alloc] init] autorelease];
    int count = 5000 - [sab numberOfPeople];
    while (count > 0) {
        RHPerson *new = [sab newPersonInDefaultSource];
        new.firstName = [NSString stringWithFormat:@"T1 %i", count];
        new.lastName = [NSString stringWithFormat:@"T2 %i", count];
        count--;
    }
    [sab save];
    NSLog(@"setup complete");
    exit(EXIT_SUCCESS);
#endif
    
#if PERF_TEST
    clock_t start_time = 0;
    clock_t end_time = 0;
    
    start_time = clock();
    RHAddressBook *pab = [[[RHAddressBook alloc] init] autorelease];
    end_time = clock();

    NSLog(@"PERF: Init took %f seconds.", (double)(end_time - start_time) / (double)CLOCKS_PER_SEC);

    start_time = clock();
    NSArray *people = [pab people];
    end_time = clock();
    
    NSLog(@"PERF: First people call took %f seconds. (for %lu people)", (double)(end_time - start_time) / (double)CLOCKS_PER_SEC, (unsigned long)[people count]);

    start_time = clock();
    NSArray *people2 = [pab people];
    end_time = clock();
    
    NSLog(@"PERF: Second people call took %f seconds. (for %lu people)", (double)(end_time - start_time) / (double)CLOCKS_PER_SEC, (unsigned long)[people2 count]);

    start_time = clock();
    [pab save];
    end_time = clock();
    
    NSLog(@"PERF: Save call took %f seconds. (for %lu people)", (double)(end_time - start_time) / (double)CLOCKS_PER_SEC, (unsigned long)[people2 count]);

#endif

    RHAddressBook *ab = [[[RHAddressBook alloc] init] autorelease];
    RHAddressBookViewController *abViewController = [[[RHAddressBookViewController alloc] initWithAddressBook:ab] autorelease];
    self.navigationController = [[[UINavigationController alloc] initWithRootViewController:abViewController] autorelease];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];

    
    
    
    
    //if not yet authorized, force an auth.
    if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined){
        [ab requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
            [abViewController setAddressBook:ab];
        }];
    }

    // warn re being denied access to contacts
    if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusDenied){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"RHAuthorizationStatusDenied" message:@"Access to the addressbook is currently denied." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }

    // warn re restricted access to contacts
    if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusRestricted){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"RHAuthorizationStatusRestricted" message:@"Access to the addressbook is currently restricted." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
    return YES;
}

-(void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

-(void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
