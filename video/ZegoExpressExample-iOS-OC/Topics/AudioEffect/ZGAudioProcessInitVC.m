//
//  ZGAudioProcessInitVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessInitVC.h"
#import "ZGAudioProcessVoiceChangeConfigVC.h"
#import "ZGAudioProcessVirtualStereoConfigVC.h"
#import "ZGAudioProcessReverbConfigVC.h"

#import "ZGAudioProcessTopicConfigManager.h"
#import "ZGKeyCenter.h"
#import "ZGUserIDHelper.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

NSString* const ZGAudioProcessInitVCKey_roomID = @"kRoomID";
NSString* const ZGAudioProcessInitVCKey_streamID = @"kStreamID";

@interface ZGAudioProcessInitVC ()<ZegoEventHandler, ZGAudioProcessTopicConfigChangedHandler>

// Log View
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

// Preview and Play View
@property (weak, nonatomic) IBOutlet UIView *localPreviewView;
@property (weak, nonatomic) IBOutlet UIView *remotePlayView;

// CreateEngine
@property (nonatomic, assign) BOOL isTestEnv;
@property (weak, nonatomic) IBOutlet UILabel *isTestEnvLabel;

// LoginRoom
@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *userID;
@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *userIDLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginRoomButton;

// PublishStream
@property (weak, nonatomic) IBOutlet UITextField *publishStreamIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *startPublishingButton;

// PlayStream
@property (weak, nonatomic) IBOutlet UITextField *playStreamIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *startPlayingButton;

@end

@implementation ZGAudioProcessInitVC

#pragma mark - Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isTestEnv = YES;
    self.roomID = @"QuickStartRoom-1";
    self.userID = [ZGUserIDHelper userID];
    
    // Print SDK version
    [self appendLog:[NSString stringWithFormat:@" 🌞 SDK Version: %@", [ZegoExpressEngine getVersion]]];
    
    [self setupUI];
    
    [[ZGAudioProcessTopicConfigManager sharedInstance] addConfigChangedHandler:self];
    
    [self createEngine];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    [self destroyEngine];
}

- (void)setupUI {
    self.navigationItem.title = @"Quick Start";
    
    self.isTestEnvLabel.text = [NSString stringWithFormat:@"isTestEnv: %@", self.isTestEnv ? @"YES" : @"NO"];
    self.roomIDLabel.text = [NSString stringWithFormat:@"RoomID: %@", self.roomID];
    self.userIDLabel.text = [NSString stringWithFormat:@"UserID: %@", self.userID];
}

- (void)createEngine {
    
    unsigned int appID = [ZGKeyCenter appID];
    NSString *appSign = [ZGKeyCenter appSign];
    
    ZegoExpressEngine *engine = [ZegoExpressEngine sharedEngine];
    
    // Create ZegoExpressEngine and set self as a delegate (ZegoEventHandler)
    [ZegoExpressEngine createEngineWithAppID:appID appSign:appSign isTestEnv:self.isTestEnv scenario:ZegoScenarioGeneral eventHandler:self];
    
    // You need to set channel to ZegoAudioChannelStereo when using VirtualStereo
    ZegoAudioConfig *config = [ZegoAudioConfig configWithPreset:ZegoAudioConfigPresetStandardQualityStereo];
    [engine setAudioConfig:config];
    
    // Print log
    [self appendLog:@" 🚀 Create ZegoExpressEngine"];

}

#pragma mark - Step 1: LoginRoom

- (IBAction)loginRoomButtonClick:(UIButton *)sender {
    // Instantiate a ZegoUser object
    ZegoUser *user = [ZegoUser userWithUserID:self.userID];
    
    // Login room
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomID user:user];
    
    // Print log
    [self appendLog:@" 🚪 Start login room"];
}

#pragma mark - Step 2: StartPublishing

- (IBAction)startPublishingButtonClick:(UIButton *)sender {
    // Instantiate a ZegoCanvas for local preview
    ZegoCanvas *previewCanvas = [ZegoCanvas canvasWithView:self.localPreviewView];
    previewCanvas.viewMode = ZegoViewModeAspectFill;
    
    // Start preview
    [[ZegoExpressEngine sharedEngine] startPreview:previewCanvas];
    
    NSString *publishStreamID = self.publishStreamIDTextField.text;
    
    // If streamID is empty @"", SDK will pop up an UIAlertController if "isTestEnv" is set to YES
    [[ZegoExpressEngine sharedEngine] startPublishingStream:publishStreamID];
    
    // Print log
    [self appendLog:@" 📤 Start publishing stream"];
}

#pragma mark - Step 3: StartPlaying

- (IBAction)startPlayingButtonClick:(UIButton *)sender {
    // Instantiate a ZegoCanvas for play view
    ZegoCanvas *playCanvas = [ZegoCanvas canvasWithView:self.remotePlayView];
    playCanvas.viewMode = ZegoViewModeAspectFill;
    
    NSString *playStreamID = self.playStreamIDTextField.text;
    
    // If streamID is empty @"", SDK will pop up an UIAlertController if "isTestEnv" is set to YES
    [[ZegoExpressEngine sharedEngine] startPlayingStream:playStreamID canvas:playCanvas];
    
    // Print log
    [self appendLog:@" 📥 Strat playing stream"];
}

- (IBAction)voiceChangeConfigButnClick:(id)sender {
    ZGAudioProcessVoiceChangeConfigVC *vc = [ZGAudioProcessVoiceChangeConfigVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)virtualStereoConfigButnClick:(id)sender {
    ZGAudioProcessVirtualStereoConfigVC *vc = [ZGAudioProcessVirtualStereoConfigVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)reverbConfigButnClick:(id)sender {
    ZGAudioProcessReverbConfigVC *vc = [ZGAudioProcessReverbConfigVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - SoundAPI

- (void)applyVoiceChangerConfig {
    float voiceChangerParam = EXPRESS_API_VOICE_CHANGER_NONE;
    BOOL voiceChangerOpen = [ZGAudioProcessTopicConfigManager sharedInstance].voiceChangerOpen;
    if (voiceChangerOpen) {
        voiceChangerParam = [ZGAudioProcessTopicConfigManager sharedInstance].voiceChangerParam;
    }
    ZegoVoiceChangerParam *param = [[ZegoVoiceChangerParam alloc] init];
    param.pitch = voiceChangerParam;
    [[ZegoExpressEngine sharedEngine] setVoiceChangerParam: param];
//    [ZegoAudioProcessing setVoiceChangerParam:voiceChangerParam];
}

- (void)applyVirtualStereoConfig {
    BOOL virtualStereoOpen = [ZGAudioProcessTopicConfigManager sharedInstance].virtualStereoOpen;
    if (virtualStereoOpen) {
        int angle = [ZGAudioProcessTopicConfigManager sharedInstance].virtualStereoAngle;
        [[ZegoExpressEngine sharedEngine] enableVirtualStereo:YES angle:angle];
    } else {
        [[ZegoExpressEngine sharedEngine] enableVirtualStereo:NO angle:0];
    }
}

- (void)applyReverbConfig {
    BOOL reverbOpen = [ZGAudioProcessTopicConfigManager sharedInstance].reverbOpen;
    if (reverbOpen) {
        NSUInteger reverbMode = [ZGAudioProcessTopicConfigManager sharedInstance].reverbMode;
        ZegoReverbParam *param = [[ZegoReverbParam alloc] init];
        if (reverbMode != NSNotFound) {
            [[ZegoExpressEngine sharedEngine] setReverbParam:param];
            
//            [[ZegoExpressEngine sharedEngine] enableReverb:YES mode:reverbMode];
        } else {
            float roomSize = [ZGAudioProcessTopicConfigManager sharedInstance].customReverbRoomSize;
            float reverberance = [ZGAudioProcessTopicConfigManager sharedInstance].customReverberance;
            float damping = [ZGAudioProcessTopicConfigManager sharedInstance].customDamping;
            float drWetRatio = [ZGAudioProcessTopicConfigManager sharedInstance].customDryWetRatio;
            param.roomSize = roomSize;
            param.reverberance = reverberance;
            param.damping = damping;
            param.dryWetRatio = drWetRatio;
            [[ZegoExpressEngine sharedEngine] setReverbParam:param];

        }
    } else {
        [[ZegoExpressEngine sharedEngine] setReverbParam:[ZegoReverbParam new]];
    }
}

#pragma mark - Exit

- (void)destroyEngine {
    [self.loginRoomButton setTitle:@"LoginRoom" forState:UIControlStateNormal];
    [self.startPublishingButton setTitle:@"StartPublishing" forState:UIControlStateNormal];
    [self.startPlayingButton setTitle:@"StartPlaying" forState:UIControlStateNormal];
    
    // Logout room will automatically stop publishing/playing stream.
//    [[ZegoExpressEngine sharedEngine] logoutRoom:self.roomID];
    
    // Can destroy the engine when you don't need audio and video calls
    //
    // Destroy engine will automatically logout room and stop publishing/playing stream.
    [ZegoExpressEngine destroyEngine:nil];
    
    // Print log
    [self appendLog:@" 🏳️ Destroy ZegoExpressEngine"];
}

- (void)dealloc {
    // Logout room will automatically stop publishing/playing stream.
//    [[ZegoExpressEngine sharedEngine] logoutRoom:self.roomID];
            
    // Can destroy the engine when you don't need audio and video calls
    //
    // Destroy engine will automatically logout room and stop publishing/playing stream.
    [ZegoExpressEngine destroyEngine:nil];
}

#pragma mark - ZegoEventHandler Delegate

- (void)onEngineStateUpdate:(ZegoEngineState)state {
    [self appendLog:[NSString stringWithFormat:@" 🚩 🚘 ZegoExpressEngineState %lu",(unsigned long)state]];
}

/// Room status change notification
- (void)onRoomStateUpdate:(ZegoRoomState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData roomID:(NSString *)roomID {
    if (state == ZegoRoomStateConnected && errorCode == 0) {
        [self appendLog:@" 🚩 🚪 Login room success"];
        
        // Add a flag to the button for successful operation
        [self.loginRoomButton setTitle:@"✅ LoginRoom" forState:UIControlStateNormal];
    }
    
    if (errorCode != 0) {
        [self appendLog:@" 🚩 ❌ 🚪 Login room fail"];
        
        [self.loginRoomButton setTitle:@"❌ LoginRoom" forState:UIControlStateNormal];
    }
}

/// Publish stream state callback
- (void)onPublisherStateUpdate:(ZegoPublisherState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData streamID:(NSString *)streamID {
    if (state == ZegoPublisherStatePublishing && errorCode == 0) {
        [self appendLog:@" 🚩 📤 Publishing stream success"];
        
        // Add a flag to the button for successful operation
        [self.startPublishingButton setTitle:@"✅ StartPublishing" forState:UIControlStateNormal];
    }
    
    if (errorCode != 0) {
        [self appendLog:@" 🚩 ❌ 📤 Publishing stream fail"];
        
        [self.startPublishingButton setTitle:@"❌ StartPublishing" forState:UIControlStateNormal];
    }
}

/// Play stream state callback
- (void)onPlayerStateUpdate:(ZegoPlayerState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData streamID:(NSString *)streamID {
    if (state == ZegoPlayerStatePlaying && errorCode == 0) {
        [self appendLog:@" 🚩 📥 Playing stream success"];
        
        // Add a flag to the button for successful operation
        [self.startPlayingButton setTitle:@"✅ StartPlaying" forState:UIControlStateNormal];
    }
    
    if (errorCode != 0) {
        [self appendLog:@" 🚩 ❌ 📥 Playing stream fail"];
        
        [self.startPlayingButton setTitle:@"❌ StartPlaying" forState:UIControlStateNormal];
    }
}

#pragma mark - ZGAudioProcessTopicConfigChangedHandler

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
               voiceChangerOpenChanged:(BOOL)voiceChangerOpen {
    [self applyVoiceChangerConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
              voiceChangerParamChanged:(float)voiceChangerParam {
    [self applyVoiceChangerConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
              virtualStereoOpenChanged:(BOOL)virtualStereoOpen {
    [self applyVirtualStereoConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
             virtualStereoAngleChanged:(int)virtualStereoAngle {
    [self applyVirtualStereoConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
                     reverbOpenChanged:(BOOL)reverbOpen {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
                     reverbModeChanged:(NSUInteger)reverbMode {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
           customReverbRoomSizeChanged:(float)customReverbRoomSize {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
              customDryWetRatioChanged:(float)customDryWetRatio {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
                  customDampingChanged:(float)customDamping {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
             customReverberanceChanged:(float)customReverberance {
    [self applyReverbConfig];
}

#pragma mark - Helper Methods

/// Append Log to Top View
- (void)appendLog:(NSString *)tipText {
    if (!tipText || tipText.length == 0) {
        return;
    }
    
    ZGLogInfo(@"%@", tipText);
    
    NSString *oldText = self.logTextView.text;
    NSString *newLine = oldText.length == 0 ? @"" : @"\n";
    NSString *newText = [NSString stringWithFormat:@"%@%@%@", oldText, newLine, tipText];
    
    self.logTextView.text = newText;
    if(newText.length > 0 ) {
        UITextView *textView = self.logTextView;
        NSRange bottom = NSMakeRange(newText.length -1, 1);
        [textView scrollRangeToVisible:bottom];
        // an iOS bug, see https://stackoverflow.com/a/20989956/971070
        [textView setScrollEnabled:NO];
        [textView setScrollEnabled:YES];
    }
}

/// Click on other areas outside the keyboard to retract the keyboard
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
#endif
