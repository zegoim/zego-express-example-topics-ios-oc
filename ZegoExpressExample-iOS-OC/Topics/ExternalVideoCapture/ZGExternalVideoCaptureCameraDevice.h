//
//  ZGExternalVideoCaptureCameraDevice.h
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/1/12.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import <Foundation/Foundation.h>
#import "ZGExternalVideoCaptureProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoCaptureCameraDevice : NSObject <ZGExternalVideoCaptureDevice>

@property (nonatomic, weak) id<ZGExternalVideoCapturePixelBufferDelegate> delegate;

- (instancetype)initWithPixelFormatType:(OSType)pixelFormatType;

@end

NS_ASSUME_NONNULL_END

#endif
