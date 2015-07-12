//
//  AppController.m
//  HandBump
//
//  Created by Max Weisel on 7/11/15.
//  Copyright (c) 2015 Organization Name. All rights reserved.
//

#import "AppController.h"
#import <GameKit/GameKit.h>

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
        
        [self performSelector:@selector(test) withObject:nil afterDelay:6.0];
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
    
    [self receivedValue:message[@"value"] forKey:message[@"key"]];
}

#pragma mark -
#pragma mark Messages

- (void)sendValue:(NSValue *)value forKey:(NSString *)key {
    if (value == nil || key == nil) {
        NSLog(@"Trying to send message with nil value or key.");
        return;
    }
    
    NSDictionary *message = @{@"key":key, @"value":value};
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    
    [_session sendDataToAllPeers:messageData withDataMode:GKSendDataReliable error:nil];
}

- (void)receivedValue:(NSValue *)value forKey:(NSString *)key {
    NSLog(@"Received value: %@ forKey: %@", value, key);
}

@end

#pragma clang diagnostic pop
