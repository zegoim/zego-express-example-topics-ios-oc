//
//  ZGMediaPlayerViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2019/12/25.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_MediaPlayer

#import "ZGMediaPlayerViewController.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGUserIDHelper.h"

#import <ZegoExpressEngine/ZegoExpressEngine.h>
#import <ZegoExpressEngine/ZegoExpressEngine+MediaPlayer.h>

@interface ZGMediaPlayerViewController ()<ZegoEventHandler, ZegoMediaPlayerEventHandler, ZegoMediaPlayerVideoHandler, ZegoMediaPlayerAudioHandler>

@property (nonatomic, strong) ZegoExpressEngine *engine;

@property (nonatomic, strong) ZegoMediaPlayer *player;

@property (nonatomic, copy) NSString *roomID;

@property (nonatomic, assign) ZegoPublisherState publisherState;

@property (weak, nonatomic) IBOutlet UIView *publisherView;
@property (weak, nonatomic) IBOutlet UIButton *publishButton;

@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UILabel *currentProcessLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;
@property (weak, nonatomic) IBOutlet UISlider *processSlider;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UISwitch *enableRepeatSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *enableAuxSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *muteLocalSwitch;

@end

@implementation ZGMediaPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.roomID = @"MediaPlayerRoom-1";
    self.title = _roomID;
    
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];
    
    self.engine = [ZegoExpressEngine createEngineWithAppID:appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];
    ZGLogInfo(@" 🚀 Initialize the ZegoExpressEngine");
    
    NSString *userID = [ZGUserIDHelper userID];
    [self.engine loginRoom:_roomID user:[ZegoUser userWithUserID:userID] config:nil];
    ZGLogInfo(@" 🚪 Login room. roomID: %@", _roomID);
    
    [self startLive];
    
    [self initializeMediaPlayer];
}

- (void)initializeMediaPlayer {
    self.player = [self.engine createMediaPlayer];
    if (!self.player) {
        ZGLogWarn(@" ❗️ Create Media Player Fail");
    }
    
    [self.player loadResource:self.mediaItem.fileURL callback:^(int errorCode) {
        ZGLogInfo(@" 🚩 💽 Media Player Load Resource ErrorCode: %d", errorCode);
        [self setupMediaPlayerUI];
    }];
    
    // set media player event handler
    [self.player setEventHandler:self];
    
    // enable audio frame callback
    [self.player setAudioHandler:self];
    
    // enable video frame callback
    [self.player setVideoHandler:self format:ZegoVideoFrameFormatNV12 type:ZegoVideoFrameTypeCVPixerBuffer];
    
    [self.player enableAux:YES];
    
    [self.player enableRepeat:YES];
    
    [self.player muteLocal:NO];
}

- (void)setupMediaPlayerUI {
    self.totalDurationLabel.text = [NSString stringWithFormat:@"%02llu:%02llu", self.player.totalDuration / 1000 / 60, (self.player.totalDuration / 1000) % 60];
    
    self.processSlider.maximumValue = self.player.totalDuration;
    self.processSlider.minimumValue = 0.0;
    self.processSlider.value = self.player.currentProgress;
    self.processSlider.continuous = NO;
 
    [self.processSlider addTarget:self action:@selector(processSliderTouchDown) forControlEvents:UIControlEventTouchDown];
    [self.processSlider addTarget:self action:@selector(processSliderTouchUp) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    
    self.volumeSlider.maximumValue = 100.0;
    self.volumeSlider.minimumValue = 0.0;
    self.volumeSlider.value = self.player.volume;
    self.volumeSlider.continuous = NO;
    
    self.enableRepeatSwitch.on = YES;
    self.enableAuxSwitch.on = YES;
    self.muteLocalSwitch.on = NO;
    
    if (self.mediaItem.isVideo) {
        [self.player setPlayerCanvas:[ZegoCanvas canvasWithView:self.playerView]];
    } else {
        [self.playerView addSubview:({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.playerView.frame.size.width, self.playerView.frame.size.height)];
            label.text = @"Audio";
            label.font = [UIFont boldSystemFontOfSize:60];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        })];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.isBeingDismissed || self.isMovingFromParentViewController
        || (self.navigationController && self.navigationController.isBeingDismissed)) {
        ZGLogInfo(@" 🏳️ Destroy the MediaPlayer");
        [self.engine destroyMediaPlayer:self.player];
        
        ZGLogInfo(@" 🏳️ Destroy the ZegoExpressEngine");
        [ZegoExpressEngine destroyEngine];
    }
    [super viewDidDisappear:animated];
}

#pragma mark Publisher Actions

- (IBAction)publishButton:(UIButton *)sender {
    switch (_publisherState) {
        case ZegoPublisherStateNoPublish:
            [self startLive];
            break;
        case ZegoPublisherStatePublishing: case ZegoPublisherStatePublishRequesting:
            [self stopLive];
            break;
    }
}

- (void)startLive {
    [self.engine startPreview:[ZegoCanvas canvasWithView:self.publisherView]];
    ZGLogInfo(@" 🔌 Start preview");
    
    // use userID as streamID
    [self.engine startPublishing:[ZGUserIDHelper userID]];
    ZGLogInfo(@" 📤 Start publishing stream. streamID: %@", [ZGUserIDHelper userID]);
}

- (void)stopLive {
    [self.engine stopPublishing];
    ZGLogInfo(@" 📤 Stop publishing stream");
    
    [self.engine stopPreview];
    ZGLogInfo(@" 🔌 Stop preview");
}

#pragma mark Media Player Actions

- (IBAction)playButtonClick:(UIButton *)sender {
    [self.player start];
    ZGLogInfo(@" ▶️ Media Player Start");
}

- (IBAction)pauseButtonClick:(UIButton *)sender {
    [self.player pause];
    ZGLogInfo(@" ⏸ Media Player Pause");
}

- (IBAction)resumeButtonClick:(UIButton *)sender {
    [self.player resume];
    ZGLogInfo(@" ⏯ Media Player Resume");
}

- (IBAction)stopButtonClick:(UIButton *)sender {
    [self.player stop];
    ZGLogInfo(@" ⏹ Media Player Start Stop");
}

- (IBAction)enableRepeatSwitchAction:(UISwitch *)sender {
    [self.player enableRepeat:sender.on];
    ZGLogInfo(@" %@ Media Player Enable Repeat: %@", sender.on ? @"🔂" : @"↩️", sender.on ? @"YES" : @"NO");
}

- (IBAction)enableAuxSwitchAction:(UISwitch *)sender {
    [self.player enableAux:sender.on];
    ZGLogInfo(@" ⏺ Media Player Enable Aux: %@", sender.on ? @"YES" : @"NO");
}

- (IBAction)muteLocalSwitchAction:(UISwitch *)sender {
    [self.player muteLocal:sender.on];
    ZGLogInfo(@" %@ Media Player Mute Local: %@", sender.on ? @"🔇" : @"🔈", sender.on ? @"YES" : @"NO");
}

#pragma mark Media Player Slider Actions

- (IBAction)volumeSliderValueChanged:(UISlider *)sender {
    [self.player setVolume:(int)sender.value];
    ZGLogInfo(@" 🔊 Media Player Set Volume: %d", (int)sender.value);
}

- (IBAction)processSliderValueChanged:(UISlider *)sender {
    [self.player seekTo:(unsigned long long)sender.value callback:^(int errorCode) {
        ZGLogInfo(@" 🚩 🔍 Media Player Seek To Time Result: errorCode: %d", errorCode);
    }];
    ZGLogInfo(@" 🔍 Media Player Seek To Time: %llu", (unsigned long long)sender.value);
}

- (void)processSliderTouchDown {
    [self.player pause];
}

- (void)processSliderTouchUp {
    [self.player resume];
}

#pragma mark Publisher Event

- (void)onPublisherStateUpdate:(ZegoPublisherState)state errorCode:(int)errorCode stream:(NSString *)streamID {
    ZGLogInfo(@" 🚩 📤 Publisher State Update Callback: %lu, errorCode: %d, streamID: %@", (unsigned long)state, (int)errorCode, streamID);
    
    _publisherState = state;
    
    switch (state) {
        case ZegoPublisherStateNoPublish:
            [self.publishButton setTitle:@"StartPublish" forState:UIControlStateNormal];
            break;
        case ZegoPublisherStatePublishing: case ZegoPublisherStatePublishRequesting:
            [self.publishButton setTitle:@"StopPublish" forState:UIControlStateNormal];
            break;
    }
}


#pragma mark - Media Player Event Handler

- (void)mediaPlayer:(ZegoMediaPlayer *)player stateUpdate:(ZegoMediaPlayerState)state errorCode:(int)errorCode {
    ZGLogInfo(@" 🚩 📻 Media Player State Update: %d, errorCode: %d", (int)state, errorCode);
}

- (void)mediaPlayer:(ZegoMediaPlayer *)player networkEvent:(ZegoMediaPlayerNetworkEvent)event {
    ZGLogInfo(@" 🚩 ⏳ Media Player Network Event: %d", (int)event);
}

- (void)mediaPlayer:(ZegoMediaPlayer *)player playingProgress:(unsigned long long)millisecond {
    self.currentProcessLabel.text = [NSString stringWithFormat:@"%02llu:%02llu", millisecond / 1000 / 60, (millisecond / 1000) % 60];
    [self.processSlider setValue:millisecond animated:YES];
}

#pragma mark - Media Player Audio Handler

/// @note Need to switch threads before processing audio frames
- (void)mediaPlayer:(ZegoMediaPlayer *)player audioFrameData:(const unsigned char *)data param:(ZegoAudioFrameParam *)param {
//    NSLog(@"audio frame callback. bufferLength:%d, sampleRate:%d, channels:%d", param.bufferLength, param.sampleRate, param.channels);
}

#pragma mark - Media Player Video Handler

/// When video frame type is set to `ZegoVideoFrameTypeCVPixelBuffer`, video frame CVPixelBuffer data will be called back from this function
/// @note Need to switch threads before processing video frames
- (void)mediaPlayer:(ZegoMediaPlayer *)player videoFramePixelBuffer:(nonnull CVPixelBufferRef)buffer param:(nonnull ZegoVideoFrameParam *)param {
//    NSLog(@"pixel buffer video frame callback. format:%d, width:%f, height:%f", (int)param.format, param.size.width, param.size.height);
}

/// When video frame type is set to `ZegoVideoFrameTypeRawdata`, video frame raw data will be called back from this function
/// @note Need to switch threads before processing video frames
- (void)mediaPlayer:(ZegoMediaPlayer *)player videoFrameRawData:(const char * _Nonnull *)data param:(ZegoVideoFrameParam *)param {
//    NSLog(@"raw data video frame callback. format:%d, width:%f, height:%f", (int)param.format, param.size.width, param.size.height);
}

@end

#endif
