//
//  ZGExternalVideoCapturePublishStreamViewController.h
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/1/12.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoCapturePublishStreamViewController : UIViewController

@property (nonatomic, copy) NSString *roomID;

@property (nonatomic, copy) NSString *streamID;

/// Capture source type, 0: Camera, 1: Motion Image
@property (nonatomic, assign) NSUInteger captureSourceType;

/// Capture CVPixelBuffer data format, 0: BGRA32, 1: NV12(yuv420sp)
@property (nonatomic, assign) NSUInteger captureDataFormat;

@end

NS_ASSUME_NONNULL_END

#endif
