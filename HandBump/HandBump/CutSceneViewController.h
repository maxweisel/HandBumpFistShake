//
//  CutSceneViewController.h
//  HandBump
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CutSceneViewController : UIViewController

- (instancetype)initWithVideoURL:(NSURL *)videoURL;

@property (nonatomic) AVPlayer *player;

@end
