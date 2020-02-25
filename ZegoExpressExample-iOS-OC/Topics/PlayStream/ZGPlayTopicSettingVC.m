//
//  ZGPlayTopicSettingVC.m
//  ZegoExpressExample-iOS-OC-iOS
//
//  Created by jeffreypeng on 2019/8/9.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Play

#import "ZGPlayTopicSettingVC.h"
#import "ZGPlayTopicConfigManager.h"

@interface ZGPlayTopicSettingVC ()

@property (weak, nonatomic) IBOutlet UILabel *playViewModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *hardwareDecodeSwitch;
@property (weak, nonatomic) IBOutlet UISlider *playVolumeSlider;
@property (weak, nonatomic) IBOutlet UILabel *playVolumeLabel;

@end

@implementation ZGPlayTopicSettingVC

static NSArray<NSNumber*> *ZGPlayTopicCommonVideoViewModeList;

+ (void)initialize {
    ZGPlayTopicCommonVideoViewModeList = @[@(ZegoViewModeAspectFit),
                                           @(ZegoViewModeAspectFill),
                                           @(ZegoViewModeScaleToFill)];
}

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PlayStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGPlayTopicSettingVC class])];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (IBAction)enableHardwareDecodeSwitchValueChanged:(id)sender {
    [[ZGPlayTopicConfigManager sharedManager] setEnableHardwareDecode:self.hardwareDecodeSwitch.isOn];
}

- (IBAction)playVolumeSwitchValueChanged:(id)sender {
    int volume = (int)self.playVolumeSlider.value;
    [[ZGPlayTopicConfigManager sharedManager] setPlayStreamVolume:volume];
    self.playVolumeLabel.text = @(volume).stringValue;
}

#pragma mark - private methods

+ (NSString *)displayTextForVideoViewMode:(ZegoViewMode)viewMode {
    switch (viewMode) {
        case ZegoViewModeAspectFit:
            return @"ScaleAspectFit 等比缩放";
            break;
        case ZegoViewModeAspectFill:
            return @"ScaleAspectFill 等比截取";
            break;
        case ZegoViewModeScaleToFill:
            return @"ScaleToFill 不等比填充";
            break;
    }
}

- (void)setupUI {
    self.navigationItem.title = @"Settings";
    self.playVolumeSlider.minimumValue = 0;
    self.playVolumeSlider.maximumValue = 100;
    
    [self invalidatePlayViewModeUI:[ZGPlayTopicConfigManager sharedManager].playViewMode];
    [self invalidateEnableHardwareDecodeUI:[ZGPlayTopicConfigManager sharedManager].isEnableHardwareDecode];
    [self invalidatePlayVolumeUI:[ZGPlayTopicConfigManager sharedManager].playStreamVolume];
}

- (void)invalidatePlayViewModeUI:(ZegoViewMode)viewMode {
    self.playViewModeLabel.text = [[self class] displayTextForVideoViewMode:viewMode];
}

- (void)invalidateEnableHardwareDecodeUI:(BOOL)enableHardwareDecode {
    self.hardwareDecodeSwitch.on = enableHardwareDecode;
}

- (void)invalidatePlayVolumeUI:(int)playVolume {
    self.playVolumeLabel.text = @(playVolume).stringValue;
    self.playVolumeSlider.value = playVolume;
}

- (void)showViewModePickSheet {
    NSArray<NSNumber*>* modeList = ZGPlayTopicCommonVideoViewModeList;
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Select Render View Mode" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *modeObj in modeList) {
        ZegoViewMode viewMode = (ZegoViewMode)[modeObj integerValue];
        [sheet addAction:[UIAlertAction actionWithTitle:[[self class] displayTextForVideoViewMode:viewMode] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ZGPlayTopicConfigManager sharedManager] setPlayViewMode:viewMode];
            [self invalidatePlayViewModeUI:viewMode];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height, 0, 0);
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self showViewModePickSheet];
        }
    }
}

@end

#endif
