//
//  GamePlayViewController.m
//  HandBump
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "GamePlayViewController.h"
#import "CutSceneViewController.h"

@implementation GamePlayViewController

- (instancetype)init {
    if ((self = [super init]) != nil) {
        self.view.backgroundColor = [UIColor blueColor];
    }
    return self;
}

- (void)dealloc {
    
}

- (void)startGame {
    [self showCutScene];
}

- (void)showCutScene {
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"movie1" ofType:@"mov"];
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    
    CutSceneViewController *cutSceneViewController = [[CutSceneViewController alloc] initWithVideoURL:videoURL];
    [cutSceneViewController.player play];
    [self presentViewController:cutSceneViewController animated:YES completion:nil];
}

@end
