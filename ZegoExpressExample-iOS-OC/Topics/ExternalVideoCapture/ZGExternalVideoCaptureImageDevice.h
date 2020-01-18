//
//  ZGExternalVideoCaptureImageDevice.h
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/1/12.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import <Foundation/Foundation.h>
#import "ZGExternalVideoCaptureProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoCaptureImageDevice : NSObject <ZGExternalVideoCaptureDevice>

@property (nonatomic, weak) id<ZGExternalVideoCapturePixelBufferDelegate> delegate;

- (instancetype)initWithMotionImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END

#endif
