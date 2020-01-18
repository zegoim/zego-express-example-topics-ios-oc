//
//  ZGExternalVideoCapturePublishStreamViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/1/12.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import "ZGExternalVideoCapturePublishStreamViewController.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGUserIDHelper.h"

#import "ZGExternalVideoCaptureCameraDevice.h"
#import "ZGExternalVideoCaptureImageDevice.h"

#import <ZegoExpressEngine/ZegoExpressEngine.h>

@interface ZGExternalVideoCapturePublishStreamViewController () <ZegoEventHandler, ZegoExternalVideoCapturer,  ZGExternalVideoCapturePixelBufferDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *startLiveButton;
@property (nonatomic, assign) ZegoPublisherState publisherState;

@property (nonatomic, strong) ZegoExpressEngine *engine;

@property (nonatomic, strong) id<ZegoVideoFrameSender> videoFrameSender;

@property (nonatomic, strong) id<ZGExternalVideoCaptureDevice> captureDevice;

@end

@implementation ZGExternalVideoCapturePublishStreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"External Video Capture";
    [self createEngineAndLoginRoom];
    [self startLive];
}

- (void)createEngineAndLoginRoom {
    // Set Capture Config
    ZegoExternalVideoCaptureConfig *captureConfig = [[ZegoExternalVideoCaptureConfig alloc] init];
    captureConfig.bufferType = ZegoVideoBufferTypeCVPixelBuffer;
    
    ZegoEngineConfig *engineConfig = [[ZegoEngineConfig alloc] init];
    [engineConfig setExternalVideoCaptureConfig:captureConfig];
    
    // Set engine config, must be called before create engine
    [ZegoExpressEngine setEngineConfig:engineConfig];
    
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];
    
    ZGLogInfo(@" 🚀 Create ZegoExpressEngine");
    
    self.engine = [ZegoExpressEngine createEngineWithAppID:(unsigned int)appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];
    
    [self.engine setExternalVideoCapturer:self];
    
    // Login Room
    ZegoUser *user = [ZegoUser userWithUserID:[ZGUserIDHelper userID] userName:[ZGUserIDHelper userName]];
    ZGLogInfo(@" 🚪 Login room. roomID: %@", self.roomID);
    [self.engine loginRoom:self.roomID user:user config:[ZegoRoomConfig defaultConfig]];
    
    [self.engine setVideoConfig:[ZegoVideoConfig configWithResolution:ZegoResolution1080x1920]];
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
    // When external video capture is enabled, developers need to render the preview by themselves
//     [self.engine startPreview:[ZegoCanvas canvasWithView:self.previewView]];
    
    // Start publishing
    ZGLogInfo(@" 📤 Start publishing stream. streamID: %@", self.streamID);
    [self.engine startPublishing:self.streamID];
}

- (void)stopLive {
    [self.engine stopPublishing];
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

- (id<ZGExternalVideoCaptureDevice>)captureDevice {
    if (!_captureDevice) {
        if (self.captureSourceType == 0) {
            // BGRA32 or NV12
            OSType pixelFormat = self.captureDataFormat == 0 ? kCVPixelFormatType_32BGRA : kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
            _captureDevice = [[ZGExternalVideoCaptureCameraDevice alloc] initWithPixelFormatType:pixelFormat];
            _captureDevice.delegate = self;
        } else if (self.captureSourceType == 1) {
            _captureDevice = [[ZGExternalVideoCaptureImageDevice alloc] initWithMotionImage:[UIImage imageNamed:@"ZegoLogo"]];
            _captureDevice.delegate = self;
        }
    }
    return _captureDevice;
}


#pragma mark - ZegoExternalVideoCapturer

- (void)willStart:(nonnull id<ZegoVideoFrameSender>)sender {
    ZGLogInfo(@" 🚩 🟢 ZegoExternalVideoCapturer Will Start");
    // Save the sender
    self.videoFrameSender = sender;
    [self.captureDevice startCapture];
}

- (void)willStop {
    ZGLogInfo(@" 🚩 🔴 ZegoExternalVideoCapturer Will Stop");
    self.videoFrameSender = nil;
    [self.captureDevice stopCapture];
}


#pragma mark - ZGExternalVideoCapturePixelBufferDelegate

- (void)captureDevice:(nonnull id<ZGExternalVideoCaptureDevice>)device didCapturedData:(nonnull CVPixelBufferRef)data presentationTimeStamp:(CMTime)timeStamp {
    
    // Send pixel buffer to ZEGO SDK
    [self.videoFrameSender sendPixelBuffer:data timeStamp:timeStamp];
    
    // When external video capture is enabled, developers need to render the preview by themselves
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
