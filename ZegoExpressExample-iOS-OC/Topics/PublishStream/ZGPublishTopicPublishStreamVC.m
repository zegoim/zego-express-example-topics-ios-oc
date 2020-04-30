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

@interface ZGPublishTopicPublishStreamVC () <ZGPublishTopicConfigChangedHandler, ZegoEventHandler, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UITextView *processTipTextView;
@property (weak, nonatomic) IBOutlet UILabel *publishResolutionLabel;
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
@property (nonatomic, copy) NSString *streamExtraInfo;
@property (nonatomic) BOOL enableHardwareEncode;
@property (nonatomic) ZegoVideoMirrorMode videoMirrorMode;
@property (nonatomic) BOOL enableMic;
@property (nonatomic) BOOL enableCamera;
@property (nonatomic) BOOL muteSpeaker;

@property (nonatomic) ZegoRoomState roomState;
@property (nonatomic) ZegoPublisherState publisherState;

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
    [self createEngine];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.isBeingDismissed || self.isMovingFromParentViewController
        || (self.navigationController && self.navigationController.isBeingDismissed)) {
        
        ZGLogInfo(@" 🔌 Stop preview");
        [[ZegoExpressEngine sharedEngine] stopPreview];
        
        // Stop publishing before exiting
        if (self.publisherState != ZegoPublisherStateNoPublish) {
            ZGLogInfo(@" 📤 Stop publishing stream");
            [[ZegoExpressEngine sharedEngine] stopPublishingStream];
        }
        
        // Logout room before exiting
        if (self.roomState != ZegoRoomStateDisconnected) {
            ZGLogInfo(@" 🚪 Logout room");
            [[ZegoExpressEngine sharedEngine] logoutRoom:self.roomID];
        }
        
        // Can destroy the engine when you don't need audio and video calls
        ZGLogInfo(@" 🏳️ Destroy ZegoExpressEngine");
        [ZegoExpressEngine destroyEngine:nil];
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
    
    self.streamExtraInfo = [ZGPublishTopicConfigManager sharedManager].streamExtraInfo;
    
    self.enableHardwareEncode = [ZGPublishTopicConfigManager sharedManager].isEnableHardwareEncode;
    
    self.videoMirrorMode = [ZGPublishTopicConfigManager sharedManager].mirrorMode;
    
    self.enableMic = YES;
    self.enableCamera = YES;
    self.muteSpeaker = YES;
}

- (void)setupUI {
    self.navigationItem.title = @"Publish Stream";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Setting" style:UIBarButtonItemStylePlain target:self action:@selector(goConfigPage:)];
    
    self.processTipTextView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.processTipTextView.textColor = [UIColor whiteColor];
    
    self.publishQualityLabel.text = @"";
    self.publishQualityLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.publishQualityLabel.textColor = [UIColor whiteColor];
    
    self.publishResolutionLabel.text = @"";
    self.publishResolutionLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.publishResolutionLabel.textColor = [UIColor whiteColor];
    
    self.stopLiveButn.alpha = 0;
    self.startPublishConfigView.alpha = 1;
    
    self.roomID = [self savedValueForKey:ZGPublishTopicPublishStreamVCKey_roomID];
    self.roomIDTextField.text = self.roomID;
    self.roomIDTextField.delegate = self;
    
    self.streamID = [self savedValueForKey:ZGPublishTopicPublishStreamVCKey_streamID];
    self.streamIDTextField.text = self.streamID;
    self.streamIDTextField.delegate = self;
}

- (void)goConfigPage:(id)sender {
    ZGPublishTopicSettingVC *vc = [ZGPublishTopicSettingVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)createEngine {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];
    
    [self appendProcessTipAndMakeVisible:@" 🚀 Create ZegoExpressEngine"];
    ZGLogInfo(@" 🚀 Create ZegoExpressEngine");
    
    [ZegoExpressEngine createEngineWithAppID:(unsigned int)appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];
    
    // Set debug verbose on
//    [[ZegoExpressEngine sharedEngine] setDebugVerbose:YES language:ZegoLanguageEnglish];
    
    // Set video config
    [[ZegoExpressEngine sharedEngine] setVideoConfig:self.avConfig];
    
    // Set hardware encoder
    [[ZegoExpressEngine sharedEngine] enableHardwareEncoder:self.enableHardwareEncode];
    
    // Set video mirror mode
    [[ZegoExpressEngine sharedEngine] setVideoMirrorMode:self.videoMirrorMode];
    
    // Set enable microphone
    [[ZegoExpressEngine sharedEngine] muteMicrophone:!self.enableMic];
    
    // Set enable camera
    [[ZegoExpressEngine sharedEngine] enableCamera:self.enableCamera];
    
    // Set enable audio output
    [[ZegoExpressEngine sharedEngine] muteSpeaker:self.muteSpeaker];
    
    // Start preview
    ZegoCanvas *previewCanvas = [ZegoCanvas canvasWithView:self.previewView];
    previewCanvas.viewMode = self.previewViewMode;
    ZGLogInfo(@" 🔌 Start preview");
    [[ZegoExpressEngine sharedEngine] startPreview:previewCanvas];
}

#pragma mark - Actions

- (IBAction)startLiveButnClick:(id)sender {
    [self startLive];
}

- (IBAction)stopLiveButnClick:(id)sender {
    [self stopLive];
}

- (IBAction)muteSpeaker:(UISwitch*)sender {
    self.muteSpeaker = sender.isOn;
    [[ZegoExpressEngine sharedEngine] muteSpeaker:self.muteSpeaker];
}

- (IBAction)enableMicValueChanged:(UISwitch*)sender {
    self.enableMic = sender.isOn;
    [[ZegoExpressEngine sharedEngine] muteMicrophone:!self.enableMic];
}

- (IBAction)enableCameraValueChanged:(UISwitch*)sender {
    self.enableCamera = sender.isOn;
    [[ZegoExpressEngine sharedEngine] enableCamera:self.enableCamera];
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
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomID user:[ZegoUser userWithUserID:userID userName:userName] config:config];
    
    [self appendProcessTipAndMakeVisible:@" 📤 Start publishing stream"];
    
    ZGLogInfo(@" 💬 Set stream extra info: %@", self.streamExtraInfo);
    [[ZegoExpressEngine sharedEngine] setStreamExtraInfo:self.streamExtraInfo callback:^(int errorCode) {
        ZGLogInfo(@" 🚩 💬 Set stream extra info result: %d", errorCode);
    }];
    
    ZGLogInfo(@" 📤 Start publishing stream");
    
    // Start publishing
    [[ZegoExpressEngine sharedEngine] startPublishingStream:self.streamID];
}

- (void)stopLive {
    // Stop publishing
    [[ZegoExpressEngine sharedEngine] stopPublishingStream];
    [self appendProcessTipAndMakeVisible:@" 📤 Stop publishing stream"];
    ZGLogInfo(@" 📤 Stop publishing stream");
    // Logout room
    [[ZegoExpressEngine sharedEngine] logoutRoom:self.roomID];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField == self.roomIDTextField) {
        [self.streamIDTextField becomeFirstResponder];
    } else if (textField == self.streamIDTextField) {
        [self startLive];
    }
    
    return YES;
}


#pragma mark - ZegoExpress EventHandler Room Event

- (void)onRoomStateUpdate:(ZegoRoomState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData roomID:(NSString *)roomID {
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
            ZegoCanvas *previewCanvas = [ZegoCanvas canvasWithView:self.previewView];
            previewCanvas.viewMode = self.previewViewMode;
            [[ZegoExpressEngine sharedEngine] startPreview:previewCanvas];
        }
    }
    self.roomState = state;
    [self invalidateLiveStateUILayout];
}

#pragma mark - ZegoExpress EventHandler Publish Event

- (void)onPublisherStateUpdate:(ZegoPublisherState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData streamID:(NSString *)streamID {
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

- (void)onPublisherQualityUpdate:(ZegoPublishStreamQuality *)quality streamID:(NSString *)streamID {
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
    [text appendFormat:@"HardwareEncode: %@ \n", quality.isHardwareEncode ? @"✅" : @"❎"];
    [text appendFormat:@"NetworkQuality: %@", networkQuality];
    self.publishQualityLabel.text = [text copy];
}

- (void)onPublisherVideoSizeChanged:(CGSize)size channel:(ZegoPublishChannel)channel {
    if (channel == ZegoPublishChannelAux) {
        return;
    }
    self.publishResolutionLabel.text = [NSString stringWithFormat:@"Resolution: %.fx%.f  ", size.width, size.height];
}

#pragma mark - ZGPublishTopicConfigChangedHandler

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager resolutionDidChange:(CGSize)resolution {
    ZegoVideoConfig *avConfig = self.avConfig;
    if (!avConfig) {
        return;
    }
    avConfig.captureResolution = CGSizeMake(resolution.width, resolution.height);
    avConfig.encodeResolution = CGSizeMake(resolution.width, resolution.height);
        
    [[ZegoExpressEngine sharedEngine] setVideoConfig:avConfig];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager fpsDidChange:(NSInteger)fps {
    ZegoVideoConfig *avConfig = self.avConfig;
    if (!avConfig) {
        return;
    }
    avConfig.fps = (int)fps;
    
    [[ZegoExpressEngine sharedEngine] setVideoConfig:avConfig];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager bitrateDidChange:(NSInteger)bitrate {
    ZegoVideoConfig *avConfig = self.avConfig;
    if (!avConfig) {
        return;
    }
    avConfig.bitrate = (int)bitrate;
    [[ZegoExpressEngine sharedEngine] setVideoConfig:avConfig];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager previewViewModeDidChange:(ZegoViewMode)previewViewMode {
    self.previewViewMode = previewViewMode;
    ZegoCanvas *previewCanvas = [ZegoCanvas canvasWithView:self.previewView];
    previewCanvas.viewMode = self.previewViewMode;
    [[ZegoExpressEngine sharedEngine] startPreview:previewCanvas];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager streamExtraInfoDidChange:(NSString *)extraInfo {
    self.streamExtraInfo = extraInfo;
    ZGLogInfo(@" 💬 Set stream extra info: %@", self.streamExtraInfo);
    [[ZegoExpressEngine sharedEngine] setStreamExtraInfo:self.streamExtraInfo callback:^(int errorCode) {
        ZGLogInfo(@" 🚩 💬 Set stream extra info result: %d", errorCode);
    }];

}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager enableHardwareEncodeDidChange:(BOOL)enableHardwareEncode {
    self.enableHardwareEncode = enableHardwareEncode;
    [[ZegoExpressEngine sharedEngine] enableHardwareEncoder:enableHardwareEncode];
    ZGLogInfo(@" ❕ Tips: The hardware encoding needs to be set before publishing stream. If it is set in publishing stream, it needs to be publish again to take effect.");
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager mirrorModeDidChange:(ZegoVideoMirrorMode)mirrorMode {
    self.videoMirrorMode = mirrorMode;
    [[ZegoExpressEngine sharedEngine] setVideoMirrorMode:self.videoMirrorMode];
}

@end

#endif
