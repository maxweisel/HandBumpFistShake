//
//  MainViewController.m
//  FistShake
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "MainViewController.h"
#import "PhysicalGestureGuesser.h"
#import "PhysicalInteraction.h"
#import "AppController.h"

#import <AudioToolbox/AudioToolbox.h>
#import <CoreMotion/CoreMotion.h>

@interface MainViewController () <AppControllerDelegate>
@end

@implementation MainViewController {
    CMMotionManager *_motionManager;
    PhysicalGestureGuesser *_gestureGuesser;

    AppController *_controller;

    InteractionType _targetGesture;
    InteractionType _currentGuess;
    UILabel *_gestureGuessLabel;
    UILabel *_targetGestureLabel;

    NSTimer *_sendCurrentGestureTimer;

    CMAttitude *_referenceAttitude;
    UILabel *_referenceLabel;
    UILabel *_endLabel;

    int _gesturesFired[Last];

    UITapGestureRecognizer *_tapGesture;

    UILabel *_gravityLabel;
    UILabel *_attitudeLabel;

    NSArray *_debugLabels;
}

#pragma mark UIViewController Crap

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _gestureGuesser = [[PhysicalGestureGuesser alloc] initWithThreshold:.3];
        _targetGesture = None;
        _currentGuess = None;

        _controller = [AppController currentInstance];
        _controller.delegate = self;

        [self resetGestureData];
    }
    return self;
}

- (NSArray *)debugLabels {
    if (!_debugLabels) {
        _debugLabels = @[_referenceLabel, _attitudeLabel, _gravityLabel];
    }
    return _debugLabels;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [self.view addGestureRecognizer:_tapGesture];

    CGRect bounds = self.view.bounds;

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

    CGFloat guessLabelY = CGRectGetMaxY(_attitudeLabel.frame) + 10;
    _gestureGuessLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, guessLabelY, CGRectGetWidth(bounds), 100)];
    _gestureGuessLabel.text = [PhysicalInteraction stringForInteractionType:_currentGuess];
    _gestureGuessLabel.font = [UIFont italicSystemFontOfSize:24];
    _gestureGuessLabel.alpha = .6;
    _gestureGuessLabel.textColor = [UIColor blackColor];
    _gestureGuessLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_gestureGuessLabel];
    CALayer *layer =  _gestureGuessLabel.layer;
    layer.borderColor = [UIColor blueColor].CGColor;
    layer.borderWidth = 2;

    [self setupTargetGestureLabel];

    // Finally! Motion!
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1.0f/60.0f;
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
                                                        toQueue:[NSOperationQueue mainQueue]
                                                    withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                        if (error) {
                                                            [self handleMotionError:&error];
                                                            return;
                                                        }

                                                        [self updateWithMotion:motion];
                                                    }];

    // Coordinate sending data.  Send every 100 ms.
    _sendCurrentGestureTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(sendGestureData) userInfo:nil repeats:YES];
}

- (void)handleMotionError:(NSError **)error {
    NSString *errorString = [NSString stringWithFormat:@"wtf: %@", *error];
    UILabel *label = [[UILabel alloc] init];
    [self.view addSubview:label];
    label.text = errorString;
    [label sizeToFit];
    // This is almost guaranteed to look shitty. It's never been tested; we've never had errors.
    label.center = [self.view convertPoint:self.view.center fromView:nil];
    NSLog(@"%@", errorString);
}

- (void)tapGesture:(UIGestureRecognizer *)tapGesture {
    // This is sure to bite us in the ass some day.
    for (UIView *view in [self debugLabels]) {
        [UIView animateWithDuration:.3 animations:^{
            view.alpha = fabs(1 - view.alpha);
        }];
    }
}

- (void)resetGestureData {
    for (int i = 0; i < Last /* InteractionType */; i++) {
        _gesturesFired[i] = 0;
    }
}

- (void)sendGestureData {
    int maxCount = 0;
    InteractionType highGesture = None;
    for (int i = 0; i < 6; i++) {
        if (_gesturesFired[i] > maxCount) {
            maxCount = _gesturesFired[i];
            highGesture = i;
        }
    }

    NSLog(@"sending gesture: %@", [PhysicalInteraction stringForInteractionType:highGesture]);
    [_controller sendValue:@(highGesture) forKey:@"CurrentGesture"];

    // Clear bucket for the next round.
    [self resetGestureData];
}

#pragma mark Bleh

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc {
    [_motionManager stopDeviceMotionUpdates];
    [_sendCurrentGestureTimer invalidate];
}

#pragma mark AppControllerDelegate

- (void)useNewGesture:(InteractionType)gesture {
    _targetGesture = gesture;
    [self updateTargetGestureUi];
}

#pragma mark Motion

- (void)updateWithMotion:(CMDeviceMotion *)motion {
    if (!_referenceAttitude) {
        _referenceAttitude = _motionManager.deviceMotion.attitude;
        [self setupReferenceLabel];
    }

    _gravityLabel.text = [NSString stringWithFormat:@"[G] %@", formattedGravity(motion.gravity)];
    _attitudeLabel.text = [NSString stringWithFormat:@"[A] %@", formattedAttitude(motion.attitude)];

    [self updateGuessLabel];
}

- (void)updateGuessLabel {
    CMAttitude *currentAttitude = _motionManager.deviceMotion.attitude;
    InteractionType interactionType = [_gestureGuesser bestGuessFromAttitude:currentAttitude];

    if (interactionType != _currentGuess) {
        NSString *gestureString = [PhysicalInteraction stringForInteractionType:interactionType];
        _gestureGuessLabel.text = gestureString;
        NSLog(@"new guess: %@", gestureString);
        _currentGuess = interactionType;
    }

    _gesturesFired[interactionType] += 1;
}

- (void)setupReferenceLabel {
    CGSize size = [self labelSize];
    CGPoint origin = (CGPoint){10, CGRectGetMaxY(self.view.bounds) - size.height - 20};
    _referenceLabel = [[UILabel alloc] initWithFrame:(CGRect){origin, size}];
    _referenceLabel.font = fixedFont();
    [self.view addSubview:_referenceLabel];

    _referenceLabel.text = [NSString stringWithFormat:@"[%@]", formattedAttitude(_referenceAttitude)];
}

- (void)setupTargetGestureLabel {
    _targetGestureLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_gestureGuessLabel.frame), CGRectGetWidth(self.view.bounds), 120)];
    _targetGestureLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_targetGestureLabel];
    _targetGestureLabel.backgroundColor = [UIColor redColor];
    _targetGestureLabel.font = [UIFont boldSystemFontOfSize:64];

    NSString *targetString = [PhysicalInteraction stringForInteractionType:_targetGesture];
    NSLog(@"first target: %@", targetString);
    _targetGestureLabel.text = targetString;
}

- (void)updateTargetGestureUi {
    // Update label.
    NSString *text = [PhysicalInteraction stringForInteractionType:_targetGesture];
    _targetGestureLabel.text = text;
    NSLog(@"new target from server: %@", text);

    // Shake phone.
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
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

// Logic: http://www.cg.info.hiroshima-cu.ac.jp/~miyazaki/knowledge/teche23.html
CMRotationMatrix inverseOfRotationMatrix(CMRotationMatrix m) {
    CMRotationMatrix inverse;

    double determinant = m.m11 * m.m22 * m.m33
                       + m.m21 * m.m32 * m.m13
                       + m.m31 * m.m12 * m.m23
                       - m.m11 * m.m32 * m.m23
                       - m.m31 * m.m22 * m.m13
                       - m.m21 * m.m12 * m.m33;

    inverse.m11 = (m.m22 * m.m33 - m.m23 * m.m32) / determinant;
    inverse.m12 = (m.m13 * m.m32 - m.m12 * m.m33) / determinant;
    inverse.m13 = (m.m12 * m.m23 - m.m13 * m.m22) / determinant;

    inverse.m21 = (m.m23 * m.m31 - m.m21 * m.m33) / determinant;
    inverse.m22 = (m.m11 * m.m33 - m.m13 * m.m31) / determinant;
    inverse.m23 = (m.m13 * m.m21 - m.m11 * m.m23) / determinant;

    inverse.m31 = (m.m21 * m.m32 - m.m22 * m.m31) / determinant;
    inverse.m32 = (m.m12 * m.m31 - m.m11 * m.m32) / determinant;
    inverse.m33 = (m.m11 * m.m22 - m.m12 * m.m21) / determinant;

    return inverse;
}

// Stolen from http://ncalculators.com/matrix/3x3-matrix-multiplication-calculator.htm
CMRotationMatrix multiplyRotationMatrices(CMRotationMatrix a, CMRotationMatrix b) {
    CMRotationMatrix m;

    m.m11 = a.m11*b.m11 + a.m12*b.m21 + a.m13*b.m31;
    m.m12 = a.m11*b.m12 + a.m12*b.m22 + a.m13*b.m32;
    m.m13 = a.m11*b.m13 + a.m12*b.m23 + a.m13*b.m33;

    m.m21 = a.m21*b.m11 + a.m22*b.m21 + a.m23*b.m31;
    m.m22 = a.m21*b.m12 + a.m22*b.m22 + a.m23*b.m32;
    m.m23 = a.m21*b.m13 + a.m22*b.m23 + a.m23*b.m33;

    m.m31 = a.m31*b.m11 + a.m32*b.m21 + a.m33*b.m31;
    m.m32 = a.m31*b.m12 + a.m32*b.m22 + a.m33*b.m32;
    m.m33 = a.m31*b.m13 + a.m32*b.m23 + a.m33*b.m33;

    return m;
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
    return [NSString stringWithFormat:@"p:%@, r:%@, y:%@", formatted(attitude.pitch), formatted(attitude.roll), formatted(attitude.yaw)];
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

@end
