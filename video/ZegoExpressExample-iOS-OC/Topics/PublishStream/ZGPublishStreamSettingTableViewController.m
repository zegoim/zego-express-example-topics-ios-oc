//
//  ZGPublishStreamSettingTableViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/5/29.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import "ZGPublishStreamSettingTableViewController.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

@interface ZGPublishStreamSettingTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *cameraSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *microphoneSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *speakerSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *hardwareEncoderSwitch;
@property (weak, nonatomic) IBOutlet UISlider *captureVolumeSlider;

@property (weak, nonatomic) IBOutlet UILabel *captureResolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *encodeResolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitrateValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *streamExtraInfoLabel;

@property (nonatomic, strong) ZegoVideoConfig *videoConfig;

@end

@implementation ZGPublishStreamSettingTableViewController

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PublishStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGPublishStreamSettingTableViewController class])];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.videoConfig = [[ZegoExpressEngine sharedEngine] getVideoConfig];

    [self setupUI];
}

- (void)setupUI {
    self.cameraSwitch.on = _enableCamera;
    self.microphoneSwitch.on = ![[ZegoExpressEngine sharedEngine] isMicrophoneMuted];
    self.speakerSwitch.on = ![[ZegoExpressEngine sharedEngine] isSpeakerMuted];
    self.hardwareEncoderSwitch.on = _enableHardwareEncoder;
    self.captureVolumeSlider.continuous = NO;
    self.captureVolumeSlider.value = _captureVolume;

    self.captureResolutionLabel.text = [NSString stringWithFormat:@"%d x %d", (int)_videoConfig.captureResolution.width, (int)_videoConfig.captureResolution.height];
    self.encodeResolutionLabel.text = [NSString stringWithFormat:@"%d x %d", (int)_videoConfig.encodeResolution.width, (int)_videoConfig.encodeResolution.height];
    self.fpsValueLabel.text = [NSString stringWithFormat:@"%d fps", _videoConfig.fps];
    self.bitrateValueLabel.text = [NSString stringWithFormat:@"%d kbps", _videoConfig.bitrate];
    self.streamExtraInfoLabel.text = self.streamExtraInfo;
}

- (void)viewDidDisappear:(BOOL)animated {
    self.presenter.enableCamera = _enableCamera;
    self.presenter.enableHardwareEncoder = _enableHardwareEncoder;
    self.presenter.captureVolume = _captureVolume;
    self.presenter.streamExtraInfo = _streamExtraInfo;
}

- (IBAction)cameraSwitchValueChanged:(UISwitch *)sender {
    _enableCamera = sender.on;
    [[ZegoExpressEngine sharedEngine] enableCamera:_enableCamera];

    [self.presenter appendLog:[NSString stringWithFormat:@"📷 Camera %@", _enableCamera ? @"on 🟢" : @"off 🔴"]];
}

- (IBAction)microphoneSwitchValueChanged:(UISwitch *)sender {
    [[ZegoExpressEngine sharedEngine] muteMicrophone:!sender.on];

    [self.presenter appendLog:[NSString stringWithFormat:@"🎙 Microphone %@", sender.on ? @"on 🟢" : @"off 🔴"]];
}

- (IBAction)speakerSwitchValueChanged:(UISwitch *)sender {
    [[ZegoExpressEngine sharedEngine] muteSpeaker:!sender.on];

    [self.presenter appendLog:[NSString stringWithFormat:@"📣 Speaker %@", sender.on ? @"on 🟢" : @"off 🔴"]];
}

- (IBAction)hardwareEncoderSwitchValueChanged:(UISwitch *)sender {
    _enableHardwareEncoder = sender.on;
    [[ZegoExpressEngine sharedEngine] enableHardwareEncoder:_enableHardwareEncoder];

    [self.presenter appendLog:[NSString stringWithFormat:@"🎛 HardwareEncoder %@", sender.on ? @"on 🟢" : @"off 🔴"]];
}

- (IBAction)captureVolumeSliderValueChanged:(UISlider *)sender {
    _captureVolume = (int)sender.value;
    [[ZegoExpressEngine sharedEngine] setCaptureVolume:_captureVolume];

    [self.presenter appendLog:[NSString stringWithFormat:@"🔊 Set capture volume: %d", _captureVolume]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 4:
            // Capture Resolution
            [self presentSetCaptureResolutionAlertController];
            break;
        case 5:
            // Encode Resolution
            [self presentSetEncodeResolutionAlertController];
            break;
        case 6:
            // FPS
            [self presentSetFpsAlertController];
            break;
        case 7:
            // FPS
            [self presentSetBitrateAlertController];
            break;
        case 8:
            // Stream Extra Info
            [self presentSetStreamExtraInfoAlertController];
        default:
            break;
    }
}

#pragma mark - AlertController

- (void)presentSetCaptureResolutionAlertController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Set Capture Resolution" message:@"Please enter width and height.\n\nThe setting only takes effect the next time the camera is turned on." preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        __strong typeof(self) strongSelf = weakSelf;
        textField.tag = 100;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.placeholder = @"Width";
        textField.text = [NSString stringWithFormat:@"%d", (int)strongSelf.videoConfig.captureResolution.width];
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        __strong typeof(self) strongSelf = weakSelf;
        textField.tag = 200;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.placeholder = @"Height";
        textField.text = [NSString stringWithFormat:@"%d", (int)strongSelf.videoConfig.captureResolution.height];
    }];

    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(self) strongSelf = weakSelf;
        CGSize captureResolution = CGSizeZero;
        for (UITextField *textField in alertController.textFields) {
            if (textField.tag == 100) {
                captureResolution.width = textField.text.intValue;
            } else if (textField.tag == 200) {
                captureResolution.height = textField.text.intValue;
            }
        }
        strongSelf.captureResolutionLabel.text = [NSString stringWithFormat:@"%d x %d", (int)captureResolution.width, (int)captureResolution.height];

        strongSelf.videoConfig.captureResolution = captureResolution;
        [[ZegoExpressEngine sharedEngine] setVideoConfig:strongSelf.videoConfig];

        [self.presenter appendLog:[NSString stringWithFormat:@"📱 Set capture resolution: %d x %d",  (int)captureResolution.width, (int)captureResolution.height]];
    }];

    [alertController addAction:setAction];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentSetEncodeResolutionAlertController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Set Encode Resolution" message:@"Please enter width and height." preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        __strong typeof(self) strongSelf = weakSelf;
        textField.tag = 100;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.placeholder = @"Width";
        textField.text = [NSString stringWithFormat:@"%d", (int)strongSelf.videoConfig.encodeResolution.width];
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        __strong typeof(self) strongSelf = weakSelf;
        textField.tag = 200;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.placeholder = @"Height";
        textField.text = [NSString stringWithFormat:@"%d", (int)strongSelf.videoConfig.encodeResolution.height];
    }];

    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(self) strongSelf = weakSelf;
        CGSize encodeResolution = CGSizeZero;
        for (UITextField *textField in alertController.textFields) {
            if (textField.tag == 100) {
                encodeResolution.width = textField.text.intValue;
            } else if (textField.tag == 200) {
                encodeResolution.height = textField.text.intValue;
            }
        }
        strongSelf.encodeResolutionLabel.text = [NSString stringWithFormat:@"%d x %d", (int)encodeResolution.width, (int)encodeResolution.height];

        strongSelf.videoConfig.encodeResolution = encodeResolution;
        [[ZegoExpressEngine sharedEngine] setVideoConfig:strongSelf.videoConfig];

        [self.presenter appendLog:[NSString stringWithFormat:@"📱 Set encode resolution: %d x %d", (int)encodeResolution.width, (int)encodeResolution.height]];
    }];

    [alertController addAction:setAction];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentSetFpsAlertController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Set FPS" message:nil preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        __strong typeof(self) strongSelf = weakSelf;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.placeholder = @"FPS";
        textField.text = [NSString stringWithFormat:@"%d", strongSelf.videoConfig.fps];
    }];

    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(self) strongSelf = weakSelf;
        UITextField *textField = [alertController.textFields firstObject];
        if (!textField) {
            return;
        }
        int fps = textField.text.intValue;

        strongSelf.fpsValueLabel.text = [NSString stringWithFormat:@"%d fps", fps];

        strongSelf.videoConfig.fps = fps;
        [[ZegoExpressEngine sharedEngine] setVideoConfig:strongSelf.videoConfig];

        [self.presenter appendLog:[NSString stringWithFormat:@"📱 Set video FPS: %d", fps]];
    }];

    [alertController addAction:setAction];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentSetBitrateAlertController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Set Bitrate" message:@"The bitrate is in kbps" preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        __strong typeof(self) strongSelf = weakSelf;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.placeholder = @"Bitrate in kbps";
        textField.text = [NSString stringWithFormat:@"%d", strongSelf.videoConfig.bitrate];
    }];

    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(self) strongSelf = weakSelf;
        UITextField *textField = [alertController.textFields firstObject];
        if (!textField) {
            return;
        }
        int bitrate = textField.text.intValue;

        strongSelf.bitrateValueLabel.text = [NSString stringWithFormat:@"%d kbps", bitrate];

        strongSelf.videoConfig.bitrate = bitrate;
        [[ZegoExpressEngine sharedEngine] setVideoConfig:strongSelf.videoConfig];

        [self.presenter appendLog:[NSString stringWithFormat:@"📱 Set video bitrate: %d kbps", bitrate]];
    }];

    [alertController addAction:setAction];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)presentSetStreamExtraInfoAlertController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Set Stream Extra Info" message:@"Enter stream extra info" preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        __strong typeof(self) strongSelf = weakSelf;
        textField.placeholder = @"Stream Extra Info";
        textField.text = strongSelf.streamExtraInfo;
    }];

    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(self) strongSelf = weakSelf;
        UITextField *textField = [alertController.textFields firstObject];
        if (!textField) {
            return;
        }
        strongSelf.streamExtraInfo = textField.text;
        strongSelf.streamExtraInfoLabel.text = strongSelf.streamExtraInfo;

        [strongSelf.presenter appendLog:[NSString stringWithFormat:@"💬 Set stream extra info: %@", strongSelf.streamExtraInfo]];
        [[ZegoExpressEngine sharedEngine] setStreamExtraInfo:strongSelf.streamExtraInfo callback:^(int errorCode) {
            [strongSelf.presenter appendLog:[NSString stringWithFormat:@"🚩 💬 Set stream extra info result: %d", errorCode]];
        }];
    }];

    [alertController addAction:setAction];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}


@end

#endif
