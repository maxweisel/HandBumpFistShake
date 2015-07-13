//
//  PhysicalInteraction.h
//  FistShake
//
//  Created by Andrea Huey on 7/12/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, InteractionType) {
    None = 0,
    Handshake = 1,
    FistBump = 2,
    HighFive = 3,
    BroHug = 4,
    Hug = 5,
    Last,
};

@class CMAttitude;

@interface PhysicalInteraction : NSObject

+ (NSString *)stringForInteractionType:(InteractionType)interactionType;
+ (InteractionType)interactionForString:(NSString *)str;

@end
