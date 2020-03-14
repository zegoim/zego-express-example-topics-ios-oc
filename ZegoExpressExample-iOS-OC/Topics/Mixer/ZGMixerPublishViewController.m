//
//  ZGMixerPublishViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2019/11/21.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Mixer

#import "ZGMixerPublishViewController.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGUserIDHelper.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

NSString* const ZGMixerTopicKey_PublishStreamID = @"kPublishStreamID";

@interface ZGMixerPublishViewController () <ZegoEventHandler>

@property (nonatomic, copy) NSString *roomID;
@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *startPublishingButton;
@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;

@end

@implementation ZGMixerPublishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Publisher";
    self.roomID = @"MixerRoom-1";
    self.roomIDLabel.text = [NSString stringWithFormat:@"RoomID: %@", self.roomID];
    self.streamIDTextField.text = [self savedValueForKey:ZGMixerTopicKey_PublishStreamID];
    self.tipsLabel.hidden = YES;
    
    [self startPreview];
}

- (void)startPreview {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];
    
    ZGLogInfo(@" 🚀 Create ZegoExpressEngine");
    [ZegoExpressEngine createEngineWithAppID:appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];
    
    ZegoUser *user = [ZegoUser userWithUserID:[ZGUserIDHelper userID] userName:[ZGUserIDHelper userName]];
    
    ZGLogInfo(@" 🚪 Login room. roomID: %@", self.roomID);
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomID user:user config:[ZegoRoomConfig defaultConfig]];
    
    ZGLogInfo(@" 🔌 Start preview");
    [[ZegoExpressEngine sharedEngine] startPreview:[ZegoCanvas canvasWithView:self.previewView]];
}

- (IBAction)startPublishing {
    if (self.streamIDTextField.text.length > 0) {
        [self saveValue:self.streamIDTextField.text forKey:ZGMixerTopicKey_PublishStreamID];
        ZGLogInfo(@" 📤 Start publishing stream. streamID: %@", self.streamIDTextField.text);
        [[ZegoExpressEngine sharedEngine] startPublishing:self.streamIDTextField.text];
    } else {
        ZGLogWarn(@" ❕ Please enter stream ID");
        [ZegoHudManager showMessage:@" ❕ Please enter stream ID"];
    }
}


#pragma mark - ZegoEventHandler

- (void)onPublisherStateUpdate:(ZegoPublisherState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData streamID:(NSString *)streamID {
    if (state == ZegoPublisherStatePublishing) {
        self.title = @"🔵 Publishing";
        [self.startPublishingButton setTitle:@"🎉 Start Publishing Success" forState:UIControlStateNormal];
        self.tipsLabel.hidden = NO;
    }
}


#pragma mark - Exit

- (void)dealloc {
    ZGLogInfo(@" 🚪 Exit the room");
    [[ZegoExpressEngine sharedEngine] logoutRoom:self.roomID];
    
    // Can destroy the engine when you don't need audio and video calls
    ZGLogInfo(@" 🏳️ Destroy ZegoExpressEngine");
    [ZegoExpressEngine destroyEngine:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end

#endif
