//
//  ZGExternalVideoRenderLoginViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/1/1.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoRender

#import "ZGExternalVideoRenderLoginViewController.h"
#import "ZGExternalVideoRenderPublishStreamViewController.h"
#import "ZGExternalVideoRenderPlayStreamViewController.h"

NSString* const ZGExternalVideoRenderLoginVCKey_roomID = @"kRoomID";
NSString* const ZGExternalVideoRenderLoginVCKey_streamID = @"kStreamID";

@interface ZGExternalVideoRenderLoginViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, copy) NSArray<NSString *> *renderBufferTypeList;
@property (nonatomic, copy) NSArray<NSString *> *renderFormatSeriesList;

@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UIPickerView *renderTypeFormatPicker;
@property (weak, nonatomic) IBOutlet UISwitch *internalRenderSwitch;

@end

@implementation ZGExternalVideoRenderLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.renderBufferTypeList = @[@"Unknown", @"RawData", @"CVPixelBuffer"];
    self.renderFormatSeriesList = @[@"RGB", @"YUV"];
    
    [self setupUI];
}

- (void)setupUI {
    self.roomIDTextField.text = [self savedValueForKey:ZGExternalVideoRenderLoginVCKey_roomID];
    self.streamIDTextField.text = [self savedValueForKey:ZGExternalVideoRenderLoginVCKey_streamID];
    
    [self.renderTypeFormatPicker setDelegate:self];
    [self.renderTypeFormatPicker setDataSource:self];
    
    [self.renderTypeFormatPicker selectRow:2 inComponent:0 animated:YES]; // Select CVPixelBuffer
    [self.renderTypeFormatPicker selectRow:0 inComponent:1 animated:YES]; // Select RGB
}

- (BOOL)prepareForJump {
    if (!self.roomIDTextField.text || [self.roomIDTextField.text isEqualToString:@""]) {
        ZGLogError(@" ❗️ Please fill in roomID.");
        return NO;
    }
    
    if (!self.streamIDTextField.text || [self.streamIDTextField.text isEqualToString:@""]) {
        ZGLogError(@" ❗️ Please fill in streamID.");
        return NO;
    }
    
    [self saveValue:self.roomIDTextField.text forKey:ZGExternalVideoRenderLoginVCKey_roomID];
    [self saveValue:self.streamIDTextField.text forKey:ZGExternalVideoRenderLoginVCKey_streamID];
    
    return YES;
}

- (IBAction)publishStream:(UIButton *)sender {
    if (![self prepareForJump]) return;
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoRender" bundle:nil];
    ZGExternalVideoRenderPublishStreamViewController *publisherVC = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGExternalVideoRenderPublishStreamViewController class])];
    publisherVC.bufferType = (int)[self.renderTypeFormatPicker selectedRowInComponent:0];
    publisherVC.frameFormatSeries = (int)[self.renderTypeFormatPicker selectedRowInComponent:1];
    publisherVC.enableInternalRender = self.internalRenderSwitch.on;
    publisherVC.roomID = self.roomIDTextField.text;
    publisherVC.streamID = self.streamIDTextField.text;
    [self.navigationController pushViewController:publisherVC animated:YES];
}

- (IBAction)playStream:(UIButton *)sender {
    if (![self prepareForJump]) return;
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoRender" bundle:nil];
    ZGExternalVideoRenderPlayStreamViewController *playerVC = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGExternalVideoRenderPlayStreamViewController class])];
    playerVC.bufferType = (int)[self.renderTypeFormatPicker selectedRowInComponent:0];
    playerVC.frameFormatSeries = (int)[self.renderTypeFormatPicker selectedRowInComponent:1];
    playerVC.enableInternalRender = self.internalRenderSwitch.on;
    playerVC.roomID = self.roomIDTextField.text;
    playerVC.streamID = self.streamIDTextField.text;
    [self.navigationController pushViewController:playerVC animated:YES];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - PickerView

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        return self.renderBufferTypeList.count;
    } else {
        return self.renderFormatSeriesList.count;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0) {
        return self.renderBufferTypeList[row];
    } else {
        return self.renderFormatSeriesList[row];
    }
}

@end

#endif
