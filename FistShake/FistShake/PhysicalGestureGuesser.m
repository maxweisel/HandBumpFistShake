//
//  PhysicalGestureGuesser.m
//  FistShake
//
//  Created by Andrea Huey on 7/12/15.
//  Copyright © 2015 Organization Name. All rights reserved.
//

#import "PhysicalGestureGuesser.h"
#import <CoreMotion/CoreMotion.h>


@interface PhysicalGesture : NSObject

- (instancetype)initWithEnum:(PhysicalGestureEnum)gestureEnum
                    minPitch:(double)minPitch
                    maxPitch:(double)maxPitch
                     minRoll:(double)minRoll
                     maxRoll:(double)maxRoll;

// How confident are we that the attitude describes this gesture?
- (double)distance:(CMAttitude *)attitude;

@property(nonatomic, readonly) PhysicalGestureEnum gestureEnum;
@property(nonatomic) double minPitch;
@property(nonatomic) double maxPitch;
@property(nonatomic) double minRoll;
@property(nonatomic) double maxRoll;

@end

@implementation PhysicalGesture

- (instancetype)initWithEnum:(PhysicalGestureEnum)gestureEnum
                    minPitch:(double)minPitch
                    maxPitch:(double)maxPitch
                     minRoll:(double)minRoll
                     maxRoll:(double)maxRoll {
    self = [super init];
    if (self) {
        _gestureEnum = gestureEnum;
        _minPitch = minPitch;
        _maxPitch = maxPitch;
        _minRoll = minRoll;
        _maxRoll = maxRoll;
    }
    return self;
}

- (double)distance:(CMAttitude *)attitude {
    double pitchDelta = 10000;
    double rollDelta = 10000;


    // Should be utility method/function.
    double pitch = attitude.pitch;
    if (_minPitch < pitch && pitch < _maxPitch) {
        pitchDelta = 0;
    } else {
        double distanceFromMin = _minPitch - pitch;
        double distanceFromMax = pitch - _maxPitch;
        pitchDelta = MIN(distanceFromMin, distanceFromMax);
    }

    double roll = attitude.roll;
    if (_minRoll < roll && roll < _maxRoll) {
        rollDelta = 0;
    } else {
        double distanceFromMin = _minRoll - roll;
        double distanceFromMax = roll - _maxRoll;
        pitchDelta = MIN(distanceFromMin, distanceFromMax);
    }

    return sqrt(pow(rollDelta, 2) + pow(pitchDelta, 2));
}

@end

@implementation PhysicalGestureGuesser {
    PhysicalGesture *_handshake;
    PhysicalGesture *_fistBump;
    PhysicalGesture *_highFive;
    PhysicalGesture *_hug;

    NSArray *_gestures;
}

- (instancetype)initWithThreshold:(double)threshold {
    self = [super init];
    if (self) {

        _handshake = [[PhysicalGesture alloc] initWithEnum:Handshake minPitch:0.87 maxPitch:1.30 minRoll:-1.98 maxRoll:-1.36];
        _fistBump = [[PhysicalGesture alloc] initWithEnum:FistBump minPitch:-0.20 maxPitch:-0.03 minRoll:3.14 maxRoll:3.14];  // shitty
        _highFive = [[PhysicalGesture alloc] initWithEnum:HighFive minPitch:-0.11 maxPitch:0.01 minRoll:1.72 maxRoll:2.11];
        _hug = [[PhysicalGesture alloc] initWithEnum:Hug minPitch:0.29 maxPitch:1.07 minRoll:-2.48 maxRoll:-2.15];

        _gestures = @[_handshake, _fistBump, _highFive, _hug];

        _threshold = threshold;
    }
    return self;
}

- (instancetype)init {
    return [self initWithThreshold:.2];
}

- (PhysicalGestureEnum)bestGuessFromAttitude:(CMAttitude *)attitude {

    PhysicalGestureEnum whichGesture = Unknown;
    double minDistance = 1000000000;

    for (PhysicalGesture *physicalGesture in _gestures) {
        double distance = [physicalGesture distance:attitude];
        if (distance < minDistance) {
            minDistance = distance;
            whichGesture = physicalGesture.gestureEnum;
        }
    }

    return whichGesture;


    // Can we reverse-engineer this, write the archived version, and decode?
    //    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:attitude];
    //    NSLog(@"encoded attitude: %@", data);

}

+ (NSString *)stringForGestureEnum:(PhysicalGestureEnum)gestureEnum {
    switch (gestureEnum) {
        case FistBump: return @"Fist Bump";
        case Handshake: return @"Handshake";
        case HighFive: return @"High Five";
        case Hug: return @"Hug";
        case HugSlap: return @"HugSlap";

        case Unknown:
        default:
            return @"Unknown";
    }
}

@end
