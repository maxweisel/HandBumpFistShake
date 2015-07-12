//
//  StartScreenViewController.m
//  HandBump
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "StartScreenViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GamePlayViewController.h"

@implementation StartScreenViewController {
    AVPlayer *_player;
    UIButton *_startButton;
}

- (instancetype)init {
    if ((self = [super init]) != nil) {
        NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"intro" ofType:@"mp4"];
        NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
        
        _player = [AVPlayer playerWithURL:videoURL];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)itemDidFinishPlaying:(NSNotification *)notification {
    [UIView animateWithDuration:0.4f animations:^{
        _startButton.alpha = 1.0f;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect viewBounds = self.view.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(viewBounds), CGRectGetMidY(viewBounds));
    
    CALayer *layer = self.view.layer;
    layer.backgroundColor = [UIColor blackColor].CGColor;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = layer.bounds;
    [layer addSublayer:playerLayer];
    
    UIImage *image = [UIImage imageNamed:@"Go.png"];
    _startButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _startButton.frame = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    [_startButton setBackgroundImage:image forState:UIControlStateNormal];
    _startButton.titleLabel.font = [UIFont systemFontOfSize:80.0f];
    _startButton.center = CGPointMake(center.x, viewBounds.size.height - 180.0f);
    [_startButton addTarget:self action:@selector(go:) forControlEvents:UIControlEventTouchUpInside];
    _startButton.alpha = 0.0f;
    [self.view addSubview:_startButton];
}

- (void)go:(UIButton *)button {
    GamePlayViewController *gamePlayViewController = [[GamePlayViewController alloc] init];
    [self presentViewController:gamePlayViewController animated:YES completion:nil];
    [gamePlayViewController startGame];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_player play];
}

@end
