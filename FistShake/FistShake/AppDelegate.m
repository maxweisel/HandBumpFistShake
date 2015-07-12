//
//  AppDelegate.m
//  FistShake
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "AppDelegate.h"
#import "AppController.h"
#import "MainViewController.h"
#import "TestViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate {
    AppController *_controller;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Create the first instance. Hold for the lifetime of the application.
    _controller = [[AppController alloc] init];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[MainViewController alloc] init];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    return YES;
}

@end
