//
//  ZGScreenCaptureManager.m
//  ZegoExpressExample-iOS-OC-Broadcast
//
//  Created by Patrick Fu on 2020/9/21.
//  Copyright © 2020 Zego. All rights reserved.
//

#import "ZGScreenCaptureManager.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

static ZGScreenCaptureManager *_sharedManager = nil;

@interface ZGScreenCaptureManager ()<ZegoEventHandler>

@property (nonatomic, copy) NSString *appGroup;

@property (nonatomic, assign) ZegoEngineState engineState;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end


@implementation ZGScreenCaptureManager

+ (instancetype)sharedManager {
    if (!_sharedManager) {
        @synchronized (self) {
            if (!_sharedManager) {
                _sharedManager = [[self alloc] init];
            }
        }
    }
    return _sharedManager;
}

- (void)startBroadcastWithAppGroup:(NSString *)appGroup {
    self.appGroup = appGroup;
    self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName:_appGroup];
    self.engineState = ZegoEngineStateStop;

    [self setupEngine];
    [self loginRoom];
    [self startPublish];
}

- (void)stopBroadcast {
    NSString *roomID = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_ROOM_ID"];
    [[ZegoExpressEngine sharedEngine] stopPublishingStream];
    [[ZegoExpressEngine sharedEngine] logoutRoom:roomID];
    [ZegoExpressEngine destroyEngine:nil];
}

- (void)handleSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle video sample buffer
            [self handlerVideoBuffer:sampleBuffer];
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;

        default:
            break;
    }
}

#pragma mark - Private methods

- (void)handlerVideoBuffer:(CMSampleBufferRef)buffer {
    if (_engineState != ZegoEngineStateStart) {
        return;
    }
    CFRetain(buffer);
    [[ZegoExpressEngine sharedEngine] sendCustomVideoCapturePixelBuffer:CMSampleBufferGetImageBuffer(buffer) timestamp:CMSampleBufferGetPresentationTimeStamp(buffer)];
    CFRelease(buffer);
}

- (void)setupEngine {
    // Prepare some config for ReplayKit
    ZegoEngineConfig *engineConfig = [[ZegoEngineConfig alloc] init];
    engineConfig.advancedConfig = @{
        @"replaykit_handle_rotation": @"false",
        @"max_channels": @"0",
        @"max_publish_channels": @"1"
    };
    [ZegoExpressEngine setEngineConfig:engineConfig];

    // Get parameters for [createEngine]
    NSNumber *appID = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_APP_ID"];
    NSString *appSign = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_APP_SIGN"];
    NSNumber *isTestEnv = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_IS_TEST_ENV"];
    NSNumber *scenario = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_SCENARIO"];

    [ZegoExpressEngine createEngineWithAppID:appID.unsignedIntValue appSign:appSign isTestEnv:isTestEnv.boolValue scenario:(ZegoScenario)scenario.unsignedIntValue eventHandler:self];

    // Enable custom video capture
    ZegoCustomVideoCaptureConfig *captureConfig = [[ZegoCustomVideoCaptureConfig alloc] init];
    captureConfig.bufferType = ZegoVideoBufferTypeCVPixelBuffer;
    [[ZegoExpressEngine sharedEngine] enableCustomVideoCapture:YES config:captureConfig];

    // Enable hardware encode/decode
    [[ZegoExpressEngine sharedEngine] enableHardwareEncoder:YES];
    [[ZegoExpressEngine sharedEngine] enableHardwareDecoder:YES];

    // Get parameters for [setVideoConfig]
    NSNumber *videoSizeWidth = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_VIDEO_SIZE_WIDTH"];
    NSNumber *videoSizeHeight = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_VIDEO_SIZE_HEIGHT"];
    NSNumber *videoFPS = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_SCREEN_CAPTURE_VIDEO_FPS"];
    NSNumber *videoBitrate = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_SCREEN_CAPTURE_VIDEO_BITRATE_KBPS"];

    // Set video config
    ZegoVideoConfig *videoConfig = [[ZegoVideoConfig alloc] init];
    videoConfig.captureResolution = CGSizeMake(videoSizeWidth.floatValue, videoSizeHeight.floatValue);
    videoConfig.encodeResolution = videoConfig.captureResolution;
    videoConfig.fps = videoFPS.intValue;
    videoConfig.bitrate = videoBitrate.intValue;
    [[ZegoExpressEngine sharedEngine] setVideoConfig:videoConfig];
}

- (void)loginRoom {
    // Get parameters for [loginRoom]
    NSString *userID = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_USER_ID"];
    NSString *userName = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_USER_NAME"];
    NSString *roomID = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_ROOM_ID"];
    [[ZegoExpressEngine sharedEngine] loginRoom:roomID user:[ZegoUser userWithUserID:userID userName:userName]];
}

- (void)startPublish {
    // Get parameters for [startPublishingStream]
    NSString *streamID = [self.userDefaults valueForKey:@"ZG_SCREEN_CAPTURE_STREAM_ID"];
    [[ZegoExpressEngine sharedEngine] startPublishingStream:streamID];
}

#pragma mark - Zego Express Handler

- (void)onRoomStateUpdate:(ZegoRoomState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData roomID:(NSString *)roomID {
    NSLog(@"🚩 🚪 Room State Update, state: %d, errorCode: %d, roomID: %@", (int)state, (int)errorCode, roomID);
}

- (void)onEngineStateUpdate:(ZegoEngineState)state {
    NSLog(@"🚩 🚀 Engine State Update, state: %d", (int)state);
    self.engineState = state;
}



@end
