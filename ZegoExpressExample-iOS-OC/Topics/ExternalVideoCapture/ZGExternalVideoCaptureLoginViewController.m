//
//  ZGExternalVideoCaptureLoginViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/1/12.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import "ZGExternalVideoCaptureLoginViewController.h"
#import "ZGExternalVideoCapturePublishStreamViewController.h"

NSString* const ZGExternalVideoCaptureLoginVCKey_roomID = @"kRoomID";
NSString* const ZGExternalVideoCaptureLoginVCKey_streamID = @"kStreamID";

@interface ZGExternalVideoCaptureLoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *captureSourceTypeSeg;
@property (weak, nonatomic) IBOutlet UISegmentedControl *captureDataFormatSeg;


@end

@implementation ZGExternalVideoCaptureLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    self.roomIDTextField.text = [self savedValueForKey:ZGExternalVideoCaptureLoginVCKey_roomID];
    self.streamIDTextField.text = [self savedValueForKey:ZGExternalVideoCaptureLoginVCKey_streamID];
}

- (IBAction)publishStream:(UIButton *)sender {
    if (!self.roomIDTextField.text || [self.roomIDTextField.text isEqualToString:@""]) {
        ZGLogError(@" ❗️ Please fill in roomID.");
        return;
    }
    
    if (!self.streamIDTextField.text || [self.streamIDTextField.text isEqualToString:@""]) {
        ZGLogError(@" ❗️ Please fill in streamID.");
        return;
    }
    
    [self saveValue:self.roomIDTextField.text forKey:ZGExternalVideoCaptureLoginVCKey_roomID];
    [self saveValue:self.streamIDTextField.text forKey:ZGExternalVideoCaptureLoginVCKey_streamID];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoCapture" bundle:nil];
    ZGExternalVideoCapturePublishStreamViewController *publisherVC = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGExternalVideoCapturePublishStreamViewController class])];
    
    publisherVC.roomID = self.roomIDTextField.text;
    publisherVC.streamID = self.streamIDTextField.text;
    publisherVC.captureSourceType = self.captureSourceTypeSeg.selectedSegmentIndex;
    publisherVC.captureDataFormat = self.captureDataFormatSeg.selectedSegmentIndex;
    
    [self.navigationController pushViewController:publisherVC animated:YES];
}

- (IBAction)captureSourceSegValueChanged:(UISegmentedControl *)sender {
    if (self.captureSourceTypeSeg.selectedSegmentIndex == 1) {
        [self.captureDataFormatSeg setEnabled:NO forSegmentAtIndex:1];
        [self.captureDataFormatSeg setSelectedSegmentIndex:0];
    } else {
        [self.captureDataFormatSeg setEnabled:YES forSegmentAtIndex:1];
        [self.captureDataFormatSeg setSelectedSegmentIndex:0];
    }
}

@end

#endif
