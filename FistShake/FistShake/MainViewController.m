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
    NSLog(@"reference: %@", formattedAttitude(_referenceAttitude));

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

// Stolen from http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToMatrix/ and modified.
CMRotationMatrix rotationMatrixForQuaternion(CMQuaternion q) {

    double xx = q.x * q.x;
    double xy = q.x * q.y;
    double xz = q.x * q.z;
    double xw = q.x * q.w;

    double yy = q.y * q.y;
    double yz = q.y * q.z;
    double yw = q.y * q.w;

    double zz = q.z * q.z;
    double zw = q.z * q.w;

    CMRotationMatrix rotationMatrix;

    rotationMatrix.m11 = 1 - 2 * (yy + zz);
    rotationMatrix.m21 =     2 * (xy - zw);
    rotationMatrix.m31 =     2 * (xz + yw);

    rotationMatrix.m12 =     2 * (xy + zw);
    rotationMatrix.m22 = 1 - 2 * (xx + zz);
    rotationMatrix.m32 =     2 * (yz - xw);

    rotationMatrix.m13 =     2 * (xz - yw);
    rotationMatrix.m23 =     2 * (yz + xw);
    rotationMatrix.m33 = 1 - 2 * (xx + yy);

    return rotationMatrix;
}

// But I wrote this one all by myself!
CMRotationMatrix subtractRotationMatrices(CMRotationMatrix first, CMRotationMatrix second) {
    CMRotationMatrix final;

    final.m11 = first.m11 - second.m11;
    final.m12 = first.m12 - second.m12;
    final.m13 = first.m13 - second.m13;
    
    final.m21 = first.m21 - second.m21;
    final.m22 = first.m22 - second.m22;
    final.m23 = first.m23 - second.m23;

    final.m31 = first.m31 - second.m31;
    final.m32 = first.m32 - second.m32;
    final.m33 = first.m33 - second.m33;

    return final;
}

// Stolen from http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
// Assumes the rotations are pure. This is probably true, right?
CMQuaternion quaternionFromRotationMatrix(CMRotationMatrix m) {
    CMQuaternion q;

    q.w = sqrt(MAX(0, 1 + m.m11 + m.m22 + m.m33)) / 2.0;
    q.x = sqrt(MAX(0, 1 + m.m11 - m.m22 - m.m33)) / 2.0;
    q.y = sqrt(MAX(0, 1 - m.m11 + m.m22 - m.m33)) / 2.0;
    q.z = sqrt(MAX(0, 1 - m.m11 - m.m22 + m.m33)) / 2.0;

    if (m.m32 - m.m23 > 0) q.x *= -1;
    if (m.m13 - m.m31 > 0) q.y *= -1;
    if (m.m21 - m.m12 > 0) q.z *= -1;

    return q;
}

CMQuaternion subtractQuaternions(CMQuaternion c1, CMQuaternion c2) {
    CMQuaternion q;
    q.x = c1.x - c2.x;
    q.y = c1.y - c2.y;
    q.z = c1.z - c2.z;
    q.w = c1.w - c2.w;
    return q;
}

- (void)endPressed:(UIButton *)endButton {
    CMAttitude *endAttitude = _motionManager.deviceMotion.attitude;

    // Use _referenceAttitude as basis for the attitude adjustment.
    CMAttitude *adjustedAttitude = [endAttitude copy];
    [adjustedAttitude multiplyByInverseOfAttitude:_referenceAttitude];

    PhysicalGesture bestGuess = [_gestureGuesser bestGuessFromAttitude:adjustedAttitude];
    NSLog(@"BEST GUESS: %@", @(bestGuess));

#if DEBUG
    // Do some dumb stuff for debugging. This should be removed.
    NSLog(@"final attitude: %@", formattedAttitude(endAttitude));
    NSLog(@"adjusted attitude: %@", formattedAttitude(adjustedAttitude));
    NSLog(@"rotation matrix:\n%@", stringifiedRotationMatrix(adjustedAttitude.rotationMatrix));
    CMQuaternion q = adjustedAttitude.quaternion;
    CMRotationMatrix calculatedRotationMatrix = rotationMatrixForQuaternion(q);
    NSLog(@"calculated rotation matrix:\n%@", stringifiedRotationMatrix(calculatedRotationMatrix));
    CMRotationMatrix differenceMatrix = subtractRotationMatrices(adjustedAttitude.rotationMatrix, calculatedRotationMatrix);
    NSLog(@"difference matrix:\n%@", stringifiedRotationMatrix(differenceMatrix));
    NSLog(@"quaternion: %@", formattedQuaternion(q));
    CMQuaternion calculatedQuaternion = quaternionFromRotationMatrix(calculatedRotationMatrix);
    NSLog(@"calculated quaternion: %@", formattedQuaternion(calculatedQuaternion));
    CMQuaternion quatDiff = subtractQuaternions(q, calculatedQuaternion);
    NSLog(@"quat diff: %@", formattedQuaternion(quatDiff));

    NSLog(@"magnitude (atti): %@", @(magnitudeOfAttitude(adjustedAttitude)));
    NSLog(@"magnitude (quat): %@", @(magnitudeOfQuaternion(q)));
#endif

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

double magnitudeOfAttitude(CMAttitude *attitude) {
    return sqrt(pow(attitude.roll, 2.0f) + pow(attitude.yaw, 2.0f) + pow(attitude.pitch, 2.0f));
}

double magnitudeOfQuaternion(CMQuaternion q) {
    return sqrt(pow(q.x, 2.0f) + pow(q.y, 2.0f) + pow(q.z, 2.0f) + pow(q.w, 2.0f));
}

CMQuaternion normalizeQuaternion(CMQuaternion q) {
    double magnitude = magnitudeOfQuaternion(q);
    q.x /= magnitude;
    q.y /= magnitude;
    q.z /= magnitude;
    q.w /= magnitude;
    return q;
}

NSString* stringifiedRotationMatrix(CMRotationMatrix matrix) {
    NSString *row1 = [NSString stringWithFormat:@"\t %1.4f \t %1.4f \t %1.4f", matrix.m11, matrix.m12, matrix.m13];
    NSString *row2 = [NSString stringWithFormat:@"\t %1.4f \t %1.4f \t %1.4f", matrix.m21, matrix.m22, matrix.m23];
    NSString *row3 = [NSString stringWithFormat:@"\t %1.4f \t %1.4f \t %1.4f", matrix.m31, matrix.m32, matrix.m33];
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

NSString* formattedQuaternion(CMQuaternion q) {
    return [NSString stringWithFormat:@"x:%@, y:%@, z:%@, w:%@", formatted(q.x), formatted(q.y), formatted(q.z), formatted(q.w)];
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
