//
//  ZGPublishTopicPublishStreamVC.m
//  ZegoExpressExample-iOS-OC
//
//  Created by jeffreypeng on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import "ZGPublishTopicPublishStreamVC.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGUserIDHelper.h"
#import "ZGPublishTopicConfigManager.h"
#import "ZGPublishTopicSettingVC.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>


NSString* const ZGPublishTopicPublishStreamVCKey_roomID = @"kRoomID";
NSString* const ZGPublishTopicPublishStreamVCKey_streamID = @"kStreamID";

@interface ZGPublishTopicPublishStreamVC () <ZGPublishTopicConfigChangedHandler, ZegoEventHandler>

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UITextView *processTipTextView;
@property (weak, nonatomic) IBOutlet UILabel *publishQualityLabel;
@property (weak, nonatomic) IBOutlet UIView *startPublishConfigView;
@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *startLiveButn;
@property (weak, nonatomic) IBOutlet UIButton *stopLiveButn;

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;

@property (nonatomic) ZegoVideoConfig *avConfig;
@property (nonatomic) ZegoViewMode previewViewMode;
@property (nonatomic) BOOL enableHardwareEncode;
@property (nonatomic) ZegoVideoMirrorMode videoMirrorMode;
@property (nonatomic) BOOL enableMic;
@property (nonatomic) BOOL enableCamera;
@property (nonatomic) BOOL muteAudioOutput;

@property (nonatomic) ZegoRoomState roomState;
@property (nonatomic) ZegoPublisherState publisherState;

@property (nonatomic) ZegoExpressEngine *engine;

@end

@implementation ZGPublishTopicPublishStreamVC

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PublishStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGPublishTopicPublishStreamVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[ZGPublishTopicConfigManager sharedManager] setConfigChangedHandler:self];
    
    [self initializeTopicConfigs];
    [self setupUI];
    [self initializeEngine];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.isBeingDismissed || self.isMovingFromParentViewController
        || (self.navigationController && self.navigationController.isBeingDismissed)) {
        
        ZGLogInfo(@" 🔌 Stop preview");
        [self.engine stopPreview];
        
        // Stop publishing before exiting
        if (self.publisherState != ZegoPublisherStateNoPublish) {
            ZGLogInfo(@" 📤 Stop publishing stream");
            [self.engine stopPublishing];
        }
        
        // Logout room before exiting
        if (self.roomState != ZegoRoomStateDisconnected) {
            ZGLogInfo(@" 🚪 Logout room");
            [self.engine logoutRoom:self.roomID];
        }
        
        // Can destroy the engine when you don't need audio and video calls
        ZGLogInfo(@" 🏳️ Destroy the ZegoExpressEngine");
        [ZegoExpressEngine destroyEngine];
    }
    [super viewDidDisappear:animated];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - Initialize Methods

- (void)initializeTopicConfigs {
    ZegoVideoConfig *avConfig = [[ZegoVideoConfig alloc] init];
    CGSize resolution = [ZGPublishTopicConfigManager sharedManager].resolution;
    avConfig.captureResolution = CGSizeMake(resolution.width, resolution.height) ;
    avConfig.encodeResolution = CGSizeMake(resolution.width, resolution.height) ;
    
    avConfig.fps = (int)[ZGPublishTopicConfigManager sharedManager].fps;
    avConfig.bitrate = (int)[ZGPublishTopicConfigManager sharedManager].bitrate;
    self.avConfig = avConfig;
    
    self.previewViewMode = [ZGPublishTopicConfigManager sharedManager].previewViewMode;
    
    self.enableHardwareEncode = [ZGPublishTopicConfigManager sharedManager].isEnableHardwareEncode;
    
    self.videoMirrorMode = [ZGPublishTopicConfigManager sharedManager].mirrorMode;
    
    self.enableMic = YES;
    self.enableCamera = YES;
    self.muteAudioOutput = YES;
}

- (void)setupUI {
    self.navigationItem.title = @"Publish Stream";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Setting" style:UIBarButtonItemStylePlain target:self action:@selector(goConfigPage:)];
    
    self.processTipTextView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.processTipTextView.textColor = [UIColor whiteColor];
    
    self.publishQualityLabel.text = @"";
    self.publishQualityLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.publishQualityLabel.textColor = [UIColor whiteColor];
    
    self.stopLiveButn.alpha = 0;
    self.startPublishConfigView.alpha = 1;
    
    self.roomID = [self savedValueForKey:ZGPublishTopicPublishStreamVCKey_roomID];
    self.roomIDTextField.text = self.roomID;
    
    self.streamID = [self savedValueForKey:ZGPublishTopicPublishStreamVCKey_streamID];
    self.streamIDTextField.text = self.streamID;
}

- (void)goConfigPage:(id)sender {
    ZGPublishTopicSettingVC *vc = [ZGPublishTopicSettingVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)initializeEngine {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];
    
    [self appendProcessTipAndMakeVisible:@" 🚀 Initialize the ZegoExpressEngine"];
    ZGLogInfo(@" 🚀 Initialize the ZegoExpressEngine");
    
    self.engine = [ZegoExpressEngine createEngineWithAppID:(unsigned int)appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];
    
    // Set debug verbose on
//    [self.engine setDebugVerbose:YES language:ZegoLanguageEnglish];
    
    // Set video config
    [self.engine setVideoConfig:self.avConfig];
    
    // Set hardware encoder
    [self.engine enableHardwareEncoder:self.enableHardwareEncode];
    
    // Set video mirror mode
    [self.engine setVideoMirrorMode:self.videoMirrorMode];
    
    // Set enable microphone
    [self.engine enableMicrophone:self.enableMic];
    
    // Set enable camera
    [self.engine enableCamera:self.enableCamera];
    
    // Set enable audio output
    [self.engine muteAudioOutput:self.muteAudioOutput];
    
    // Start preview
    ZGLogInfo(@" 🔌 Start preview");
    [self.engine startPreview:[ZegoCanvas canvasWithView:self.previewView viewMode:self.previewViewMode]];
}

#pragma mark - Actions

- (IBAction)startLiveButnClick:(id)sender {
    [self startLive];
}

- (IBAction)stopLiveButnClick:(id)sender {
    [self stopLive];
}

- (IBAction)muteAudioOutput:(UISwitch*)sender {
    self.muteAudioOutput = sender.isOn;
    [self.engine muteAudioOutput:self.muteAudioOutput];
}

- (IBAction)enableMicValueChanged:(UISwitch*)sender {
    self.enableMic = sender.isOn;
    [self.engine enableMicrophone:self.enableMic];
}

- (IBAction)enableCameraValueChanged:(UISwitch*)sender {
    self.enableCamera = sender.isOn;
    [self.engine enableCamera:self.enableCamera];
}

- (void)startLive {
    [self appendProcessTipAndMakeVisible:@" 🚪 Start login room"];
    ZGLogInfo(@" 🚪 Start login room");
    
    self.roomID = self.roomIDTextField.text;
    self.streamID = self.streamIDTextField.text;
    
    [self saveValue:self.roomID forKey:ZGPublishTopicPublishStreamVCKey_roomID];
    [self saveValue:self.streamID forKey:ZGPublishTopicPublishStreamVCKey_streamID];
    
    // This demonstrates simply using the timestamp as the userID. In actual use, you can set the business-related userID as needed.
    NSString *userID = ZGUserIDHelper.userID;
    NSString *userName = ZGUserIDHelper.userName;
    
    ZegoRoomConfig *config = [ZegoRoomConfig defaultConfig];
    
    // Login room
    [self.engine loginRoom:self.roomID user:[ZegoUser userWithUserID:userID userName:userName] config:config];
    
    [self appendProcessTipAndMakeVisible:@" 📤 Start publishing stream"];
    ZGLogInfo(@" 📤 Start publishing stream");
    
    // Start publishing
    [self.engine startPublishing:self.streamID];
}

- (void)stopLive {
    // Stop publishing
    [self.engine stopPublishing];
    [self appendProcessTipAndMakeVisible:@" 📤 Stop publishing stream"];
    ZGLogInfo(@" 📤 Stop publishing stream");
    // Logout room
    [self.engine logoutRoom:self.roomID];
    [self appendProcessTipAndMakeVisible:@" 🚪 Logout room"];
    ZGLogInfo(@" 🚪 Logout room");
    
    self.publishQualityLabel.text = @"";
}


#pragma mark - Change UI Methods

- (void)invalidateLiveStateUILayout {
    if (self.roomState == ZegoRoomStateConnected &&
        self.publisherState == ZegoPublisherStatePublishing) {
        [self showLiveStartedStateUI];
    } else if (self.roomState == ZegoRoomStateDisconnected &&
        self.publisherState == ZegoPublisherStateNoPublish) {
        [self showLiveStoppedStateUI];
    } else {
        [self showLiveRequestingStateUI];
    }
}

- (void)showLiveRequestingStateUI {
    [self.startLiveButn setEnabled:NO];
    [self.stopLiveButn setEnabled:NO];
}

- (void)showLiveStartedStateUI {
    [self.startLiveButn setEnabled:NO];
    [self.stopLiveButn setEnabled:YES];
    [UIView animateWithDuration:0.5 animations:^{
        self.startPublishConfigView.alpha = 0;
        self.stopLiveButn.alpha = 1;
    }];
}

- (void)showLiveStoppedStateUI {
    [self.startLiveButn setEnabled:YES];
    [self.stopLiveButn setEnabled:NO];
    [UIView animateWithDuration:0.5 animations:^{
        self.startPublishConfigView.alpha = 1;
        self.stopLiveButn.alpha = 0;
    }];
}

- (void)appendProcessTipAndMakeVisible:(NSString *)tipText {
    if (!tipText || tipText.length == 0) {
        return;
    }
    
    NSString *oldText = self.processTipTextView.text;
    NSString *newLine = oldText.length == 0 ? @"" : @"\n";
    NSString *newText = [NSString stringWithFormat:@"%@%@%@", oldText, newLine, tipText];
    
    self.processTipTextView.text = newText;
    if(newText.length > 0 ) {
        UITextView *textView = self.processTipTextView;
        NSRange bottom = NSMakeRange(newText.length -1, 1);
        [textView scrollRangeToVisible:bottom];
//        NSRange range = NSMakeRange(textView.text.length, 0);
//        [textView scrollRangeToVisible:range];
        // an iOS bug, see https://stackoverflow.com/a/20989956/971070
        [textView setScrollEnabled:NO];
        [textView setScrollEnabled:YES];
    }
}


#pragma mark - ZegoExpress EventHandler Room Event

- (void)onRoomStateUpdate:(ZegoRoomState)state errorCode:(int)errorCode room:(NSString *)roomID {
    if (errorCode != 0) {
        [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@" 🚩 ❌ 🚪 Room state error, errorCode: %d", errorCode]];
        ZGLogWarn(@" 🚩 ❌ 🚪 Room state error, errorCode: %d", errorCode);
    } else {
        if (state == ZegoRoomStateConnected) {
            [self appendProcessTipAndMakeVisible:@" 🚩 🚪 Login room success"];
            ZGLogInfo(@" 🚩 🚪 Login room success");
        } else if (state == ZegoRoomStateConnecting) {
            [self appendProcessTipAndMakeVisible:@" 🚩 🚪 Requesting login room"];
            ZGLogInfo(@" 🚩 🚪 Requesting login room");
        } else if (state == ZegoRoomStateDisconnected) {
            [self appendProcessTipAndMakeVisible:@" 🚩 🚪 Logout room"];
            ZGLogInfo(@" 🚩 🚪 Logout room");
            
            // After logout room, the preview will stop. You need to re-start preview.
            [self.engine startPreview:[ZegoCanvas canvasWithView:self.previewView viewMode:self.previewViewMode]];
        }
    }
    self.roomState = state;
    [self invalidateLiveStateUILayout];
}

#pragma mark - ZegoExpress EventHandler Publish Event

- (void)onPublisherStateUpdate:(ZegoPublisherState)state errorCode:(int)errorCode stream:(NSString *)streamID {
    if (errorCode != 0) {
        [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@" 🚩 ❌ 📤 Publishing stream error of streamID: %@, errorCode:%d", streamID, errorCode]];
        ZGLogWarn(@" 🚩 ❌ 📤 Publishing stream error of streamID: %@, errorCode:%d", streamID, errorCode);
    } else {
        if (state == ZegoPublisherStatePublishing) {
            [self appendProcessTipAndMakeVisible:@" 🚩 📤 Publishing stream"];
            ZGLogInfo(@" 🚩 📤 Publishing stream");
        } else if (state == ZegoPublisherStatePublishRequesting) {
            [self appendProcessTipAndMakeVisible:@" 🚩 📤 Requesting publish stream"];
            ZGLogInfo(@" 🚩 📤 Requesting publish stream");
        } else if (state == ZegoPublisherStateNoPublish) {
            [self appendProcessTipAndMakeVisible:@" 🚩 📤 Stop playing stream"];
            ZGLogInfo(@" 🚩 📤 Stop playing stream");
        }
    }
    self.publisherState = state;
    [self invalidateLiveStateUILayout];
}

- (void)onPublisherQualityUpdate:(ZegoPublishStreamQuality *)quality stream:(NSString *)streamID {
    NSString *networkQuality = @"";
    switch (quality.level) {
        case 0:
            networkQuality = @"☀️";
            break;
        case 1:
            networkQuality = @"⛅️";
            break;
        case 2:
            networkQuality = @"☁️";
            break;
        case 3:
            networkQuality = @"🌧";
            break;
        case 4:
            networkQuality = @"❌";
            break;
        default:
            break;
    }
    NSMutableString *text = [NSMutableString string];
    [text appendFormat:@"FPS: %d fps \n", (int)quality.videoSendFPS];
    [text appendFormat:@"Bitrate: %.2f kb/s \n", quality.videoKBPS];
    [text appendFormat:@"Resolution: %dx%d \n", (int)quality.videoResolution.width, (int)quality.videoResolution.height];
    [text appendFormat:@"HardwareEncode: %@ \n", quality.isHardwareEncode ? @"✅" : @"❎"];
    [text appendFormat:@"NetworkQuality: %@", networkQuality];
    self.publishQualityLabel.text = [text copy];
}

#pragma mark - ZGPublishTopicConfigChangedHandler

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager resolutionDidChange:(CGSize)resolution {
    ZegoVideoConfig *avConfig = self.avConfig;
    if (!avConfig) {
        return;
    }
    avConfig.captureResolution = CGSizeMake(resolution.width, resolution.height);
    avConfig.encodeResolution = CGSizeMake(resolution.width, resolution.height);
        
    [self.engine setVideoConfig:avConfig];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager fpsDidChange:(NSInteger)fps {
    ZegoVideoConfig *avConfig = self.avConfig;
    if (!avConfig) {
        return;
    }
    avConfig.fps = (int)fps;
    
    [self.engine setVideoConfig:avConfig];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager bitrateDidChange:(NSInteger)bitrate {
    ZegoVideoConfig *avConfig = self.avConfig;
    if (!avConfig) {
        return;
    }
    avConfig.bitrate = (int)bitrate;
    [self.engine setVideoConfig:avConfig];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager previewViewModeDidChange:(ZegoViewMode)previewViewMode {
    self.previewViewMode = previewViewMode;
    [self.engine startPreview:[ZegoCanvas canvasWithView:self.previewView viewMode:self.previewViewMode]];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager enableHardwareEncodeDidChange:(BOOL)enableHardwareEncode {
    self.enableHardwareEncode = enableHardwareEncode;
    [self.engine enableHardwareEncoder:enableHardwareEncode];
    ZGLogInfo(@" ❕ Tips: The hardware encoding needs to be set before publishing stream. If it is set in publishing stream, it needs to be publish again to take effect.");
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager mirrorModeDidChange:(ZegoVideoMirrorMode)mirrorMode {
    self.videoMirrorMode = mirrorMode;
    [self.engine setVideoMirrorMode:self.videoMirrorMode];
}

@end

#endif
