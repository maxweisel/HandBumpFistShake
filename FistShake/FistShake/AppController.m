//
//  AppController.m
//  FistShake
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "AppController.h"
#import <GameKit/GameKit.h>
#import "PhysicalGestureGuesser.h"

// This is here to get clang to stfu about GKSession being deprecated.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface AppController () <GKSessionDelegate>

@end

@implementation AppController {
    GKSession *_session;
}

__weak static AppController *__currentInstance = nil;

+ (instancetype)currentInstance {
    return __currentInstance;
}

- (instancetype)init {
    if ((self = [super init]) != nil) {
        if (__currentInstance == nil)
            __currentInstance = self;
        
        _session = [[GKSession alloc] initWithSessionID:@"HandBumpFistShake" displayName:nil sessionMode:GKSessionModeClient];
        _session.delegate = self;
        [_session setDataReceiveHandler:self withContext:nil];
        _session.available = YES;
    }
    return self;
}

- (void)dealloc {
    
}

#pragma mark -
#pragma mark GKSession

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    NSLog(@"Peer: %@ didChangeState: %i", peerID, state);
    
    switch (state) {
        case GKPeerStateAvailable:
            if ([[_session displayNameForPeer:peerID] isEqualToString:@"Host"])
                [_session connectToPeer:peerID withTimeout:40.0f];
            break;
        case GKPeerStateConnected:
            NSLog(@"Peer connected %@", [_session displayNameForPeer:peerID]);
        default:
            break;
    }
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed" message:@"Please restart and try again" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    NSDictionary *message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    [self receivedValue:message[@"value"] forKey:message[@"key"]];
}

#pragma mark -
#pragma mark Messages

- (void)sendValue:(id<NSCoding>)value forKey:(NSString *)key {
    if (value == nil || key == nil) {
        NSLog(@"Trying to send message with nil value or key.");
        return;
    }
    
    NSDictionary *message = @{@"key":key, @"value":value};
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    
    [_session sendDataToAllPeers:messageData withDataMode:GKSendDataReliable error:nil];
}

- (void)receivedValue:(id)value forKey:(NSString *)key {
    if ([@"interaction" isEqualToString:key]) {
        Interaction interaction = [PhysicalGestureGuesser interactionForString:value];
        [_delegate useNewGesture:interaction];
    }
}

@end

#pragma clang diagnostic pop
