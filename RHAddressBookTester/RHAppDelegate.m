//
//  RHAppDelegate.m
//  RHAddressBookTester
//
//  Created by Richard Heard on 13/11/11.
//  Copyright (c) 2011 Richard Heard. All rights reserved.
//

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
