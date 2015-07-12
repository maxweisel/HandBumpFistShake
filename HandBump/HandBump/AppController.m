//
//  AppController.m
//  HandBump
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "AppController.h"
#import <GameKit/GameKit.h>
#import "GamePlayViewController.h"

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
        
        _session = [[GKSession alloc] initWithSessionID:@"HandBumpFistShake" displayName:@"Host" sessionMode:GKSessionModeServer];
        _session.delegate = self;
        [_session setDataReceiveHandler:self withContext:nil];
        _session.available = YES;
    }
    return self;
}

- (void)dealloc {
    
}

- (void)test {
    NSLog(@"Send test");
    [self sendValue:[NSNumber numberWithDouble:3.141592] forKey:@"Pie"];
}

#pragma mark -
#pragma mark GKSession

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    if (session != _session)
        return;
    
    NSError *error = nil;
    if ([session acceptConnectionFromPeer:peerID error:&error]) {
        NSLog(@"Peer connected! %@", [session displayNameForPeer:peerID]);
    } else {
        NSLog(@"Peer connect failed! %@", error.localizedDescription);
    }
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed" message:@"Please restart and try again" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    NSDictionary *message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    [self receivedValue:message[@"value"] forKey:message[@"key"] peer:peer];
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

- (void)receivedValue:(id)value forKey:(NSString *)key peer:(NSString *)peer {
    if ([@"CurrentGesture" isEqualToString:key]) {
        [_gamePlayViewController receivedInteraction:value fromDevice:peer];
    }
}

#pragma mark -
#pragma mark Peers

- (NSArray *)connectedPeers {
    return [_session peersWithConnectionState:GKPeerStateConnected];
}

#pragma mark -
#pragma mark Interaction

- (void)sendInteraction:(NSString *)interaction {
    [self sendValue:interaction forKey:@"interaction"];
}

@end

#pragma clang diagnostic pop
