//
//  AppController.h
//  FistShake
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhysicalGestureGuesser.h" // gross

@protocol AppControllerDelegate <NSObject>
- (void)useNewGesture:(Interaction)gesture;
@end

@interface AppController : NSObject

+ (instancetype)currentInstance;

@property (nonatomic, weak) id<AppControllerDelegate> delegate;

- (void)sendValue:(id<NSCoding>)value forKey:(NSString *)key;

@end
