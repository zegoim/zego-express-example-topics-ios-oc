//
//  ZGPublishTopicSettingVC.m
//  ZegoExpressExample-iOS-OC
//
//  Created by jeffreypeng on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import "ZGPublishTopicSettingVC.h"
#import "ZGPublishTopicConfigManager.h"

@interface ZGPublishTopicSettingVC ()

@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitrateLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewModeLabel;
@property (weak, nonatomic) IBOutlet UITextField *streamExtraInfoTextField;
@property (weak, nonatomic) IBOutlet UISwitch *hardwareEncodeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *mirrorLabel;

@end

@implementation ZGPublishTopicSettingVC

static NSArray<NSValue*> *ZGPublishTopicCommonResolutionList;
static NSArray<NSNumber*> *ZGPublishTopicCommonBitrateList;
static NSArray<NSNumber*> *ZGPublishTopicCommonFpsList;
static NSArray<NSNumber*> *ZGPublishTopicCommonVideoViewModeList;
static NSArray<NSNumber*> *ZGPublishTopicCommonMirrorModeList;

+ (void)initialize {
    ZGPublishTopicCommonResolutionList =
        @[@(CGSizeMake(1080, 1920)),
          @(CGSizeMake(720, 1280)),
          @(CGSizeMake(540, 960)),
          @(CGSizeMake(360, 640)),
          @(CGSizeMake(270, 480)),
          @(CGSizeMake(180, 320))];
    
    ZGPublishTopicCommonBitrateList =
        @[@(3000000),
          @(1500000),
          @(1200000),
          @(600000),
          @(400000),
          @(300000)];
    
    ZGPublishTopicCommonFpsList = @[@(10),@(15),@(20),@(25),@(30)];
    
    ZGPublishTopicCommonVideoViewModeList = @[@(ZegoViewModeAspectFit),
          @(ZegoViewModeAspectFill),
          @(ZegoViewModeScaleToFill)];
    
    ZGPublishTopicCommonMirrorModeList = @[@(ZegoVideoMirrorModeOnlyPreviewMirror), @(ZegoVideoMirrorModeBothMirror), @(ZegoVideoMirrorModeNoMirror), @(ZegoVideoMirrorModeOnlyPublishMirror)];
}

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PublishStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGPublishTopicSettingVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}


- (IBAction)setStreamExtraInfoButtonClick:(UIButton *)sender {
    [[ZGPublishTopicConfigManager sharedManager] setStreamExtraInfo:self.streamExtraInfoTextField.text];
}

- (IBAction)enableHardwareEncodeSwitchValueChanged:(id)sender {
    [[ZGPublishTopicConfigManager sharedManager] setEnableHardwareEncode:self.hardwareEncodeSwitch.isOn];
}


#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"Setting";
    
    [self invalidateResolutionUI:[ZGPublishTopicConfigManager sharedManager].resolution];
    [self invalidateFpsUI:[ZGPublishTopicConfigManager sharedManager].fps];
    [self invalidateBitrateUI:[ZGPublishTopicConfigManager sharedManager].bitrate];
    [self invalidatePreviewViewModeUI:[ZGPublishTopicConfigManager sharedManager].previewViewMode];
    [self invalidateStreamExtraInfoUI:[ZGPublishTopicConfigManager sharedManager].streamExtraInfo];
    [self invalidateEnableHardwareEncodeUI:[ZGPublishTopicConfigManager sharedManager].isEnableHardwareEncode];
    [self invalidateMirrorMode:[ZGPublishTopicConfigManager sharedManager].mirrorMode];
}

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

+ (NSString *)displayTextForMirrorMode:(ZegoVideoMirrorMode)mirrorMode {
    switch (mirrorMode) {
        case ZegoVideoMirrorModeOnlyPreviewMirror:
            return @"Only Preview Mirror";
            break;
        case ZegoVideoMirrorModeBothMirror:
            return @"Both Mirror";
            break;
        case ZegoVideoMirrorModeNoMirror:
            return @"No Mirror";
            break;
        case ZegoVideoMirrorModeOnlyPublishMirror:
            return @"Only Publish Mirror";
            break;
    }
}

+ (NSString *)displayTextForResolution:(CGSize)resolution {
    return [NSString stringWithFormat:@"%@ x %@", @(resolution.width), @(resolution.height)];
}

- (void)invalidateResolutionUI:(CGSize)resolution {
    self.resolutionLabel.text = [[self class] displayTextForResolution:resolution];
}

- (void)invalidateFpsUI:(NSInteger)fps {
    self.fpsLabel.text = @(fps).stringValue;
}

- (void)invalidateBitrateUI:(NSInteger)bitrate {
    self.bitrateLabel.text = @(bitrate).stringValue;
}

- (void)invalidatePreviewViewModeUI:(ZegoViewMode)viewMode {
    self.viewModeLabel.text = [[self class] displayTextForVideoViewMode:viewMode];
}

- (void)invalidateEnableHardwareEncodeUI:(BOOL)enableHardwareEncode {
    self.hardwareEncodeSwitch.on = enableHardwareEncode;
}

- (void)invalidateStreamExtraInfoUI:(NSString *)streamExtraInfo {
    self.streamExtraInfoTextField.text = streamExtraInfo;
}

- (void)invalidateMirrorMode:(ZegoVideoMirrorMode)mirrorMode {
    self.mirrorLabel.text = [[self class] displayTextForMirrorMode:mirrorMode];
}

- (void)showResolutionListPickSheet {
    NSArray<NSValue*>* resolutionList = ZGPublishTopicCommonResolutionList;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Select Video Resolution" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSValue *sizeObj in resolutionList) {
        CGSize size = [sizeObj CGSizeValue];
        NSString *title = [[self class] displayTextForResolution:size];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ZGPublishTopicConfigManager sharedManager] setResolution:size];
            [self invalidateResolutionUI:size];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height, 0, 0);
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showBitratePickSheet {
    NSArray<NSNumber*> *bitrateList = ZGPublishTopicCommonBitrateList;
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Select Video Bitrate" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *bitrateObj in bitrateList) {
        [sheet addAction:[UIAlertAction actionWithTitle:[bitrateObj stringValue] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSInteger bitrate = [bitrateObj integerValue];
            [[ZGPublishTopicConfigManager sharedManager] setBitrate:bitrate];
            [self invalidateBitrateUI:bitrate];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height, 0, 0);
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showFpsPickSheet {
    NSArray<NSNumber*>* fpsList = ZGPublishTopicCommonFpsList;
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Select Video FPS" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *fpsObj in fpsList) {
        [sheet addAction:[UIAlertAction actionWithTitle:[fpsObj stringValue] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSInteger fps = [fpsObj integerValue];
            [[ZGPublishTopicConfigManager sharedManager] setFps:fps];
            [self invalidateFpsUI:fps];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height, 0, 0);
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showViewModePickSheet {
    NSArray<NSNumber*>* modeList = ZGPublishTopicCommonVideoViewModeList;
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Select Render View Mode" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *modeObj in modeList) {
        ZegoViewMode viewMode = (ZegoViewMode)[modeObj integerValue];
        [sheet addAction:[UIAlertAction actionWithTitle:[[self class] displayTextForVideoViewMode:viewMode] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ZGPublishTopicConfigManager sharedManager] setPreviewViewMode:viewMode];
            [self invalidatePreviewViewModeUI:viewMode];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height, 0, 0);
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showMirrorModePickSheet {
    NSArray<NSNumber*>* modeList = ZGPublishTopicCommonMirrorModeList;
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Select Video Mirror Mode" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *modeObj in modeList) {
        ZegoVideoMirrorMode mirrorMode = (ZegoVideoMirrorMode)[modeObj integerValue];
        [sheet addAction:[UIAlertAction actionWithTitle:[[self class] displayTextForMirrorMode:(ZegoVideoMirrorMode)mirrorMode] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ZGPublishTopicConfigManager sharedManager] setMirrorMode:(ZegoVideoMirrorMode)mirrorMode];
            [self invalidateMirrorMode:(ZegoVideoMirrorMode)mirrorMode];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height, 0, 0);
    [self presentViewController:sheet animated:YES completion:nil];
}


#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self showResolutionListPickSheet];
        }
        else if (indexPath.row == 1) {
            [self showFpsPickSheet];
        }
        else if (indexPath.row == 2) {
            [self showBitratePickSheet];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self showViewModePickSheet];
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 1) {
            [self showMirrorModePickSheet];
        }
    }
}

@end

#endif
