//
//  AppController.h
//  HandBump
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GamePlayViewController;

@interface AppController : NSObject

+ (instancetype)currentInstance;

@property (nonatomic, readonly) NSArray *connectedPeers;

- (void)sendInteraction:(NSString *)interaction;

@property (nonatomic, weak) GamePlayViewController *gamePlayViewController;

@end
