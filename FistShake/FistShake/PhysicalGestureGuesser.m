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

- (instancetype)initWithType:(Interaction)Interaction
                    minPitch:(double)minPitch
                    maxPitch:(double)maxPitch
                     minRoll:(double)minRoll
                     maxRoll:(double)maxRoll;

// How confident are we that the attitude describes this gesture?
- (double)distance:(CMAttitude *)attitude;

@property(nonatomic, readonly) Interaction Interaction;
@property(nonatomic) double minPitch;
@property(nonatomic) double maxPitch;
@property(nonatomic) double minRoll;
@property(nonatomic) double maxRoll;

@end

@implementation PhysicalGesture

- (instancetype)initWithType:(Interaction)Interaction
                    minPitch:(double)minPitch
                    maxPitch:(double)maxPitch
                     minRoll:(double)minRoll
                     maxRoll:(double)maxRoll {
    self = [super init];
    if (self) {
        _Interaction = Interaction;
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

        _handshake = [[PhysicalGesture alloc] initWithType:Handshake minPitch:0.87 maxPitch:1.30 minRoll:-1.98 maxRoll:-1.36];
        _fistBump = [[PhysicalGesture alloc] initWithType:FistBump minPitch:-0.20 maxPitch:-0.03 minRoll:3.14 maxRoll:3.14];  // shitty
        _highFive = [[PhysicalGesture alloc] initWithType:HighFive minPitch:-0.11 maxPitch:0.01 minRoll:1.72 maxRoll:2.11];
        _hug = [[PhysicalGesture alloc] initWithType:Hug minPitch:0.29 maxPitch:1.07 minRoll:-2.48 maxRoll:-2.15];

        _gestures = @[_handshake, _fistBump, _highFive, _hug];

        // Currently ignored.
        _threshold = threshold;
    }
    return self;
}

- (instancetype)init {
    return [self initWithThreshold:.2];
}

- (Interaction)bestGuessFromAttitude:(CMAttitude *)attitude {

    Interaction whichGesture = None;
    double minDistance = 1000000000;

    for (PhysicalGesture *physicalGesture in _gestures) {
        double distance = [physicalGesture distance:attitude];
        if (distance < minDistance) {
            minDistance = distance;
            whichGesture = physicalGesture.Interaction;
        }
    }

    return whichGesture;


    // Can we reverse-engineer this, write the archived version, and decode?
    //    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:attitude];
    //    NSLog(@"encoded attitude: %@", data);

}

+ (NSString *)stringForInteraction:(Interaction)interaction {
    switch (interaction) {
        case None:
            return @"None";
        case Handshake:
            return @"Handshake";
        case FistBump:
            return @"Fist Bump";
        case HighFive:
            return @"High Five";
        case BroHug:
            return @"Bro Hug";
        case Hug:
            return @"Hug";
        default:
            break;
    }
    return @"<Interaction Not Found>";
}

+ (Interaction)interactionForString:(NSString *)str {
    if ([str isEqualToString:@"None"]) {
        return None;
    }
    if ([str isEqualToString:@"Handshake"]) {
        return Handshake;
    }
    if ([str isEqualToString:@"Fist Bump"]) {
        return FistBump;
    }
    if ([str isEqualToString:@"HighFive"]) {
        return HighFive;
    }
    if ([str isEqualToString:@"BroHug"]) {
        return BroHug;
    }
    if ([str isEqualToString:@"Hug"]) {
        return Hug;
    }

    return None;
}

@end
