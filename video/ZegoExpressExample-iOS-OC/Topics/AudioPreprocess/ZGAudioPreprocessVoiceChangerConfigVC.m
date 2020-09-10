//
//  ZGAudioPreprocessVoiceChangerConfigVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioPreprocess

#import "ZGAudioPreprocessVoiceChangerConfigVC.h"
#import "ZGAudioPreprocessTopicConfigManager.h"
#import "ZGAudioPreprocessTopicHelper.h"

@interface ZGAudioPreprocessVoiceChangerConfigVC () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UISwitch *openVoiceChangerSwitch;
@property (weak, nonatomic) IBOutlet UIView *voiceChargerConfigContainerView;
@property (weak, nonatomic) IBOutlet UIPickerView *modePicker;
@property (weak, nonatomic) IBOutlet UILabel *customModeValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customModeValueSlider;

@property (nonatomic, copy) NSArray<ZGAudioPreprocessTopicConfigMode*> *voiceChangerOptionModes;

@end

@implementation ZGAudioPreprocessVoiceChangerConfigVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AudioPreprocess" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAudioPreprocessVoiceChangerConfigVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.voiceChangerOptionModes = [ZGAudioPreprocessTopicHelper voiceChangerOptionModes];
    
    self.navigationItem.title = @"Set Voice Changer";
    
    BOOL voiceChangerOpen = [ZGAudioPreprocessTopicConfigManager sharedInstance].voiceChangerOpen;
    self.voiceChargerConfigContainerView.hidden = !voiceChangerOpen;
    self.openVoiceChangerSwitch.on = voiceChangerOpen;
    self.modePicker.dataSource = self;
    self.modePicker.delegate = self;
    
    float voiceChangerParam = [ZGAudioPreprocessTopicConfigManager sharedInstance].voiceChangerParam;
    self.customModeValueSlider.minimumValue = -8.f;
    self.customModeValueSlider.maximumValue = 8.f;
    self.customModeValueSlider.value = voiceChangerParam;
    self.customModeValueLabel.text = @(voiceChangerParam).stringValue;
    
    [self.modePicker reloadAllComponents];
    [self invalidateModePickerSelection];
}

- (IBAction)voiceChangerOpenValueChanged:(UISwitch *)sender {
    BOOL voiceChangerOpen = sender.isOn;
    [[ZGAudioPreprocessTopicConfigManager sharedInstance] setVoiceChangerOpen:voiceChangerOpen];
    self.voiceChargerConfigContainerView.hidden = !voiceChangerOpen;
}

- (IBAction)customModeValueChanged:(UISlider*)sender {
    float voiceChangerParam = sender.value;
    [[ZGAudioPreprocessTopicConfigManager sharedInstance] setVoiceChangerParam:voiceChangerParam];
    self.customModeValueLabel.text = @(voiceChangerParam).stringValue;
    [self invalidateModePickerSelection];
}

- (void)invalidateModePickerSelection {
    float voiceChangerParam = [ZGAudioPreprocessTopicConfigManager sharedInstance].voiceChangerParam;
    NSInteger selectionRow = NSNotFound;
    for (NSInteger i=0; i<self.voiceChangerOptionModes.count; i++) {
        ZGAudioPreprocessTopicConfigMode *mode = self.voiceChangerOptionModes[i];
        if (!mode.isCustom && mode.modeValue.floatValue == voiceChangerParam) {
            selectionRow = i;
        }
    }
    if (selectionRow != NSNotFound) {
        [self.modePicker selectRow:selectionRow inComponent:0 animated:NO];
    } else {
        // 选中到‘自定义’行
        ZGAudioPreprocessTopicConfigMode *customMode = [self customModeInModeList];
        NSInteger customModeIdx = [self.voiceChangerOptionModes indexOfObject:customMode];
        if (customModeIdx != NSNotFound) {
            [self.modePicker selectRow:customModeIdx inComponent:0 animated:NO];
        }
    }
}

- (ZGAudioPreprocessTopicConfigMode*)customModeInModeList {
    ZGAudioPreprocessTopicConfigMode *tarMode =nil;
    for (ZGAudioPreprocessTopicConfigMode *m in self.voiceChangerOptionModes) {
        if (m.isCustom) {
            tarMode = m;
            break;
        }
    }
    return tarMode;
}

#pragma mark - picker view dataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.voiceChangerOptionModes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.voiceChangerOptionModes[row].modeName;
}

#pragma mark - picker view delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([ZGAudioPreprocessTopicConfigManager sharedInstance].voiceChangerOpen) {
        ZGAudioPreprocessTopicConfigMode *mode = self.voiceChangerOptionModes[row];
        if (!mode.isCustom) {
            [[ZGAudioPreprocessTopicConfigManager sharedInstance] setVoiceChangerParam:mode.modeValue.floatValue];
        }
    }
}

@end
#endif
