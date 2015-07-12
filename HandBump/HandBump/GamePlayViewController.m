//
//  GamePlayViewController.m
//  HandBump
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "GamePlayViewController.h"
#import "CutSceneViewController.h"
#import "AppController.h"
#import "VideoPlayer.h"

typedef enum {
    GSStart = 0,
    GSTeam1Playing,
    GSTeam2Playing,
    GSTeam1Wins,
    GSTeam2Wins,
} GameState;

typedef enum {
    None = 0,
    Handshake = 1,
    FistBump = 2,
    HighFive = 3,
    BroHug = 4,
    Hug = 5,
} Interaction;

#define FLASH_TIME 0.5f

@implementation GamePlayViewController {
    GameState _state;
    UIImageView *_teamUp;
    UIImageView *_teamWims;
    NSTimer *_flashTimer;
    
    UIImageView *_interactionView;
    NSTimer *_interactionFlashTimer;
    
    UILabel *_team1Score;
    int _team1Points;
    UILabel *_team2Score;
    int _team2Points;
    
    Interaction _targetInteraction;
    NSString *_device1Peer;
    Interaction _device1Interaction;
    
    NSString *_device2Peer;
    Interaction _device2Interaction;
    
    int _numberOfCorrectGestureFrames;
    
    VideoPlayer *_videoPlayer;
    
    SystemSoundID dingSoung;
    
    SEL _nextSelector;
    
    BOOL _blockButton;
}

- (instancetype)init {
    if ((self = [super init]) != nil) {
        self.view.backgroundColor = [UIColor blackColor];
        
        _state = GSStart;
        [self updateGameUIForNewState];
        
        srand((unsigned int)time(NULL));
        
        NSString *successPath = [[NSBundle mainBundle] pathForResource:@"Success" ofType:@"aif"];
        NSURL *successURL = [NSURL fileURLWithPath:successPath];
        
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(successURL), &dingSoung);
    }
    return self;
}

- (void)dealloc {
    [_flashTimer invalidate];
    [_interactionFlashTimer invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //CGRect viewBounds = self.view.bounds;
    //CGPoint center = CGPointMake(CGRectGetMidX(viewBounds), CGRectGetMidY(viewBounds));
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MainScreen.png"]];
    [self.view addSubview:backgroundView];
    
    _teamUp = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"YouUp.png"]];
    _teamUp.hidden = YES;
    [self.view addSubview:_teamUp];
    
    _teamWims = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Winner.png"]];
    _teamWims.hidden = YES;
    [self.view addSubview:_teamWims];
    
    _team1Score = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 400.0f, 250.0f)];
    _team1Score.center = CGPointMake(248.0f, 500.0f);
    _team1Score.text = @"0";
    _team1Score.font = [UIFont fontWithName:@"04b03" size:200.0f];
    _team1Score.textAlignment = NSTextAlignmentCenter;
    _team1Score.textColor = [UIColor whiteColor];
    [self.view addSubview:_team1Score];
    
    _team2Score = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 400.0f, 250.0f)];
    _team2Score.center = CGPointMake(self.view.bounds.size.width - 248.0f, 500.0f);
    _team2Score.text = @"0";
    _team2Score.font = [UIFont fontWithName:@"04b03" size:200.0f];
    _team2Score.textAlignment = NSTextAlignmentCenter;
    _team2Score.textColor = [UIColor whiteColor];
    [self.view addSubview:_team2Score];
}

- (void)startGame {
    AppController *controller = [AppController currentInstance];
    controller.gamePlayViewController = self;
    
    NSLog(@"Waiting for peers to connect.");
    [self tryPeers];
    
    _team1Points = 0;
    _team2Points = 0;
    [self updateScoreUI];
}

- (void)tryPeers {
    AppController *controller = [AppController currentInstance];
    NSArray *peers = controller.connectedPeers;
    NSLog(@"%lu peer(s) connected. Waiting for 2 to start.", (unsigned long)peers.count);
    if (peers.count >= 2) {
        NSLog(@"Peers have connected. Starting game.");
        [self startTeam1];
        _device1Peer = peers[0];
        _device2Peer = peers[1];
    } else {
        [self performSelector:@selector(tryPeers) withObject:nil afterDelay:0.5f];
    }
}

- (void)startTeam1 {
    _state = GSTeam1Playing;
    [self updateGameUIForNewState];
    
    _device1Interaction = None;
    _device2Interaction = None;
    
    [self performSelector:@selector(startTeam1_) withObject:nil afterDelay:2.0f];
}

- (void)startTeam1_ {
    _videoPlayer = [[VideoPlayer alloc] initWithFrame:CGRectMake(1024.0f - 40.0f - 1024.0f/7.0f, 768.0f - 40.0f - 768.0f/7.0f, 1024.0f/7.0f, 768.0f/7.0f)];
    [self.view addSubview:_videoPlayer];
    
    // Start the first gesture
    [self sendNewGesture];
    
    // Start timer
    [self performSelector:@selector(blockButton) withObject:nil afterDelay:9.0f];
    [self performSelector:@selector(endRound1) withObject:nil afterDelay:15.0f];
}

- (void)blockButton {
    _blockButton = YES;
    [self performSelector:@selector(unblockButton) withObject:nil afterDelay:1.0f];
}

- (void)unblockButton {
    _blockButton = NO;
}

- (void)sendNewGesture {
    Interaction interaction = rand() % 5 + 1;
    if (interaction == _targetInteraction) {
        [self sendNewGesture];
        return;
    }
    _targetInteraction = interaction;
    [self displayInteraction:interaction];
    
    AppController *controller = [AppController currentInstance];
    [controller sendInteraction:[self interactionNameForInteraction:interaction]];
}

- (void)receivedInteraction:(NSNumber *)interaction fromDevice:(NSString *)device {
    if (_targetInteraction == None) {
        NSLog(@"Ignoring interaction from the device.");
        return;
    }
    
    if ([device isEqualToString:_device1Peer]) {
        _device1Interaction = [interaction intValue];
    } else if ([device isEqualToString:_device2Peer]) {
        _device2Interaction = [interaction intValue];
    }
    
    if (_device1Interaction == _targetInteraction && _device2Interaction == _targetInteraction && _device1Interaction != None && _device2Interaction != None) {
        _numberOfCorrectGestureFrames++;
    } else {
        _numberOfCorrectGestureFrames = 0;
    }
    
    if (_numberOfCorrectGestureFrames > 10) {
        // Award point
        if (_state == GSTeam1Playing) {
            _team1Points++;
            [self ding];
        } else if (_state == GSTeam2Playing) {
            _team2Points++;
            [self ding];
        }
        [self updateScoreUI];
        
        [self sendNewGesture];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_blockButton)
        return;
    
    CGPoint point = [[touches anyObject] locationInView:self.view];
    if (point.x > 900.0f && point.y > 600.0f) {
        if (_state == GSStart) {
            [self startTeam1];
        } else {
            if (_targetInteraction == None) {
                // Lame hack to see if we've started round two yet or not.
                [self startTeam2];
            } else {
                // Award point
                if (_state == GSTeam1Playing) {
                    _team1Points++;
                    [self ding];
                } else if (_state == GSTeam2Playing) {
                    _team2Points++;
                    [self ding];
                }
                [self updateScoreUI];
                
                [self sendNewGesture];
            }
        }
    }
}

- (void)ding {
    AudioServicesPlaySystemSound(dingSoung);
}

- (void)endRound1 {
    _targetInteraction = None;
    
    _state = GSTeam2Playing;
    [self updateGameUIForNewState];
    
    _device1Interaction = None;
    _device2Interaction = None;
    
    [_videoPlayer stop];
    [_videoPlayer removeFromSuperview];
    
    //[self performSelector:@selector(startTeam2) withObject:nil afterDelay:2.0f];
}

- (void)startTeam2 {
    _videoPlayer = [[VideoPlayer alloc] initWithFrame:CGRectMake(1024.0f - 40.0f - 1024.0f/7.0f, 768.0f - 40.0f - 768.0f/7.0f, 1024.0f/7.0f, 768.0f/7.0f)];
    [self.view addSubview:_videoPlayer];
    
    // Start the first gesture
    [self sendNewGesture];
    
    // Start timer
    [self performSelector:@selector(endRound2) withObject:nil afterDelay:15.0f];
}

- (void)endRound2 {
    _targetInteraction = None;
    
    [_videoPlayer stop];
    [_videoPlayer removeFromSuperview];
    
    if (_team1Points >= _team2Points) {
        _state = GSTeam1Wins;
        [self updateGameUIForNewState];
    } else {
        _state = GSTeam2Wins;
        [self updateGameUIForNewState];
    }
    
    [self performSelector:@selector(showCutScene1) withObject:nil afterDelay:4.0f];
}

- (void)showCutScene1 {
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"Cutscene1" ofType:@"mp4"];
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    
    CutSceneViewController *cutSceneViewController = [[CutSceneViewController alloc] initWithVideoURL:videoURL];
    [cutSceneViewController.player play];
    [self presentViewController:cutSceneViewController animated:YES completion:nil];
}

- (void)showCutScene2 {
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"Cutscene2" ofType:@"mp4"];
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    
    CutSceneViewController *cutSceneViewController = [[CutSceneViewController alloc] initWithVideoURL:videoURL];
    [cutSceneViewController.player play];
    [self presentViewController:cutSceneViewController animated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)updateGameUIForNewState {
    switch (_state) {
        case GSStart:
        {
            _teamUp.hidden = YES;
            _teamWims.hidden = YES;
            
            [_flashTimer invalidate];
            _flashTimer = nil;
        }
            break;
        case GSTeam1Playing:
        {
            _teamUp.hidden = NO;
            CGRect teamUpFrame = _teamUp.frame;
            teamUpFrame.origin = CGPointMake(62.0f, 77.0f);
            _teamUp.frame = teamUpFrame;
            _teamWims.hidden = YES;
            
            [_flashTimer invalidate];
            _flashTimer = [NSTimer scheduledTimerWithTimeInterval:FLASH_TIME target:self selector:@selector(flashView:) userInfo:_teamUp repeats:YES];
            
            [self displayInteraction:None];
        }
            break;
        case GSTeam2Playing:
        {
            _teamUp.hidden = NO;
            CGRect teamUpFrame = _teamUp.frame;
            teamUpFrame.origin = CGPointMake(self.view.bounds.size.width - teamUpFrame.size.width - 62.0f, 77.0f);
            _teamUp.frame = teamUpFrame;
            _teamWims.hidden = YES;
            
            [_flashTimer invalidate];
            _flashTimer = [NSTimer scheduledTimerWithTimeInterval:FLASH_TIME target:self selector:@selector(flashView:) userInfo:_teamUp repeats:YES];
            
            [self displayInteraction:None];
        }
            break;
        case GSTeam1Wins:
        {
            _teamUp.hidden = YES;
            _teamWims.hidden = NO;
            CGRect teamWinsFrame = _teamWims.frame;
            teamWinsFrame.origin = CGPointMake(62.0f, 77.0f);
            _teamWims.frame = teamWinsFrame;
            
            [_flashTimer invalidate];
            _flashTimer = [NSTimer scheduledTimerWithTimeInterval:FLASH_TIME target:self selector:@selector(flashView:) userInfo:_teamWims repeats:YES];
            
            [self displayInteraction:None];
        }
            break;
        case GSTeam2Wins:
        {
            _teamUp.hidden = YES;
            _teamWims.hidden = NO;
            CGRect teamWinsFrame = _teamWims.frame;
            teamWinsFrame.origin = CGPointMake(self.view.bounds.size.width - teamWinsFrame.size.width - 62.0f, 77.0f);
            _teamWims.frame = teamWinsFrame;
            
            [_flashTimer invalidate];
            _flashTimer = [NSTimer scheduledTimerWithTimeInterval:FLASH_TIME target:self selector:@selector(flashView:) userInfo:_teamWims repeats:YES];
            
            [self displayInteraction:None];
        }
            break;
        default:
            break;
    }
}

- (void)flashView:(NSTimer *)timer {
    UIView *flashView = timer.userInfo;
    flashView.hidden = !flashView.hidden;
}

- (void)displayInteraction:(Interaction)interaction {
    [_interactionView removeFromSuperview];
    _interactionView = nil;
    [_interactionFlashTimer invalidate];
    _interactionFlashTimer = nil;
    
    CGRect viewBounds = self.view.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(viewBounds), CGRectGetMidY(viewBounds));
    
    switch (interaction) {
        case Handshake:
            _interactionView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Handshake.png"]];
            break;
        case FistBump:
            _interactionView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FistBump.png"]];
            break;
        case HighFive:
            _interactionView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HighFive.png"]];
            break;
        case BroHug:
            _interactionView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BroHug.png"]];
            break;
        case Hug:
            _interactionView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Hug.png"]];
            break;
        default:
            break;
    }
    
    _interactionView.center = center;
    [self.view addSubview:_interactionView];
    
    _interactionFlashTimer = [NSTimer scheduledTimerWithTimeInterval:0.25f target:self selector:@selector(flashInteraction:) userInfo:nil repeats:YES];
    UIView *v = _interactionView;
    NSTimer *t = _interactionFlashTimer;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [v removeFromSuperview];
        [t invalidate];
    });
}

- (void)flashInteraction:(NSTimer *)timer {
    _interactionView.hidden = !_interactionView.hidden;
}

- (NSString *)interactionNameForInteraction:(Interaction)interaction {
    switch (interaction) {
        case None:
            return @"None";
        case Handshake:
            return @"Handshake";
        case FistBump:
            return @"Fist Bump";
        case HighFive:
            return @"High Five";
        case BroHug:
            return @"Bro Hug";
        case Hug:
            return @"Hug";
        default:
            break;
    }
    return @"<Interaction Not Found>";
}

- (void)updateScoreUI {
    _team1Score.text = [NSString stringWithFormat:@"%i", _team1Points];
    _team2Score.text = [NSString stringWithFormat:@"%i", _team2Points];
}

@end
