//
//  PhysicalGestureGuesser.h
//  FistShake
//
//  Created by Andrea Huey on 7/12/15.
//  Copyright © 2015 Organization Name. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMAttitude;

typedef NS_ENUM(NSInteger, PhysicalGestureEnum) {
    Unknown,
    FistBump,
    Handshake,
    HighFive,
    Hug,
    HugSlap,
};

@interface PhysicalGestureGuesser : NSObject

- (instancetype)initWithThreshold:(double)threshold NS_DESIGNATED_INITIALIZER;

// Make the best guess at which gesture the user performed.
// If the attitude change between every physical gesture and |attitude| is
// greater than |threshold|, return Unknown.
- (PhysicalGestureEnum)bestGuessFromAttitude:(CMAttitude *)attitude;

// If all attitude magnitudes are greater than this threshold, assume there is no gesture.
@property(nonatomic, assign) double threshold;

+ (NSString *)stringForGestureEnum:(PhysicalGestureEnum)gestureEnum;

@end
