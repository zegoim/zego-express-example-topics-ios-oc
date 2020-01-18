//
//  ZGExternalVideoCaptureProtocol.h
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/1/12.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGExternalVideoCaptureDevice;

@protocol ZGExternalVideoCapturePixelBufferDelegate <NSObject>

- (void)captureDevice:(id<ZGExternalVideoCaptureDevice>)device didCapturedData:(CVPixelBufferRef)data presentationTimeStamp:(CMTime)timeStamp;

@end


@protocol ZGExternalVideoCaptureDevice <NSObject>

@property (nonatomic, weak) id<ZGExternalVideoCapturePixelBufferDelegate> delegate;

- (void)startCapture;

- (void)stopCapture;

@end

NS_ASSUME_NONNULL_END

#endif
