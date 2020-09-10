//
//  ZGAudioPreprocessReverbConfigVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioPreprocess

#import "ZGAudioPreprocessReverbConfigVC.h"
#import "ZGAudioPreprocessTopicConfigManager.h"
#import "ZGAudioPreprocessTopicHelper.h"

@interface ZGAudioPreprocessReverbConfigVC () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UISwitch *openReverbSwitch;
@property (weak, nonatomic) IBOutlet UIView *reverbConfigContainerView;
@property (weak, nonatomic) IBOutlet UIPickerView *modePicker;
@property (weak, nonatomic) IBOutlet UILabel *customRoomSizeValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customRoomSizeSlider;
@property (weak, nonatomic) IBOutlet UILabel *customDryWetRatioValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customDryWetRatioSlider;
@property (weak, nonatomic) IBOutlet UILabel *customDampingValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customDampingSlider;
@property (weak, nonatomic) IBOutlet UILabel *customReverberanceValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customReverberanceSlider;

@property (nonatomic, copy) NSArray<ZGAudioPreprocessTopicConfigMode*> *reverbOptionModes;

@end

@implementation ZGAudioPreprocessReverbConfigVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AudioPreprocess" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAudioPreprocessReverbConfigVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.reverbOptionModes = [ZGAudioPreprocessTopicHelper reverbOptionModes];
    self.navigationItem.title = @"Set Reverberation";
    
    BOOL reverbOpen = [ZGAudioPreprocessTopicConfigManager sharedInstance].reverbOpen;
    
    self.reverbConfigContainerView.hidden = !reverbOpen;
    self.openReverbSwitch.on = reverbOpen;
    self.modePicker.delegate = self;
    self.modePicker.dataSource = self;
    
    float customReverbRoomSize = [ZGAudioPreprocessTopicConfigManager sharedInstance].customReverbRoomSize;
    self.customRoomSizeSlider.minimumValue = 0.0f;
    self.customRoomSizeSlider.maximumValue = 1.0f;
    self.customRoomSizeSlider.value = customReverbRoomSize;
    self.customRoomSizeValueLabel.text = @(customReverbRoomSize).stringValue;
    
    float customDryWetRatio = [ZGAudioPreprocessTopicConfigManager sharedInstance].customDryWetRatio;
    self.customDryWetRatioSlider.minimumValue = 0.0f;
    self.customDryWetRatioSlider.maximumValue = 2.0f;
    self.customDryWetRatioSlider.value = customDryWetRatio;
    self.customDryWetRatioValueLabel.text = @(customDryWetRatio).stringValue;
    
    float customDamping = [ZGAudioPreprocessTopicConfigManager sharedInstance].customDamping;
    self.customDampingSlider.minimumValue = 0.0f;
    self.customDampingSlider.maximumValue = 2.0f;
    self.customDampingSlider.value = customDamping;
    self.customDampingValueLabel.text = @(customDamping).stringValue;
    
    float customReverberance =[ZGAudioPreprocessTopicConfigManager sharedInstance].customReverberance;
    self.customReverberanceSlider.minimumValue = 0.0f;
    self.customReverberanceSlider.maximumValue = 0.5f;
    self.customReverberanceSlider.value = customReverberance;
    self.customReverberanceValueLabel.text = @(customReverberance).stringValue;
}

- (IBAction)reverbValueChanged:(UISwitch*)sender {
    BOOL reverbOpen = sender.isOn;
    [[ZGAudioPreprocessTopicConfigManager sharedInstance] setReverbOpen:reverbOpen];
    self.reverbConfigContainerView.hidden = !reverbOpen;
}

- (IBAction)customRoomSizeValueChanged:(UISlider*)sender {
    float customReverbRoomSize = sender.value;
    [[ZGAudioPreprocessTopicConfigManager sharedInstance] setCustomReverbRoomSize:customReverbRoomSize];
    self.customRoomSizeValueLabel.text = @(customReverbRoomSize).stringValue;
}

- (IBAction)customDryWetRationValueChanged:(UISlider*)sender {
    float customDryWetRatio = sender.value;
    [[ZGAudioPreprocessTopicConfigManager sharedInstance] setCustomDryWetRatio:customDryWetRatio];
    self.customDryWetRatioValueLabel.text = @(customDryWetRatio).stringValue;
}

- (IBAction)customDampingValueChanged:(UISlider*)sender {
    float customDamping = sender.value;
    [[ZGAudioPreprocessTopicConfigManager sharedInstance] setCustomDamping:customDamping];
    self.customDampingValueLabel.text = @(customDamping).stringValue;
}

- (IBAction)customReverberanceChanged:(UISlider*)sender {
    float customReverberance = sender.value;
    [[ZGAudioPreprocessTopicConfigManager sharedInstance] setCustomReverberance:customReverberance];
    self.customReverberanceValueLabel.text = @(customReverberance).stringValue;
}

#pragma mark - picker view dataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.reverbOptionModes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.reverbOptionModes[row].modeName;
}

#pragma mark - picker view delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([ZGAudioPreprocessTopicConfigManager sharedInstance].reverbOpen) {
        ZGAudioPreprocessTopicConfigMode *mode = self.reverbOptionModes[row];
        if (!mode.isCustom) {
            [[ZGAudioPreprocessTopicConfigManager sharedInstance] setReverbMode:[mode.modeValue unsignedIntegerValue]];
        } else {
            [[ZGAudioPreprocessTopicConfigManager sharedInstance] setReverbMode:NSNotFound];
        }
    }
}

@end
#endif
