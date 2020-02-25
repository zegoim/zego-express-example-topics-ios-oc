//
//  ZGPlayTopicPlayStreamVC.m
//  ZegoExpressExample-iOS-OC-iOS
//
//  Created by jeffreypeng on 2019/8/9.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Play

#import "ZGPlayTopicPlayStreamVC.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGPlayTopicConfigManager.h"
#import "ZGUserIDHelper.h"
#import "ZGPlayTopicSettingVC.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

NSString* const ZGPlayTopicPlayStreamVCKey_roomID = @"kRoomID";
NSString* const ZGPlayTopicPlayStreamVCKey_streamID = @"kStreamID";

@interface ZGPlayTopicPlayStreamVC () <ZGPlayTopicConfigChangedHandler, ZegoEventHandler, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *playLiveView;
@property (weak, nonatomic) IBOutlet UITextView *processTipTextView;
@property (weak, nonatomic) IBOutlet UILabel *playLiveResolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *playLiveQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *playStreamExtraInfoLabel;
@property (weak, nonatomic) IBOutlet UIView *startPlayLiveConfigView;
@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *startPlayLiveButn;
@property (weak, nonatomic) IBOutlet UIButton *stopPlayLiveButn;

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;

@property (nonatomic) ZegoViewMode playViewMode;
@property (nonatomic) BOOL enableHardwareDecode;
@property (nonatomic) int playStreamVolume;

@property (nonatomic) ZegoRoomState roomState;
@property (nonatomic) ZegoPlayerState playerState;

@property (nonatomic) ZegoExpressEngine *engine;

@end

@implementation ZGPlayTopicPlayStreamVC

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PlayStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGPlayTopicPlayStreamVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[ZGPlayTopicConfigManager sharedManager] setConfigChangedHandler:self];
    [self initializeTopicConfigs];
    [self setupUI];
    [self createEngine];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.isBeingDismissed || self.isMovingFromParentViewController
        || (self.navigationController && self.navigationController.isBeingDismissed)) {
        
        // Stop playing before exiting
        if (self.playerState != ZegoPlayerStateNoPlay) {
            ZGLogInfo(@" 📥 Stop playing stream");
            [self.engine stopPlayingStream:self.streamID];
        }
        
        // Logout room before exiting
        if (self.roomState != ZegoRoomStateDisconnected) {
            ZGLogInfo(@" 🚪 Logout room");
            [self.engine logoutRoom:self.roomID];
        }
        
        // Can destroy the engine when you don't need audio and video calls
        ZGLogInfo(@" 🏳️ Destroy ZegoExpressEngine");
        [ZegoExpressEngine destroyEngine];
    }
    [super viewDidDisappear:animated];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - Initialize Methods

- (void)initializeTopicConfigs {
    self.playViewMode = [ZGPlayTopicConfigManager sharedManager].playViewMode;
    self.enableHardwareDecode = [ZGPlayTopicConfigManager sharedManager].isEnableHardwareDecode;
    self.playStreamVolume = [ZGPlayTopicConfigManager sharedManager].playStreamVolume;
}

- (void)setupUI {
    self.navigationItem.title = @"Play Stream";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Setting" style:UIBarButtonItemStylePlain target:self action:@selector(goConfigPage:)];
    
    self.processTipTextView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.processTipTextView.textColor = [UIColor whiteColor];
    
    self.playLiveQualityLabel.text = @"";
    self.playLiveQualityLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.playLiveQualityLabel.textColor = [UIColor whiteColor];
    
    self.playLiveResolutionLabel.text = @"";
    self.playLiveResolutionLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.playLiveResolutionLabel.textColor = [UIColor whiteColor];
    
    self.playStreamExtraInfoLabel.text = @"";
    self.playStreamExtraInfoLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    self.playStreamExtraInfoLabel.textColor = [UIColor whiteColor];

    self.stopPlayLiveButn.alpha = 0;
    self.startPlayLiveConfigView.alpha = 1;

    self.roomID = [self savedValueForKey:ZGPlayTopicPlayStreamVCKey_roomID];
    self.roomIDTextField.text = self.roomID;
    self.roomIDTextField.delegate = self;
    
    self.streamID = [self savedValueForKey:ZGPlayTopicPlayStreamVCKey_streamID];
    self.streamIDTextField.text = self.streamID;
    self.streamIDTextField.delegate = self;
}

- (void)goConfigPage:(id)sender {
    ZGPlayTopicSettingVC *vc = [ZGPlayTopicSettingVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)createEngine {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];
    
    [self appendProcessTipAndMakeVisible:@" 🚀 Create ZegoExpressEngine"];
    ZGLogInfo(@" 🚀 Create ZegoExpressEngine");
    
    self.engine = [ZegoExpressEngine createEngineWithAppID:(unsigned int)appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];

    // Set debug verbose on
//    [self.engine setDebugVerbose:YES language:ZegoLanguageEnglish];
    
    // Set hardware decoder before playing stream
    [self.engine enableHardwareDecoder:self.enableHardwareDecode];
}

#pragma mark - Actions

- (IBAction)startPlayLiveButnClick:(id)sender {
    [self startPlayLive];
}

- (IBAction)stopStopLiveButnClick:(id)sender {
    [self stopPlayLive];
}

- (void)startPlayLive {
    [self appendProcessTipAndMakeVisible:@" 🚪 Start login room"];
    ZGLogInfo(@" 🚪 Start login room");
    
    self.roomID = self.roomIDTextField.text;
    self.streamID = self.streamIDTextField.text;
    
    [self saveValue:self.roomID forKey:ZGPlayTopicPlayStreamVCKey_roomID];
    [self saveValue:self.streamID forKey:ZGPlayTopicPlayStreamVCKey_streamID];
    
    // This demonstrates simply using the timestamp as the userID. In actual use, you can set the business-related userID as needed.
    NSString *userID = ZGUserIDHelper.userID;
    NSString *userName = ZGUserIDHelper.userName;
    
    ZegoRoomConfig *config = [ZegoRoomConfig defaultConfig];
    
    // Start login room
    [self.engine loginRoom:self.roomID user:[ZegoUser userWithUserID:userID userName:userName] config:config];
    
    [self appendProcessTipAndMakeVisible:@" 📥 Strat playing stream"];
    ZGLogInfo(@" 📥 Strat playing stream");
    
    // Strat playing stream
    ZegoCanvas *playCanvas = [ZegoCanvas canvasWithView:self.playLiveView];
    playCanvas.viewMode = self.playViewMode;
    [self.engine startPlayingStream:self.streamID canvas:playCanvas];
    
    // Volume needs to be set after playing stream
    [self.engine setPlayVolume:self.playStreamVolume stream:self.streamID];
    
}

- (void)stopPlayLive {
    // Stop playing stream
    [self.engine stopPlayingStream:self.streamID];
    [self appendProcessTipAndMakeVisible:@" 📥 Stop playing stream"];
    ZGLogInfo(@" 📥 Stop playing stream");
    // Logout room
    [self.engine logoutRoom:self.roomID];
    [self appendProcessTipAndMakeVisible:@" 🚪 Logout room"];
    ZGLogInfo(@" 🚪 Logout room");
    
    self.playLiveQualityLabel.text = @"";
}


- (void)invalidatePlayLiveStateUILayout {
    if (self.roomState == ZegoRoomStateConnected && self.playerState == ZegoPlayerStatePlaying) {
        [self showPlayLiveStartedStateUI];
    } else if (self.roomState == ZegoRoomStateDisconnected && self.playerState == ZegoPlayerStateNoPlay) {
        [self showPlayLiveStoppedStateUI];
    } else {
        [self showPlayLiveRequestingStateUI];
    }
}

- (void)showPlayLiveRequestingStateUI {
    [self.startPlayLiveButn setEnabled:NO];
    [self.stopPlayLiveButn setEnabled:NO];
}

- (void)showPlayLiveStartedStateUI {
    [self.startPlayLiveButn setEnabled:NO];
    [self.stopPlayLiveButn setEnabled:YES];
    [UIView animateWithDuration:0.5 animations:^{
        self.startPlayLiveConfigView.alpha = 0;
        self.stopPlayLiveButn.alpha = 1;
    }];
}

- (void)showPlayLiveStoppedStateUI {
    [self.startPlayLiveButn setEnabled:YES];
    [self.stopPlayLiveButn setEnabled:NO];
    [UIView animateWithDuration:0.5 animations:^{
        self.startPlayLiveConfigView.alpha = 1;
        self.stopPlayLiveButn.alpha = 0;
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
        [self startPlayLive];
    }
    
    return YES;
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
        }
    }
    self.roomState = state;
    [self invalidatePlayLiveStateUILayout];
}

- (void)onRoomStreamUpdate:(ZegoUpdateType)updateType streamList:(NSArray<ZegoStream *> *)streamList room:(NSString *)roomID {
    for (ZegoStream *stream in streamList) {
        if ([stream.streamID isEqualToString:self.streamID]) {
            self.playStreamExtraInfoLabel.text = [NSString stringWithFormat:@"Stream Extra Info: %@  ", stream.extraInfo];
            ZGLogInfo(@" 🚩 💬 Stream Extra Info First Recv: %@, StreamID: %@", stream.extraInfo, stream.streamID);
        }
    }
}

- (void)onRoomStreamExtraInfoUpdate:(NSArray<ZegoStream *> *)streamList room:(NSString *)roomID {
    NSLog(@"extra info update");
    for (ZegoStream *stream in streamList) {
        if ([stream.streamID isEqualToString:self.streamID]) {
            self.playStreamExtraInfoLabel.text = [NSString stringWithFormat:@"Stream Extra Info: %@  ", stream.extraInfo];
            ZGLogInfo(@" 🚩 💬 Stream Extra Info Update: %@, StreamID: %@", stream.extraInfo, stream.streamID);
        }
    }
}


#pragma mark - ZegoExpress EventHandler Player Event

- (void)onPlayerStateUpdate:(ZegoPlayerState)state errorCode:(int)errorCode stream:(NSString *)streamID {
    if (errorCode != 0) {
        [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@" 🚩 ❌ 📥 Playing stream error of streamID: %@, errorCode:%d", streamID, errorCode]];
        ZGLogWarn(@" 🚩 ❌ 📥 Playing stream error of streamID: %@, errorCode:%d", streamID, errorCode);
    } else {
        if (state == ZegoPlayerStatePlaying) {
            [self appendProcessTipAndMakeVisible:@" 🚩 📥 Playing stream"];
            ZGLogInfo(@" 🚩 📥 Playing stream");
        } else if (state == ZegoPlayerStatePlayRequesting) {
            [self appendProcessTipAndMakeVisible:@" 🚩 📥 Requesting play stream"];
            ZGLogInfo(@" 🚩 📥 Requesting play stream");
        } else if (state == ZegoPlayerStateNoPlay) {
            [self appendProcessTipAndMakeVisible:@" 🚩 📥 Stop playing stream"];
            ZGLogInfo(@" 🚩 📥 Stop playing stream");
        }
    }
    self.playerState = state;
    [self invalidatePlayLiveStateUILayout];
}

- (void)onPlayerQualityUpdate:(ZegoPlayStreamQuality *)quality stream:(NSString *)streamID {
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
    [text appendFormat:@"FPS: %d fps\n", (int)quality.videoRecvFPS];
    [text appendFormat:@"Bitrate: %.2f kb/s \n", quality.videoKBPS];
    [text appendFormat:@"HardwareDecode: %@ \n", quality.isHardwareDecode ? @"✅" : @"❎"];
    [text appendFormat:@"NetworkQuality: %@", networkQuality];
    self.playLiveQualityLabel.text = [text copy];
}

- (void)onPlayerVideoSizeChanged:(CGSize)size stream:(NSString *)streamID {
    self.playLiveResolutionLabel.text = [NSString stringWithFormat:@"Resolution: %.fx%.f  ", size.width, size.height];
}

- (void)onDebugError:(int)errorCode funcName:(NSString *)funcName info:(NSString *)info {
    ZGLogInfo(@" 🚩 Debug Error Callback: errorCode: %d, funcName: %@, info: %@", errorCode, funcName, info);
}

#pragma mark - ZGPlayTopicConfigChangedHandler

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager playViewModeDidChange:(ZegoViewMode)playViewMode {
    self.playViewMode = playViewMode;
    
    ZegoCanvas *playCanvas = [ZegoCanvas canvasWithView:self.playLiveView];
    playCanvas.viewMode = self.playViewMode;
    [self.engine startPlayingStream:self.streamID canvas:playCanvas];
}

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager playStreamVolumeDidChange:(int)playStreamVolume {
    self.playStreamVolume = playStreamVolume;
    
    [self.engine setPlayVolume:playStreamVolume stream:self.streamID];
}

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager enableHardwareDecodeDidChange:(BOOL)enableHardwareDecode {
    self.enableHardwareDecode = enableHardwareDecode;
    [self.engine enableHardwareDecoder:enableHardwareDecode];
    ZGLogInfo(@" ❕ Tips: The hardware decoding needs to be set before playing stream. If it is set in playing stream, it needs to be play again to take effect.");
}

@end

#endif
