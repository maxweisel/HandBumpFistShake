//
//  CutSceneViewController.m
//  HandBump
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "CutSceneViewController.h"

@implementation CutSceneViewController

- (instancetype)initWithVideoURL:(NSURL *)videoURL {
    if ((self = [super init]) != nil) {
        _player = [AVPlayer playerWithURL:videoURL];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CALayer *layer = self.view.layer;
    layer.backgroundColor = [UIColor blackColor].CGColor;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = layer.bounds;
    [layer addSublayer:playerLayer];
}

- (void)itemDidFinishPlaying:(NSNotification *)notification {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
