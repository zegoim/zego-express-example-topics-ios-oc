//
//  ZGAudioPreprocessVirtualStereoConfigVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioPreprocess

#import "ZGAudioPreprocessVirtualStereoConfigVC.h"
#import "ZGAudioPreprocessTopicConfigManager.h"
#import "ZGAudioPreprocessTopicHelper.h"

@interface ZGAudioPreprocessVirtualStereoConfigVC ()

@property (weak, nonatomic) IBOutlet UISwitch *openVirtaulStereoSwitch;
@property (weak, nonatomic) IBOutlet UIView *virtaulStereoConfigContainerView;
@property (weak, nonatomic) IBOutlet UILabel *angleValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *angleValueSlider;

@end

@implementation ZGAudioPreprocessVirtualStereoConfigVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AudioPreprocess" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAudioPreprocessVirtualStereoConfigVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Set Virtual Stereo";
    
    BOOL virtualStereoOpen = [ZGAudioPreprocessTopicConfigManager sharedInstance].virtualStereoOpen;
    
    self.virtaulStereoConfigContainerView.hidden = !virtualStereoOpen;
    self.openVirtaulStereoSwitch.on = virtualStereoOpen;
    
    float virtualStereoAngle = [ZGAudioPreprocessTopicConfigManager sharedInstance].virtualStereoAngle;
    self.angleValueSlider.minimumValue = 0;
    self.angleValueSlider.maximumValue = 180;
    self.angleValueSlider.value = virtualStereoAngle;
    self.angleValueLabel.text = @(virtualStereoAngle).stringValue;
}

- (IBAction)openVirtaulStereoValueChanged:(UISwitch*)sender {
    float virtualStereoOpen = sender.isOn;
    [[ZGAudioPreprocessTopicConfigManager sharedInstance] setVirtualStereoOpen:virtualStereoOpen];
    self.virtaulStereoConfigContainerView.hidden = !virtualStereoOpen;
}

- (IBAction)angleValueChanged:(UISlider*)sender {
    float virtualStereoAngle = sender.value;
    [[ZGAudioPreprocessTopicConfigManager sharedInstance] setVirtualStereoAngle:virtualStereoAngle];
    self.angleValueLabel.text = @(virtualStereoAngle).stringValue;
}

@end
#endif
