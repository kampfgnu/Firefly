//
//  AppDelegate.m
//  Firefly
//
//  Created by kampfgnu on 4/27/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import "AppDelegate.h"

#import "ActiveRecordHelpers.h"

#import "FileBrowserViewController.h"
#import "PlayerViewController.h"
#import "SettingsViewController.h"
#import "StreamerViewController.h"

#import "SongsViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) StreamerViewController *streamerViewController;

@end


@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
$synthesize(streamerViewController);

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [ActiveRecordHelpers setupCoreDataStack];
    
    self.window = [[KGWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.delegate = self;
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self.window becomeFirstResponder];

    SongsViewController *vc = [[SongsViewController alloc] initWithStyle:UITableViewStylePlain listType:ListTypeArtists queryString:nil];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.navigationBar.barStyle = UIBarStyleBlack;
    
//    FileBrowserViewController *fileBrowserViewController = [[FileBrowserViewController alloc] initWithNibName:@"FileBrowserViewController" bundle:[NSBundle mainBundle]];
//    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:fileBrowserViewController];
//    nc.navigationBar.barStyle = UIBarStyleBlack;
    
//    PlayerViewController *playerViewController = [[PlayerViewController alloc] initWithNibName:nil bundle:nil];
    self.streamerViewController = [[StreamerViewController alloc] initWithNibName:nil bundle:nil];
//    fileBrowserViewController.playerViewController = playerViewController;
    vc.streamerViewController = self.streamerViewController;
    
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStylePlain];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:nc, self.streamerViewController, settingsViewController, nil];
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)window:(KGWindow *)window remoteControlReceivedWithEvent:(UIEvent *)event {
    [self.streamerViewController remoteControlReceivedWithEvent:event];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
