//
//  ZGAudioPreprocessConfigTableViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/10/1.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_AudioPreprocess

#import "ZGAudioPreprocessConfigTableViewController.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

@interface ZGAudioPreprocessConfigTableViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

// Voice Changer
@property (nonatomic, copy) NSArray<NSString *> *voiceChangerPresetList;
@property (weak, nonatomic) IBOutlet UIPickerView *voiceChangerPresetPicker;
@property (weak, nonatomic) IBOutlet UISwitch *voiceChangerEnableCustomSwitch;
@property (weak, nonatomic) IBOutlet UILabel *voiceChangerPitchLabel;
@property (weak, nonatomic) IBOutlet UISlider *voiceChangerPitchSlider;


// Reverb
@property (nonatomic, copy) NSArray<NSString *> *reverbPresetList;
@property (nonatomic, strong) ZegoReverbParam *reverbParam;
@property (weak, nonatomic) IBOutlet UIPickerView *reverbPresetPicker;
@property (weak, nonatomic) IBOutlet UISwitch *reverbEnableCustomSwitch;

@property (weak, nonatomic) IBOutlet UILabel *reverbRoomSizeLabel;
@property (weak, nonatomic) IBOutlet UISlider *reverbRoomSizeSlider;
@property (weak, nonatomic) IBOutlet UILabel *reverbReverberanceLabel;
@property (weak, nonatomic) IBOutlet UISlider *reverbReverberanceSlider;
@property (weak, nonatomic) IBOutlet UILabel *reverbDampingLabel;
@property (weak, nonatomic) IBOutlet UISlider *reverbDampingSlider;
@property (weak, nonatomic) IBOutlet UILabel *reverbDryWetRatioLabel;
@property (weak, nonatomic) IBOutlet UISlider *reverbDryWetRatioSlider;


// Reverb Echo
@property (nonatomic, copy) NSDictionary<NSString *, ZegoReverbEchoParam *> *reverbEchoCustomParams;
@property (weak, nonatomic) IBOutlet UIPickerView *reverbEchoCustomParamsPicker;


// Virtual Stereo
@property (weak, nonatomic) IBOutlet UISwitch *virtualStereoEnableSwitch;
@property (weak, nonatomic) IBOutlet UILabel *virtualStereoAngleLabel;
@property (weak, nonatomic) IBOutlet UISlider *virtualStereoAngleSlider;


@end

@implementation ZGAudioPreprocessConfigTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.voiceChangerPresetList = @[@"None", @"MenToChild", @"MenToWomen", @"WomenToChild", @"WomenToMen", @"Foreigner", @"OptimusPrime", @"Android", @"Ethereal"];
    self.voiceChangerPresetPicker.dataSource = self;
    self.voiceChangerPresetPicker.delegate = self;

    self.reverbPresetList = @[@"None", @"SoftRoom", @"LargeRoom", @"ConcerHall", @"Valley"];
    self.reverbPresetPicker.dataSource = self;
    self.reverbPresetPicker.delegate = self;
    self.reverbParam = [[ZegoReverbParam alloc] init];

    self.reverbEchoCustomParamsPicker.dataSource = self;
    self.reverbEchoCustomParamsPicker.delegate = self;

    [self setupUI];
}

- (void)setupUI {
    self.title = @"AudioPreprocess";

    self.voiceChangerEnableCustomSwitch.on = NO;
    self.voiceChangerPitchSlider.enabled = NO;
    self.voiceChangerPitchLabel.text = @"Pitch";

    self.reverbEnableCustomSwitch.on = NO;
    self.reverbRoomSizeSlider.enabled = NO;
    self.reverbReverberanceSlider.enabled = NO;
    self.reverbDampingSlider.enabled = NO;
    self.reverbDryWetRatioSlider.enabled = NO;
    self.reverbRoomSizeLabel.text = @"RoomSize";
    self.reverbReverberanceLabel.text = @"Reverberance";
    self.reverbDampingLabel.text = @"Damping";
    self.reverbDryWetRatioLabel.text = @"DryWetRatio";

    self.virtualStereoAngleSlider.enabled = NO;
    self.virtualStereoAngleLabel.text = @"Angle";
}

- (void)resetAllEffect {
    self.voiceChangerEnableCustomSwitch.on = NO;
    [self voiceChangerCustomSwitchValueChanged:self.voiceChangerEnableCustomSwitch];

    self.reverbEnableCustomSwitch.on = NO;
    [self reverbCustomSwitchValueChanged:self.reverbEnableCustomSwitch];

    [self.reverbEchoCustomParamsPicker selectRow:0 inComponent:0 animated:YES];
    [self pickerView:self.reverbEchoCustomParamsPicker didSelectRow:0 inComponent:0];

    self.virtualStereoEnableSwitch.on = NO;
    [self virtualStereoSwitchValueChanged:self.virtualStereoEnableSwitch];
}

#pragma mark - Voice Changer

// Triggered by voice changer picker view
- (void)voiceChangerPresetDidChanged:(ZegoVoiceChangerPreset)preset {
    ZGLogInfo(@"🗣 Set voice changer preset: %d", (int)preset);
    [[ZegoExpressEngine sharedEngine] setVoiceChangerPreset:preset];
}

- (IBAction)voiceChangerCustomSwitchValueChanged:(UISwitch *)sender {
    self.voiceChangerPresetPicker.userInteractionEnabled = !sender.on;
    self.voiceChangerPresetPicker.alpha = sender.on ? 0.5 : 1.0;

    self.voiceChangerPitchSlider.enabled = sender.on;
    self.voiceChangerPitchSlider.value = 0.0;

    [self.voiceChangerPresetPicker selectRow:0 inComponent:0 animated:YES];
    [self pickerView:self.voiceChangerPresetPicker didSelectRow:0 inComponent:0];

    self.voiceChangerPitchLabel.text = sender.on ? @"Pitch: 0.00" : @"Pitch";
}

- (IBAction)voiceChangerPitchSliderValueChanged:(UISlider *)sender {
    self.voiceChangerPitchLabel.text = [NSString stringWithFormat:@"Pitch: %.2f", sender.value];
}

- (IBAction)voiceChangerPitchSliderTouchUp:(UISlider *)sender {
    ZGLogInfo(@"🗣 Set voice changer pitch: %.2f", sender.value);
    ZegoVoiceChangerParam *param = [[ZegoVoiceChangerParam alloc] init];
    param.pitch = sender.value;
    [[ZegoExpressEngine sharedEngine] setVoiceChangerParam:param];
}

#pragma mark - Reverb

// Triggered by reverb picker view
- (void)reverbPresetDidChanged:(ZegoReverbPreset)preset {
    ZGLogInfo(@"🎼 Set reverb preset: %d", (int)preset);
    [[ZegoExpressEngine sharedEngine] setReverbPreset:preset];
}

- (IBAction)reverbCustomSwitchValueChanged:(UISwitch *)sender {
    self.reverbPresetPicker.userInteractionEnabled = !sender.on;
    self.reverbPresetPicker.alpha = sender.on ? 0.5 : 1.0;

    self.reverbRoomSizeSlider.enabled = sender.on;
    self.reverbReverberanceSlider.enabled = sender.on;
    self.reverbDampingSlider.enabled = sender.on;
    self.reverbDryWetRatioSlider.enabled = sender.on;

    self.reverbRoomSizeSlider.value = 0.0;
    self.reverbReverberanceSlider.value = 0.0;
    self.reverbDampingSlider.value = 0.0;
    self.reverbDryWetRatioSlider.value = 0.0;

    [self clearReverbParam];

    [self.reverbPresetPicker selectRow:0 inComponent:0 animated:YES];
    [self pickerView:self.reverbPresetPicker didSelectRow:0 inComponent:0];

    self.reverbRoomSizeLabel.text = sender.on ? @"RoomSize: 0.00" : @"RoomSize";
    self.reverbReverberanceLabel.text = sender.on ? @"Reverberance: 0.00" : @"Reverberance";
    self.reverbDampingLabel.text = sender.on ? @"Damping: 0.00" : @"Damping";
    self.reverbDryWetRatioLabel.text = sender.on ? @"DryWetRatio: 0.00" : @"DryWetRatio";
}

- (IBAction)reverbParamsSliderValueChanged:(UISlider *)sender {
    if (sender == self.reverbRoomSizeSlider) {
        self.reverbRoomSizeLabel.text = [NSString stringWithFormat:@"RoomSize: %.2f", sender.value];

    } else if (sender == self.reverbReverberanceSlider) {
        self.reverbReverberanceLabel.text = [NSString stringWithFormat:@"Reverberance: %.2f", sender.value];

    } else if (sender == self.reverbDampingSlider) {
        self.reverbDampingLabel.text = [NSString stringWithFormat:@"Damping: %.2f", sender.value];

    } else if (sender == self.reverbDryWetRatioSlider) {
        self.reverbDryWetRatioLabel.text = [NSString stringWithFormat:@"DryWetRatio: %.2f", sender.value];
    }
}

- (IBAction)reverbParamsSliderTouchUp:(UISlider *)sender {
    if (sender == self.reverbRoomSizeSlider) {
        ZGLogInfo(@"🎼 Update reverb param room size: %.2f", sender.value);
        self.reverbParam.roomSize = sender.value;

    } else if (sender == self.reverbReverberanceSlider) {
        ZGLogInfo(@"🎼 Update reverb param reverberance: %.2f", sender.value);
        self.reverbParam.reverberance = sender.value;

    } else if (sender == self.reverbDampingSlider) {
        ZGLogInfo(@"🎼 Update reverb param damping: %.2f", sender.value);
        self.reverbParam.damping = sender.value;

    } else if (sender == self.reverbDryWetRatioSlider) {
        ZGLogInfo(@"🎼 Update reverb param dry wet ratio: %.2f", sender.value);
        self.reverbParam.dryWetRatio = sender.value;
    }

    [self updateReverbParam];
}

- (void)updateReverbParam {
    ZGLogInfo(@"🎼 Set reverb param");
    [[ZegoExpressEngine sharedEngine] setReverbParam:self.reverbParam];
}

- (void)clearReverbParam {
    self.reverbParam.roomSize = 0.0;
    self.reverbParam.reverberance = 0.0;
    self.reverbParam.damping = 0.0;
    self.reverbParam.dryWetRatio = 0.0;
}


#pragma mark - Reverb Echo

// Triggered by reverb picker view
- (void)reverbEchoCustomParamsDidChanged:(NSInteger)index {
    NSString *paramName = [self.reverbEchoCustomParams.allKeys sortedArrayUsingSelector:@selector(compare:)][index];
    ZGLogInfo(@"🌬 Set reverb echo param: %@", paramName);
    ZegoReverbEchoParam *echoParam = self.reverbEchoCustomParams[paramName];
    [[ZegoExpressEngine sharedEngine] setReverbEchoParam:echoParam];
}

- (NSDictionary<NSString *, ZegoReverbEchoParam *> *)reverbEchoCustomParams {
    if (!_reverbEchoCustomParams) {

        // No echo
        ZegoReverbEchoParam *echoParamNone = [[ZegoReverbEchoParam alloc] init];
        echoParamNone.inGain = 1.0;
        echoParamNone.outGain = 1.0;
        echoParamNone.numDelays = 0;
        echoParamNone.delay = @[@0, @0, @0, @0, @0, @0, @0];
        echoParamNone.decay = @[@0.0f, @0.0f, @0.0f, @0.0f, @0.0f, @0.0f, @0.0f];

        // Ethereal
        ZegoReverbEchoParam *echoParamEthereal = [[ZegoReverbEchoParam alloc] init];
        echoParamEthereal.inGain = 0.8;
        echoParamEthereal.outGain = 1.0;
        echoParamEthereal.numDelays = 7;
        echoParamEthereal.delay = @[@230, @460, @690, @920, @1150, @1380, @1610];
        echoParamEthereal.decay = @[@0.41f, @0.18f, @0.08f, @0.03f, @0.009f, @0.003f, @0.001f];

        // Robot
        ZegoReverbEchoParam *echoParamRobot = [[ZegoReverbEchoParam alloc] init];
        echoParamRobot.inGain = 0.8;
        echoParamRobot.outGain = 1.0;
        echoParamRobot.numDelays = 7;
        echoParamRobot.delay = @[@60, @120, @180, @240, @300, @360, @420];
        echoParamRobot.decay = @[@0.51f, @0.26f, @0.12f, @0.05f, @0.02f, @0.009f, @0.001f];

        // Customize your own echo parameters
        ZegoReverbEchoParam *echoParamCustom = [[ZegoReverbEchoParam alloc] init];
        echoParamCustom.inGain = 1.0;
        echoParamCustom.outGain = 1.0;
        echoParamCustom.numDelays = 3;
        echoParamCustom.delay = @[@300, @600, @900, @0, @0, @0, @0];
        echoParamCustom.decay = @[@0.3f, @0.2f, @0.1f, @0.0f, @0.0f, @0.0f, @0.0f];

        _reverbEchoCustomParams = @{
            @"0.None": echoParamNone,
            @"1.Ethereal": echoParamEthereal,
            @"2.Robot": echoParamRobot,
            @"3.Custom": echoParamCustom
        };
    }
    return _reverbEchoCustomParams;
}

#pragma mark - Virtual Stereo

- (IBAction)virtualStereoSwitchValueChanged:(UISwitch *)sender {
    self.virtualStereoAngleSlider.enabled = sender.on;
    self.virtualStereoAngleSlider.value = 90.0;

    self.virtualStereoAngleLabel.text = sender.on ? @"Angle: 90°" : @"Angle";

    [self virtualStereoParamsDidChanged];
}

- (IBAction)virtualStereoSliderValueChanged:(UISlider *)sender {
    self.virtualStereoAngleLabel.text = [NSString stringWithFormat:@"Angle: %d°", (int)sender.value];
}

- (IBAction)virtualStereoSliderTouchUp:(UISlider *)sender {
    [self virtualStereoParamsDidChanged];
}

- (void)virtualStereoParamsDidChanged {
    BOOL enable = self.virtualStereoEnableSwitch.on;
    int angle = (int)self.virtualStereoAngleSlider.value;
    ZGLogInfo(@"🎶 Set virtual stereo, enable: %@, angle: %d", enable ? @"YES" : @"NO", angle);
    [[ZegoExpressEngine sharedEngine] enableVirtualStereo:enable angle:angle];
}

#pragma mark - UIPickerView delegate/datasource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView == self.voiceChangerPresetPicker) {
        return self.voiceChangerPresetList.count;
    } else if (pickerView == self.reverbPresetPicker) {
        return self.reverbPresetList.count;
    } else if (pickerView == self.reverbEchoCustomParamsPicker) {
        return self.reverbEchoCustomParams.count;
    } else {
        return 0;
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView == self.voiceChangerPresetPicker) {
        [self voiceChangerPresetDidChanged:(ZegoVoiceChangerPreset)row];
    } else if (pickerView == self.reverbPresetPicker) {
        [self reverbPresetDidChanged:(ZegoReverbPreset)row];
    } else if (pickerView == self.reverbEchoCustomParamsPicker) {
        [self reverbEchoCustomParamsDidChanged:(NSInteger)row];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView == self.voiceChangerPresetPicker) {
        return self.voiceChangerPresetList[row];
    } else if (pickerView == self.reverbPresetPicker) {
        return self.reverbPresetList[row];
    } else if (pickerView == self.reverbEchoCustomParamsPicker) {
        return [self.reverbEchoCustomParams.allKeys sortedArrayUsingSelector:@selector(compare:)][row];
    } else {
        return @"Unknown";
    }
}


@end

#endif
