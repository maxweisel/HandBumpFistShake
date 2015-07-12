//
//  PhysicalGestureGuesser.h
//  FistShake
//
//  Created by Andrea Huey on 7/12/15.
//  Copyright © 2015 Organization Name. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMAttitude;

// Copied from HandBump/GameViewController.m
typedef NS_ENUM(NSInteger, Interaction) {
    None = 0,
    Handshake = 1,
    FistBump = 2,
    HighFive = 3,
    BroHug = 4,
    Hug = 5,
};


@interface PhysicalGestureGuesser : NSObject

- (instancetype)initWithThreshold:(double)threshold NS_DESIGNATED_INITIALIZER;

// Make the best guess at which gesture the user performed.
// If the attitude change between every physical gesture and |attitude| is
// greater than |threshold|, return Unknown.
- (Interaction)bestGuessFromAttitude:(CMAttitude *)attitude;

// If all attitude magnitudes are greater than this threshold, assume there is no gesture.
@property(nonatomic, assign) double threshold;

+ (NSString *)stringForInteraction:(Interaction)interaction;
+ (Interaction)interactionForString:(NSString *)str;

@end
