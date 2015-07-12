//
//  MainViewController.m
//  FistShake
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "MainViewController.h"
#import "PhysicalGestureGuesser.h"

#import <CoreMotion/CoreMotion.h>

@implementation MainViewController {
    CMMotionManager *_motionManager;
    PhysicalGestureGuesser *_gestureGuesser;

    UIButton *_startButton;
    UIButton *_endButton;

    UILabel *_gravityLabel;
    UILabel *_attitudeLabel;

    CMAttitude *_referenceAttitude;
    UILabel *_referenceLabel;
    UILabel *_endLabel;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _gestureGuesser = [[PhysicalGestureGuesser alloc] initWithThreshold:.3];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect bounds = self.view.bounds;

    _startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _startButton.frame = CGRectMake(0, 0, 200, 60); // It's a lie!
    [_startButton setTitle:@"[Start]" forState:UIControlStateNormal];
    [_startButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _startButton.titleLabel.font = fixedFont();
    _startButton.layer.borderColor = [UIColor redColor].CGColor;
    _startButton.layer.borderWidth = 1;
    _startButton.layer.cornerRadius = 3;
    [self.view addSubview:_startButton];
    _startButton.center = CGPointMake(CGRectGetMidX(bounds),
                                 CGRectGetMidY(bounds));
    [_startButton addTarget:self action:@selector(startPressed:) forControlEvents:UIControlEventTouchUpInside];

    _endButton = [UIButton buttonWithType:UIButtonTypeSystem];
    CGRect endFrame = _startButton.frame;
    endFrame.origin.y = CGRectGetMaxY(_startButton.frame) + 15;
    _endButton.frame = endFrame;
    [_endButton setTitle:@"{End}" forState:UIControlStateNormal];
    [_endButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _endButton.layer.borderColor = [UIColor redColor].CGColor;
    _endButton.layer.borderWidth = 1;
    _endButton.layer.cornerRadius = 3;
    _endButton.titleLabel.font = fixedFont();
    [self.view addSubview:_endButton];
    [_endButton addTarget:self action:@selector(endPressed:) forControlEvents:UIControlEventTouchUpInside];
    _endButton.alpha = .1;
    _endButton.userInteractionEnabled = NO;

    // Diagnostics.
    CGPoint gravityLabelOrigin = CGPointMake(10, 20);
    CGSize gravityLabelSize = [self labelSize];
    CGRect gravityLabelFrame = (CGRect){gravityLabelOrigin, gravityLabelSize};
    _gravityLabel = [[UILabel alloc] initWithFrame:gravityLabelFrame];
    _gravityLabel.font = fixedFont();
    [self.view addSubview:_gravityLabel];

    CGPoint attitudeLabelOrigin = CGPointMake(CGRectGetMinX(gravityLabelFrame), CGRectGetMaxY(gravityLabelFrame));
    CGSize attitudeLabelSize = [self labelSize];
    CGRect attitudeLabelFrame = (CGRect){attitudeLabelOrigin, attitudeLabelSize};
    _attitudeLabel = [[UILabel alloc] initWithFrame:attitudeLabelFrame];
    _attitudeLabel.font = _gravityLabel.font;
    [self.view addSubview:_attitudeLabel];

    // Finally! Motion!
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1.0f/60.0f;
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
                                                        toQueue:[NSOperationQueue mainQueue]
                                                    withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                        if (error) {
                                                            NSString *errorString = [NSString stringWithFormat:@"wtf: %@", error];

                                                            [_startButton removeFromSuperview];

                                                            UILabel *label = [[UILabel alloc] init];
                                                            [self.view addSubview:label];
                                                            label.text = errorString;
                                                            [label sizeToFit];
                                                            // This is almost guaranteed to look shitty. It's never been tested; we've never had errors.
                                                            label.center = [self.view convertPoint:self.view.center fromView:nil];
                                                            NSLog(@"%@", errorString);
                                                            return;
                                                        }

                                                        [self updateWithMotion:motion];
                                                    }];
}

- (void)updateWithMotion:(CMDeviceMotion *)motion {
    _gravityLabel.text = [NSString stringWithFormat:@"[G] %@", formattedGravity(motion.gravity)];
    _attitudeLabel.text = [NSString stringWithFormat:@"[A] %@", formattedAttitude(motion.attitude)];
}

#pragma mark Buttons

- (void)startPressed:(UIButton *)startButton {
    _referenceAttitude = _motionManager.deviceMotion.attitude;
    NSLog(@"reference: %@", _referenceAttitude);

    if (![_referenceLabel superview]) {
        CGSize size = [self labelSize];
        CGPoint origin = (CGPoint){10, CGRectGetMaxY(self.view.bounds) - size.height - 20};
        _referenceLabel = [[UILabel alloc] initWithFrame:(CGRect){origin, size}];
        _referenceLabel.font = fixedFont();
        [self.view addSubview:_referenceLabel];
    }

    _referenceLabel.text = [NSString stringWithFormat:@"[%@]", formattedAttitude(_referenceAttitude)];
    _endButton.alpha = 1;
    _endButton.userInteractionEnabled = YES;

    _endLabel.alpha = .1;
}

- (void)endPressed:(UIButton *)endButton {
    CMAttitude *endAttitude = _motionManager.deviceMotion.attitude;

    // Use _referenceAttitude as basis for the attitude adjustment.
    CMAttitude *adjustedAttitude = [endAttitude copy];
    [adjustedAttitude multiplyByInverseOfAttitude:_referenceAttitude];

    PhysicalGesture bestGuess = [_gestureGuesser bestGuessFromAttitude:adjustedAttitude];
    NSLog(@"BEST GUESS: %@", )



    // Do some dumb stuff for debugging. This should be removed.
    NSLog(@"final attitude: %@", formattedAttitude(endAttitude));
    NSLog(@"adjusted attitude: %@", formattedAttitude(adjustedAttitude));
    NSLog(@"rotation matrix:\n%@", stringifiedRotationMatrix(endAttitude.rotationMatrix));
    NSLog(@"magnitude: %@", @(magnitudeFromAttitude(endAttitude)));

    _endButton.alpha = .1;
    _endButton.userInteractionEnabled = NO;

    if (![_endLabel superview]) {
        // Place label where start currently is. Why? Why not?
        CGRect referenceFrame = _referenceLabel.frame;
        _endLabel = [[UILabel alloc] initWithFrame:referenceFrame];
        _endLabel.font = fixedFont();

        // Move start label up.
        referenceFrame.origin.y -= CGRectGetHeight(referenceFrame);
        [UIView animateWithDuration:.2 animations:^{
            _referenceLabel.frame = referenceFrame;
            [self.view addSubview:_endLabel];
        }];
    }

    _endLabel.text = [NSString stringWithFormat:@"{%@}", formattedAttitude(endAttitude)];
    _endLabel.alpha = 1;
}


#pragma mark Math

double magnitudeFromAttitude(CMAttitude *attitude) {
    return sqrt(pow(attitude.roll, 2.0f) + pow(attitude.yaw, 2.0f) + pow(attitude.pitch, 2.0f));
}

NSString* stringifiedRotationMatrix(CMRotationMatrix matrix) {
    NSString *row1 = [NSString stringWithFormat:@"\t %1.2f \t %1.2f \t %1.2f", matrix.m11, matrix.m12, matrix.m13];
    NSString *row2 = [NSString stringWithFormat:@"\t %1.2f \t %1.2f \t %1.2f", matrix.m21, matrix.m22, matrix.m23];
    NSString *row3 = [NSString stringWithFormat:@"\t %1.2f \t %1.2f \t %1.2f", matrix.m31, matrix.m32, matrix.m33];
    return [NSString stringWithFormat:@"[%@\n %@\n %@]", row1, row2, row3];
}

#pragma mark Formatting

NSString* formatted(double d) {
    NSString *sign = (d < 0) ? @"-" : @" ";
    return [NSString stringWithFormat:@"%@%1.2f", sign, fabs(d)];
}

// Gross duplication. I have brought shame to my family.
NSString* formattedInDegrees(double d) {
    double degrees = d * 180 / M_PI;
    NSString *sign = (d < 0) ? @"-" : @" ";
    return [NSString stringWithFormat:@"%@%2.2f", sign, fabs(degrees)];
}

NSString* formattedGravity(CMAcceleration gravity) {
    return [NSString stringWithFormat:@"x:%@, y:%@, z:%@", formatted(gravity.x), formatted(gravity.y), formatted(gravity.z)];
}

NSString* formattedAttitude(CMAttitude *attitude) {
    return [NSString stringWithFormat:@"r:%@, p:%@, y:%@", formatted(attitude.roll), formatted(attitude.pitch), formatted(attitude.yaw)];
}


NSString* formattedAttitudeInDegrees(CMAttitude *attitude) {
    return [NSString stringWithFormat:@"r:%@, p:%@, y:%@", formattedInDegrees(attitude.roll), formattedInDegrees(attitude.pitch), formattedInDegrees(attitude.yaw)];
}

UIFont* fixedFont() {
    return [UIFont fontWithName:@"Menlo" size:16];
}

- (CGSize)labelSize {
    return CGSizeMake(CGRectGetWidth(self.view.bounds) - 20, 30);
}

# pragma mark Bull

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc {
    [_motionManager stopDeviceMotionUpdates];
}

@end
