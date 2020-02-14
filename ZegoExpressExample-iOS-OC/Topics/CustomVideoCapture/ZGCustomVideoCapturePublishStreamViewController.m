//
//  ZGCustomVideoCapturePublishStreamViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/1/12.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_CustomVideoCapture

#import "ZGCustomVideoCapturePublishStreamViewController.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGUserIDHelper.h"

#import "ZGCaptureDeviceCamera.h"
#import "ZGCaptureDeviceImage.h"

#import <ZegoExpressEngine/ZegoExpressEngine.h>

@interface ZGCustomVideoCapturePublishStreamViewController () <ZegoEventHandler, ZegoCustomVideoCaptureHandler,  ZGCaptureDeviceDataOutputPixelBufferDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *startLiveButton;
@property (nonatomic, assign) ZegoPublisherState publisherState;

@property (nonatomic, strong) id<ZGCaptureDevice> captureDevice;

@end

@implementation ZGCustomVideoCapturePublishStreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Publish";
    [self createEngineAndLoginRoom];
    [self startLive];
}

- (void)createEngineAndLoginRoom {
    // Set capture config
    ZegoCustomVideoCaptureConfig *captureConfig = [[ZegoCustomVideoCaptureConfig alloc] init];
    captureConfig.bufferType = ZegoVideoBufferTypeCVPixelBuffer;
    
    ZegoEngineConfig *engineConfig = [[ZegoEngineConfig alloc] init];
    [engineConfig setCustomVideoCaptureConfig:captureConfig];
    
    // Set engine config, must be called before create engine
    [ZegoExpressEngine setEngineConfig:engineConfig];
    
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];
    
    ZGLogInfo(@" 🚀 Create ZegoExpressEngine");
    [ZegoExpressEngine createEngineWithAppID:(unsigned int)appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];
    
    // Set custom video capture handler
    [[ZegoExpressEngine sharedEngine] setCustomVideoCaptureHandler:self];
    
    // Login room
    ZegoUser *user = [ZegoUser userWithUserID:[ZGUserIDHelper userID] userName:[ZGUserIDHelper userName]];
    ZGLogInfo(@" 🚪 Login room. roomID: %@", self.roomID);
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomID user:user config:[ZegoRoomConfig defaultConfig]];
    
    // Set video config
    [[ZegoExpressEngine sharedEngine] setVideoConfig:[ZegoVideoConfig configWithResolution:ZegoResolution1080x1920]];
}

- (IBAction)startLiveButtonClick:(UIButton *)sender {
    switch (self.publisherState) {
        case ZegoPublisherStatePublishing:
            [self stopLive];
            break;
        case ZegoPublisherStateNoPublish:
            [self startLive];
            break;
        case ZegoPublisherStatePublishRequesting:
            break;
    }
}

- (void)startLive {
    // When custom video capture is enabled, developers need to render the preview by themselves
//    [self.engine startPreview:[ZegoCanvas canvasWithView:self.previewView]];
    
    // Start publishing
    ZGLogInfo(@" 📤 Start publishing stream. streamID: %@", self.streamID);
    [[ZegoExpressEngine sharedEngine] startPublishing:self.streamID];
}

- (void)stopLive {
    [[ZegoExpressEngine sharedEngine] stopPublishing];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.isBeingDismissed || self.isMovingFromParentViewController
        || (self.navigationController && self.navigationController.isBeingDismissed)) {
        ZGLogInfo(@" 🏳️ Destroy ZegoExpressEngine");
        [ZegoExpressEngine destroyEngine];
    }
    [super viewDidDisappear:animated];
}

#pragma mark - Getter

- (id<ZGCaptureDevice>)captureDevice {
    if (!_captureDevice) {
        if (self.captureSourceType == 0) {
            // BGRA32 or NV12
            OSType pixelFormat = self.captureDataFormat == 0 ? kCVPixelFormatType_32BGRA : kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
            _captureDevice = [[ZGCaptureDeviceCamera alloc] initWithPixelFormatType:pixelFormat];
            _captureDevice.delegate = self;
        } else if (self.captureSourceType == 1) {
            _captureDevice = [[ZGCaptureDeviceImage alloc] initWithMotionImage:[UIImage imageNamed:@"ZegoLogo"]];
            _captureDevice.delegate = self;
        }
    }
    return _captureDevice;
}


#pragma mark - ZegoCustomVideoCaptureHandler

// Note: This callback is not in the main thread. If you have UI operations, please switch to the main thread yourself.
- (void)onStart {
    ZGLogInfo(@" 🚩 🟢 ZegoCustomVideoCaptureHandler onStart");
    [self.captureDevice startCapture];
}

// Note: This callback is not in the main thread. If you have UI operations, please switch to the main thread yourself.
- (void)onStop {
    ZGLogInfo(@" 🚩 🔴 ZegoCustomVideoCaptureHandler onStop");
    [self.captureDevice stopCapture];
}


#pragma mark - ZGCustomVideoCapturePixelBufferDelegate

- (void)captureDevice:(nonnull id<ZGCaptureDevice>)device didCapturedData:(nonnull CVPixelBufferRef)data presentationTimeStamp:(CMTime)timeStamp {
    
    // Send pixel buffer to ZEGO SDK
    [[ZegoExpressEngine sharedEngine] sendCustomVideoCapturePixelBuffer:data timeStamp:timeStamp];
    
    // When custom video capture is enabled, developers need to render the preview by themselves
    [self renderWithCVPixelBuffer:data];
}


#pragma mark - ZegoEventHandler

- (void)onPublisherStateUpdate:(ZegoPublisherState)state errorCode:(int)errorCode stream:(NSString *)streamID {
    ZGLogInfo(@" 🚩 📤 Publisher State Update Callback: %lu, errorCode: %d, streamID: %@", (unsigned long)state, (int)errorCode, streamID);
    
    self.publisherState = state;
    
    switch (state) {
        case ZegoPublisherStateNoPublish:
            [self.startLiveButton setTitle:@"Start Live" forState:UIControlStateNormal];
            break;
        case ZegoPublisherStatePublishRequesting:
            [self.startLiveButton setTitle:@"Requesting" forState:UIControlStateNormal];
            break;
        case ZegoPublisherStatePublishing:
            [self.startLiveButton setTitle:@"Stop Live" forState:UIControlStateNormal];
            break;
    }
}

#pragma mark - Render Preview

- (void)renderWithCVPixelBuffer:(CVPixelBufferRef)buffer {
    CIImage *image = [CIImage imageWithCVPixelBuffer:buffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.previewView.image = [UIImage imageWithCIImage:image];
    });
}


@end

#endif
