//
//  PhysicalGestureGuesser.m
//  FistShake
//
//  Created by Andrea Huey on 7/12/15.
//  Copyright © 2015 Organization Name. All rights reserved.
//

#import "PhysicalGestureGuesser.h"
#import <CoreMotion/CoreMotion.h>

@implementation PhysicalGestureGuesser {
    NSDictionary *_gestureAttitudes;
}

- (instancetype)initWithThreshold:(double)threshold {
    self = [super init];
    if (self) {

        // Use the fist-bump as the "normal".
        _gestureAttitudes = @{
                              @"FistBump": [[CMAttitude alloc] init],
                              };

        // Any better way than the following?
//        CMAttitude *fistBump = [[CMAttitude alloc] initWithQuaternion:]



        _threshold = threshold;
    }
    return self;
}

- (instancetype)init {
    return [self initWithThreshold:.2];
}

- (PhysicalGesture)bestGuessFromAttitude:(CMAttitude *)attitude {

    // Can we reverse-engineer this, write the archived version, and decode?
//    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:attitude];
//    NSLog(@"encoded attitude: %@", data);

    return Unknown;
}

@end
