//
//  ZGCustomAudioIOViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/6/30.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_CustomAudioIO

#import "ZGCustomAudioIOViewController.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGUserIDHelper.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

@interface ZGCustomAudioIOViewController () <ZegoEventHandler>

@property (weak, nonatomic) IBOutlet UIView *localPreviewView;
@property (weak, nonatomic) IBOutlet UIView *remotePlayView;

@property (nonatomic, assign) ZegoPublisherState publisherState;
@property (weak, nonatomic) IBOutlet UIButton *startPublishButton;

@property (nonatomic, assign) ZegoPlayerState playerState;
@property (weak, nonatomic) IBOutlet UIButton *startPlayButton;

@property (strong, nonatomic) NSTimer *audioCaptureTimer;
@property (strong, nonatomic) NSTimer *audioRenderTimer;

@property (nonatomic, strong) ZegoAudioFrameParam *audioCapturedFrameParam;
@property (nonatomic, strong) ZegoAudioFrameParam *audioRenderFrameParam;

// Audio data to be sent
@property (nonatomic, strong) NSData *audioCapturedData;
// Audio origin data position
@property (nonatomic, assign) void *audioCapturedDataPosition;

// Audio data buffer to be fetch
@property (nonatomic, assign) unsigned char *audioRenderBuffer;
// Total render audio data to be save
@property (nonatomic, strong) NSMutableData *audioRenderData;

@end

@implementation ZGCustomAudioIOViewController

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"CustomAudioIO" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGCustomAudioIOViewController class])];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    [self createEngineAndLoginRoom];
}

- (void)viewDidDisappear:(BOOL)animated {
    if ([self.audioCaptureTimer isValid]) {
        ZGLogInfo(@" ⏱ Audio capture timer invalidate");
        [self.audioCaptureTimer invalidate];
    }
    self.audioCaptureTimer = nil;

    if ([self.audioRenderTimer isValid]) {
        ZGLogInfo(@" ⏱ Audio render timer invalidate");
        [self.audioRenderTimer invalidate];
    }
    self.audioRenderTimer = nil;

    ZGLogInfo(@" 🚪 Logout room");
    [[ZegoExpressEngine sharedEngine] logoutRoom:self.roomID];

    // Can destroy the engine when you don't need audio and video calls
    ZGLogInfo(@" 🏳️ Destroy ZegoExpressEngine");
    [ZegoExpressEngine destroyEngine:nil];
}

- (void)dealloc {
    ZGLogInfo(@" 🔴 %s dealloc", __FILE__);
}

- (void)createEngineAndLoginRoom {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];

    ZGLogInfo(@" 🚀 Create ZegoExpressEngine");
    [ZegoExpressEngine createEngineWithAppID:appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];


    ZegoCustomAudioConfig *audioConfig = [[ZegoCustomAudioConfig alloc] init];
    audioConfig.sourceType = ZegoAudioSourceTypeCustom;

    ZGLogInfo(@" 🎶 Enable custom audio io");
    [[ZegoExpressEngine sharedEngine] enableCustomAudioIO:YES config:audioConfig];


    ZegoUser *user = [ZegoUser userWithUserID:[ZGUserIDHelper userID] userName:[ZGUserIDHelper userName]];

    ZGLogInfo(@" 🚪 Login room. roomID: %@", self.roomID);
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomID user:user config:[ZegoRoomConfig defaultConfig]];
}


- (IBAction)startPublishButtonClick:(UIButton *)sender {
    if (self.publisherState == ZegoPublisherStatePublishing) {
        [self stopPublishing];
    } else if (self.publisherState == ZegoPublisherStateNoPublish) {
        [self startPublishing];
    }
}

- (IBAction)startPlayButtonClick:(UIButton *)sender {
    if (self.playerState == ZegoPlayerStatePlaying) {
        [self stopPlaying];
    } else if (self.playerState == ZegoPlayerStateNoPlay) {
        [self startPlaying];
    }
}

- (void)startPublishing {

    ZGLogInfo(@" 🔌 Start preview");
    ZegoCanvas *previewCanvas = [ZegoCanvas canvasWithView:self.localPreviewView];
    [[ZegoExpressEngine sharedEngine] startPreview:previewCanvas];

    ZGLogInfo(@" 📤 Start publishing stream. streamID: %@", self.localPublishStreamID);
    [[ZegoExpressEngine sharedEngine] startPublishingStream:self.localPublishStreamID];


    // Start a timer that triggers every 20ms to send audio data
    self.audioCaptureTimer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(sendCapturedAudioFrame) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:self.audioCaptureTimer forMode:NSRunLoopCommonModes];
    ZGLogInfo(@" ⏱ Audio capture timer fire 🚀");
    [self.audioCaptureTimer fire];
}

- (void)stopPublishing {

    if (self.audioCaptureTimer) {
        ZGLogInfo(@" ⏱ Audio capture timer invalidate");
        [self.audioCaptureTimer invalidate];
        self.audioCaptureTimer = nil;
    }

    ZGLogInfo(@" 🔌 Stop preview");
    [[ZegoExpressEngine sharedEngine] stopPreview];

    ZGLogInfo(@" 📤 Stop publishing stream");
    [[ZegoExpressEngine sharedEngine] stopPublishingStream];

}

- (void)startPlaying {

    ZGLogInfo(@" 📥 Start playing stream, streamID: %@", self.remotePlayStreamID);
    ZegoCanvas *playCanvas = [ZegoCanvas canvasWithView:self.remotePlayView];
    [[ZegoExpressEngine sharedEngine] startPlayingStream:self.remotePlayStreamID canvas:playCanvas];

    // Start a timer that triggers every 20ms to fetch audio data
    self.audioRenderTimer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(fetchRenderAudioFrame) userInfo:nil repeats:YES];
    [NSRunLoop.mainRunLoop addTimer:self.audioRenderTimer forMode:NSRunLoopCommonModes];
    ZGLogInfo(@" ⏱ Audio render timer fire 🚀");
    [self.audioRenderTimer fire];

}

- (void)stopPlaying {

    if (self.audioRenderTimer) {
        ZGLogInfo(@" ⏱ Audio render timer invalidate");
        [self.audioRenderTimer invalidate];
        self.audioRenderTimer = nil;
    }

    // Free the audio render buffer
    if (self.audioRenderBuffer) {
        free(self.audioRenderBuffer);
    }

    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [docPaths objectAtIndex:0];
    NSString *audioRenderFilePath = [documentsPath stringByAppendingPathComponent:@"CustomAudioRender.pcm"];
    ZGLogInfo(@" 💾 Write audio render data to file: %@", audioRenderFilePath);
    [self.audioRenderData writeToFile:audioRenderFilePath atomically:YES];

    ZGLogInfo(@" 📥 Stop playing stream");
    [[ZegoExpressEngine sharedEngine] stopPlayingStream:self.remotePlayStreamID];
}

#pragma mark - Custom Audio IO

// Will be called by the NSTimer every 20ms
- (void)sendCapturedAudioFrame {

    // Initialize audio pcm data
    if (!_audioCapturedData) {
        NSURL *auxURL = [[NSBundle mainBundle] URLForResource:@"test.wav" withExtension:nil];
        _audioCapturedData = [NSData dataWithContentsOfURL:auxURL options:0 error:nil];
        _audioCapturedDataPosition = (void *)[_audioCapturedData bytes];
    }

    if (!_audioCapturedFrameParam) {
        _audioCapturedFrameParam = [[ZegoAudioFrameParam alloc] init];
        _audioCapturedFrameParam.channel = 1;
        _audioCapturedFrameParam.sampleRate = ZegoAudioSampleRate16K;
    }

    float duration = 0.02; // 20ms
    int sampleRate = 16000;
    int audioChannels = 1;
    int bytesPerSample = 2;

    // Calculate remaining data length
    unsigned int remainingDataLength = (unsigned int)([_audioCapturedData bytes] + (int)[_audioCapturedData length] - _audioCapturedDataPosition);

    unsigned int expectedDataLength = (unsigned int)(duration * sampleRate * audioChannels * bytesPerSample);

    if (remainingDataLength >= expectedDataLength) {
        NSLog(@"sendCustomAudioCapturePCMData, remain: %d", remainingDataLength);
        [[ZegoExpressEngine sharedEngine] sendCustomAudioCapturePCMData:_audioCapturedDataPosition dataLength:expectedDataLength param:_audioCapturedFrameParam];
        _audioCapturedDataPosition = _audioCapturedDataPosition + expectedDataLength;

    } else {
        _audioCapturedDataPosition = (void *)[_audioCapturedData bytes];
    }

}

// Will be called by the NSTimer every 20ms
- (void)fetchRenderAudioFrame {

    if (!_audioRenderData) {
        _audioRenderData = [NSMutableData data];
    }

    if (!_audioRenderFrameParam) {
        _audioRenderFrameParam = [[ZegoAudioFrameParam alloc] init];
        _audioRenderFrameParam.channel = 1;
        _audioRenderFrameParam.sampleRate = ZegoAudioSampleRate16K;
    }

    float duration = 0.02; // 20ms
    int sampleRate = 16000;
    int audioChannels = 1;
    int bytesPerSample = 2;

    unsigned int expectedDataLength = (unsigned int)(duration * sampleRate * audioChannels * bytesPerSample);

    if (!_audioRenderBuffer) {
        _audioRenderBuffer = malloc(expectedDataLength);
        memset(_audioRenderBuffer, 0, expectedDataLength);
    }

    // Fetch audio render buffer
    [[ZegoExpressEngine sharedEngine] fetchCustomAudioRenderPCMData:_audioRenderBuffer dataLength:expectedDataLength param:_audioRenderFrameParam];

    // Write audio render buffer to NSMutableData
    [_audioRenderData appendBytes:_audioRenderBuffer length:expectedDataLength];
}

#pragma mark - ZegoEventHandler

- (void)onPublisherStateUpdate:(ZegoPublisherState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData streamID:(NSString *)streamID {
    if (errorCode != 0) {
        ZGLogError(@" 🚩 ❌ 📤 Publishing stream error of streamID: %@, errorCode:%d", streamID, errorCode);
    } else {
        switch (state) {
            case ZegoPublisherStatePublishing:
                ZGLogInfo(@" 🚩 📤 Publishing stream");
                [self.startPublishButton setTitle:@"Stop Publish" forState:UIControlStateNormal];
                break;

            case ZegoPublisherStatePublishRequesting:
                ZGLogInfo(@" 🚩 📤 Requesting publish stream");
                [self.startPublishButton setTitle:@"Requesting" forState:UIControlStateNormal];
                break;

            case ZegoPublisherStateNoPublish:
                ZGLogInfo(@" 🚩 📤 No publish stream");
                [self.startPublishButton setTitle:@"Start Publish" forState:UIControlStateNormal];
                break;
        }
    }
    self.publisherState = state;
}

- (void)onPlayerStateUpdate:(ZegoPlayerState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData streamID:(NSString *)streamID {
    if (errorCode != 0) {
        ZGLogError(@" 🚩 ❌ 📥 Playing stream error of streamID: %@, errorCode:%d", streamID, errorCode);
    } else {
        switch (state) {
            case ZegoPlayerStatePlaying:
                ZGLogInfo(@" 🚩 📥 Playing stream");
                [self.startPlayButton setTitle:@"Stop Play" forState:UIControlStateNormal];
                break;

            case ZegoPlayerStatePlayRequesting:
                ZGLogInfo(@" 🚩 📥 Requesting play stream");
                [self.startPlayButton setTitle:@"Requesting" forState:UIControlStateNormal];
                break;

            case ZegoPlayerStateNoPlay:
                ZGLogInfo(@" 🚩 📥 No play stream");
                [self.startPlayButton setTitle:@"Start Play" forState:UIControlStateNormal];
                break;
        }
    }
    self.playerState = state;
}


@end

#endif
