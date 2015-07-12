//
//  StartScreenViewController.m
//  HandBump
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "StartScreenViewController.h"
#import "GamePlayViewController.h"

@implementation StartScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect viewBounds = self.view.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(viewBounds), CGRectGetMidY(viewBounds));
    
    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TitleScreen.png"]];
    titleView.frame = viewBounds;
    //titleView.center = center;
    [self.view addSubview:titleView];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    startButton.frame = CGRectMake(0.0f, 0.0f, 200.0f, 88.0f);
    [startButton setTitle:@"Go!" forState:UIControlStateNormal];
    startButton.titleLabel.font = [UIFont systemFontOfSize:80.0f];
    startButton.center = center;
    [startButton addTarget:self action:@selector(go:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
}

- (void)go:(UIButton *)button {
    GamePlayViewController *gamePlayViewController = [[GamePlayViewController alloc] init];
    [self presentViewController:gamePlayViewController animated:YES completion:nil];
    [gamePlayViewController startGame];
}

@end
