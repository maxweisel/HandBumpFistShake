//
//  VideoPlayer.m
//  HandBump
//
//  Created by Max Weisel on 7/12/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "VideoPlayer.h"
#import <AVFoundation/AVFoundation.h>

@implementation VideoPlayer {
    AVPlayer *_player;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]) != nil) {
        NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"SAXGUY" ofType:@"mp4"];
        NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
        
        _player = [AVPlayer playerWithURL:videoURL];
        
        _player.volume = 2.0f;
        
        CALayer *layer = self.layer;
        layer.backgroundColor = [UIColor blackColor].CGColor;
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        playerLayer.frame = layer.bounds;
        [layer addSublayer:playerLayer];
        
        [_player play];
    }
    return self;
}

- (void)dealloc {
    
}

- (void)stop {
    [_player pause];
}

@end
