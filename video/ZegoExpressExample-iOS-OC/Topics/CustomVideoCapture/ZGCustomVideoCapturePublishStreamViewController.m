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

#import "ZGVideoFrameEncoder.h"

#import <ZegoExpressEngine/ZegoExpressEngine.h>

@interface ZGCustomVideoCapturePublishStreamViewController () <ZegoEventHandler, ZegoCustomVideoCaptureHandler, ZGCaptureDeviceDataOutputPixelBufferDelegate, ZGVideoFrameEncoderDelegate>

@property (weak, nonatomic) IBOutlet UIView *previewView;

@property (nonatomic, strong) UIBarButtonItem *startLiveButton;
@property (nonatomic, strong) UIBarButtonItem *stopLiveButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;

@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *streamIDLabel;

@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitrateLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;

@property (nonatomic, strong) id<ZGCaptureDevice> captureDevice;

@property (nonatomic, strong) ZegoVideoEncodedFrameParam *encodeFrameParam;
@property (nonatomic, strong) ZGVideoFrameEncoder *encoder;

@end

@implementation ZGCustomVideoCapturePublishStreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self createEngineAndLoginRoom];
    [self startLive];
}

- (void)setupUI {
    self.roomIDLabel.text = [NSString stringWithFormat:@"RoomID: %@", self.roomID];
    self.streamIDLabel.text = [NSString stringWithFormat:@"StreamID: %@", self.streamID];

    self.startLiveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(startLive)];
    self.stopLiveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(stopLive)];
    self.navigationItem.rightBarButtonItem = self.startLiveButton;

    if (self.captureSourceType == ZGCustomVideoCaptureSourceTypeImage) {
        self.switchCameraButton.hidden = YES;
    }
}

- (IBAction)switchCamera:(UIButton *)sender {
    if ([self.captureDevice respondsToSelector:@selector(switchCameraPosition)]) {
        [self.captureDevice switchCameraPosition];
    }
}

- (void)createEngineAndLoginRoom {

    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];

    ZGLogInfo(@" 🚀 Create ZegoExpressEngine");
    [ZegoExpressEngine createEngineWithAppID:(unsigned int)appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];

    // Init capture config
    ZegoCustomVideoCaptureConfig *captureConfig = [[ZegoCustomVideoCaptureConfig alloc] init];

    if (self.captureBufferType == ZGCustomVideoCaptureBufferTypeCVPixelBuffer) {
        captureConfig.bufferType = ZegoVideoBufferTypeCVPixelBuffer;
    } else if (self.captureBufferType == ZGCustomVideoCaptureBufferTypeEncodedFrame) {
        captureConfig.bufferType = ZegoVideoBufferTypeEncodedData;
    }

    // Enable custom video capture
    [[ZegoExpressEngine sharedEngine] enableCustomVideoCapture:YES config:captureConfig channel:ZegoPublishChannelMain];

    // Set self as custom video capture handler
    [[ZegoExpressEngine sharedEngine] setCustomVideoCaptureHandler:self];

    // Login room
    ZegoUser *user = [ZegoUser userWithUserID:[ZGUserIDHelper userID] userName:[ZGUserIDHelper userName]];
    ZGLogInfo(@" 🚪 Login room. roomID: %@", self.roomID);
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomID user:user config:[ZegoRoomConfig defaultConfig]];

    // Set video config
    [[ZegoExpressEngine sharedEngine] setVideoConfig:[ZegoVideoConfig configWithPreset:ZegoVideoConfigPreset720P]];
}

- (void)startLive {
    // The engine supports rendering the preview when the capture type is CVPixelBuffer.
    // Not supported when the capture type is EncodedData.
    ZGLogInfo(@" 🔌 Start preview");
    [[ZegoExpressEngine sharedEngine] startPreview:[ZegoCanvas canvasWithView:self.previewView]];

    ZGLogInfo(@" 📤 Start publishing stream. streamID: %@", self.streamID);
    [[ZegoExpressEngine sharedEngine] startPublishingStream:self.streamID];
}

- (void)stopLive {
    ZGLogInfo(@" 🔌 Stop preview");
    [[ZegoExpressEngine sharedEngine] stopPreview];

    ZGLogInfo(@" 📤 Stop publishing stream");
    [[ZegoExpressEngine sharedEngine] stopPublishingStream];
}

- (void)dealloc {
    ZGLogInfo(@" 🏳️ Destroy ZegoExpressEngine");
    [ZegoExpressEngine destroyEngine:^{
        // This callback is only used to notify the completion of the release of internal resources of the engine.
        // Developers cannot release resources related to the engine within this callback.
        //
        // In general, developers do not need to listen to this callback.
        ZGLogInfo(@" 🚩 🏳️ Destroy ZegoExpressEngine complete");
    }];

    // After destroying the engine, you will not receive the `-onStop:` callback, you need to stop the custom video caputre manually.
    [self.captureDevice stopCapture];
}

#pragma mark - Getter

- (id<ZGCaptureDevice>)captureDevice {
    if (!_captureDevice) {
        if (self.captureSourceType == ZGCustomVideoCaptureSourceTypeCamera) {
            // BGRA32 or NV12
            OSType pixelFormat = self.captureDataFormat == ZGCustomVideoCaptureDataFormatBGRA32 ? kCVPixelFormatType_32BGRA : kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
            _captureDevice = [[ZGCaptureDeviceCamera alloc] initWithPixelFormatType:pixelFormat];
        } else if (self.captureSourceType == ZGCustomVideoCaptureSourceTypeImage) {
            _captureDevice = [[ZGCaptureDeviceImage alloc] initWithMotionImage:[UIImage imageNamed:@"ZegoLogo"].CGImage contentSize:CGSizeMake(720, 1280)];
        }

        _captureDevice.delegate = self;
    }
    return _captureDevice;
}

- (ZGVideoFrameEncoder *)encoder {
    if (!_encoder) {
        _encoder = [[ZGVideoFrameEncoder alloc] initWithResolution:CGSizeMake(720, 1280) maxBitrate:(int)(3000 * 1000 * 1.2) averageBitrate:(int)(3000 * 1000) fps:30];
        _encoder.delegate = self;
    }
    return _encoder;
}


#pragma mark - ZegoCustomVideoCaptureHandler

// Note: This callback is not in the main thread. If you have UI operations, please switch to the main thread yourself.
- (void)onStart:(ZegoPublishChannel)channel {
    ZGLogInfo(@" 🚩 🟢 ZegoCustomVideoCaptureHandler onStart, channel: %d", (int)channel);
    [self.captureDevice startCapture];
}

// Note: This callback is not in the main thread. If you have UI operations, please switch to the main thread yourself.
- (void)onStop:(ZegoPublishChannel)channel {
    ZGLogInfo(@" 🚩 🔴 ZegoCustomVideoCaptureHandler onStop, channel: %d", (int)channel);
    [self.captureDevice stopCapture];
}


#pragma mark - ZGCustomVideoCapturePixelBufferDelegate

- (void)captureDevice:(id<ZGCaptureDevice>)device didCapturedData:(CMSampleBufferRef)data {

    if (self.captureBufferType == ZGCustomVideoCaptureBufferTypeCVPixelBuffer) {

        // BufferType: CVPixelBuffer

        // Send pixel buffer to ZEGO SDK
        [[ZegoExpressEngine sharedEngine] sendCustomVideoCapturePixelBuffer:CMSampleBufferGetImageBuffer(data) timestamp:CMSampleBufferGetPresentationTimeStamp(data)];

    } else if (self.captureBufferType == ZGCustomVideoCaptureBufferTypeEncodedFrame) {

        // BufferType: Encoded frame (H.264)

        // Need to encode frame
        [self.encoder encodeBuffer:data];
    }
}


#pragma mark - ZGVideoFrameEncoderDelegate

// BufferType: Encoded frame (H.264)
- (void)encoder:(ZGVideoFrameEncoder *)encoder encodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame timestamp:(CMTime)timestamp {

    self.encodeFrameParam.isKeyFrame = isKeyFrame;

    // Send encoded frame to ZEGO SDK
    [[ZegoExpressEngine sharedEngine] sendCustomVideoCaptureEncodedData:data params:self.encodeFrameParam timestamp:timestamp];
}

- (ZegoVideoEncodedFrameParam *)encodeFrameParam {
    if (!_encodeFrameParam) {
        _encodeFrameParam = [[ZegoVideoEncodedFrameParam alloc] init];
        _encodeFrameParam.size = CGSizeMake(720, 1280);
        _encodeFrameParam.format = ZegoVideoEncodedFrameFormatAVCC; // The VideoToolBox default compression format is AVCC
    }
    return _encodeFrameParam;
}


#pragma mark - ZegoEventHandler

- (void)onPublisherStateUpdate:(ZegoPublisherState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData streamID:(NSString *)streamID {
    ZGLogInfo(@" 🚩 📤 Publisher State Update Callback: %lu, errorCode: %d, streamID: %@", (unsigned long)state, (int)errorCode, streamID);

    switch (state) {
        case ZegoPublisherStateNoPublish:
            self.title = @"🔴 No Publish";
            self.navigationItem.rightBarButtonItem = self.startLiveButton;
            break;
        case ZegoPublisherStatePublishRequesting:
            self.title = @"🟡 Publish Requesting";
            self.navigationItem.rightBarButtonItem = self.stopLiveButton;
            break;
        case ZegoPublisherStatePublishing:
            self.title = @"🟢 Publishing";
            self.navigationItem.rightBarButtonItem = self.stopLiveButton;
            break;
    }
}

- (void)onPublisherVideoSizeChanged:(CGSize)size channel:(ZegoPublishChannel)channel {
    self.resolutionLabel.text = [NSString stringWithFormat:@"Resolution: %.fx%.f  ", size.width, size.height];
}

- (void)onPublisherQualityUpdate:(ZegoPublishStreamQuality *)quality streamID:(NSString *)streamID {
    self.fpsLabel.text = [NSString stringWithFormat:@"FPS: %d fps \n", (int)quality.videoSendFPS];
    self.bitrateLabel.text = [NSString stringWithFormat:@"Bitrate: %.2f kb/s \n", quality.videoKBPS];
}


@end

#endif
