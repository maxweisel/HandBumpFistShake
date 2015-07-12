//
//  TestViewController.m
//  FistShake
//
//  Created by Max Weisel on 7/12/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "TestViewController.h"
#import "AppController.h"

@implementation TestViewController {
    UILabel *_gestureLabel;
}

- (instancetype)init {
    if ((self = [super init]) != nil) {
        
    }
    return self;
}

- (void)dealloc {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blueColor];
    
    CGRect viewBounds = self.view.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(viewBounds), CGRectGetMidY(viewBounds));
    
    AppController *controller = [AppController currentInstance];
    controller.viewController = self;
    
    _gestureLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 44.0f)];
    _gestureLabel.center = center;
    _gestureLabel.text = @"BumpShake";
    _gestureLabel.font = [UIFont systemFontOfSize:30.0f];
    _gestureLabel.textAlignment = NSTextAlignmentCenter;
    _gestureLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:_gestureLabel];
}

- (void)displayGesture:(NSString *)gesture {
    _gestureLabel.text = gesture;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    AppController *controller = [AppController currentInstance];
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    float buttonHeight = self.view.bounds.size.height / 5;
    int button = point.y / buttonHeight;
    
    [controller sendValue:[NSNumber numberWithInt:button] forKey:@"CurrentGesture"];
    NSLog(@"CurrentGesture: %@", [NSNumber numberWithInt:button]);
}

@end
