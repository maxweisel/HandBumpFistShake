//
//  PhysicalInteraction.m
//  FistShake
//
//  Created by Andrea Huey on 7/12/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "PhysicalInteraction.h"

@implementation PhysicalInteraction

+ (NSString *)stringForInteractionType:(InteractionType)interactionType {
    switch (interactionType) {
        case None:
            return @"None";
        case Handshake:
            return @"Handshake";
        case FistBump:
            return @"Fist Bump";
        case HighFive:
            return @"High Five";
        case Hug:
            return @"Hug";
        case HugSlap:
            return @"Hug Slap";
        default:
            break;
    }
    return @"<Interaction Not Found>";
}

+ (InteractionType)interactionForString:(NSString *)str {
    if ([str isEqualToString:@"None"]) {
        return None;
    }
    if ([str isEqualToString:@"Handshake"]) {
        return Handshake;
    }
    if ([str isEqualToString:@"Fist Bump"]) {
        return FistBump;
    }
    if ([str isEqualToString:@"High Five"]) {
        return HighFive;
    }
    if ([str isEqualToString:@"Hug"]) {
        return Hug;
    }
    if ([str isEqualToString:@"Hug Slap"]) {
        return HugSlap;
    }

    return None;
}


@end
