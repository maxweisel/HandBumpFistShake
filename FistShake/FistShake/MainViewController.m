//
//  MainViewController.m
//  FistShake
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "MainViewController.h"
#import <CoreMotion/CoreMotion.h>

@implementation MainViewController {
    CMMotionManager *_motionManager;
}

- (instancetype)init {
    if ((self = [super init]) != nil) {
        self.view.backgroundColor = [UIColor blackColor];
        
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 1.0f/60.0f;
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                NSLog(@"%f %f %f", motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw);
         }];
    }
    return self;
}

- (void)dealloc {
    [_motionManager stopDeviceMotionUpdates];
}

@end
