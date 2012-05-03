//
//  AppDelegate.h
//  Firefly
//
//  Created by kampfgnu on 4/27/12.
//  Copyright (c) 2012 NOUS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KGWindow.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, KGWindowDelegate>

@property (strong, nonatomic) KGWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

@end
