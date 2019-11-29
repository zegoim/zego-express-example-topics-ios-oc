//
//  ZGPublishTopicConfigManager.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2019/10/25.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import "ZGPublishTopicConfigManager.h"
#import "ZGUserDefaults.h"
#import "ZGHashTableHelper.h"

NSString* const ZGPublishTopicConfigResolutionKey = @"ZGPublishTopicConfigResolutionKey";
NSString* const ZGPublishTopicConfigFpsKey = @"ZGPublishTopicConfigFpsKey";
NSString* const ZGPublishTopicConfigBitrateKey = @"ZGPublishTopicConfigBitrateKey";
NSString* const ZGPublishTopicConfigPreviewViewModeKey = @"ZGPublishTopicConfigPreviewViewModeKey";
NSString* const ZGPublishTopicConfigEnableHardwareEncodeKey = @"ZGPublishTopicConfigEnableHardwareEncodeKey";
NSString* const ZGPublishTopicConfigMirrorModeKey = @"ZGPublishTopicConfigMirrorModeKey";

static ZGPublishTopicConfigManager *instance = nil;

@interface ZGPublishTopicConfigManager () {
    dispatch_queue_t _configOptQueue;
}

@property (nonatomic) ZGUserDefaults *zgUserDefaults;
@property (nonatomic, weak) id<ZGPublishTopicConfigChangedHandler> handler;

@end

@implementation ZGPublishTopicConfigManager

#pragma mark - public methods

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [ZGPublishTopicConfigManager sharedManager];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [ZGPublishTopicConfigManager sharedManager];
}

- (instancetype)init {
    if (self = [super init]) {
        _zgUserDefaults = [[ZGUserDefaults alloc] init];
        _configOptQueue = dispatch_queue_create("com.doudong.ZGPublishTopicConfigOptQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setConfigChangedHandler:(id<ZGPublishTopicConfigChangedHandler>)handler {
    _handler = handler;
}

- (void)setResolution:(CGSize)resolution {
    dispatch_async(_configOptQueue, ^{
        NSArray *resObj = @[@(resolution.width), @(resolution.height)];
        [self.zgUserDefaults setObject:resObj forKey:ZGPublishTopicConfigResolutionKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.handler respondsToSelector:@selector(publishTopicConfigManager:resolutionDidChange:)]) {
                [self.handler publishTopicConfigManager:self resolutionDidChange:resolution];
            }
        });
    });
}

- (CGSize)resolution {
    __block CGSize rs = CGSizeZero;
    dispatch_sync(_configOptQueue, ^{
        NSArray *r = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigResolutionKey];
        if (r && r.count == 2) {
            rs = CGSizeMake(((NSNumber*)r[0]).integerValue, ((NSNumber*)r[1]).integerValue);
        } else {
            // Set the default
            rs = CGSizeMake(360, 640);
        }
    });
    return rs;
}

- (void)setFps:(NSInteger)fps {
    dispatch_async(_configOptQueue, ^{
        NSNumber *fpsObj = @(fps);
        [self.zgUserDefaults setObject:fpsObj forKey:ZGPublishTopicConfigFpsKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.handler respondsToSelector:@selector(publishTopicConfigManager:fpsDidChange:)]) {
                [self.handler publishTopicConfigManager:self fpsDidChange:fps];
            }
        });
    });
}

- (NSInteger)fps {
    __block NSInteger fps = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigFpsKey];
        if (n) {
            fps = [n integerValue];
        } else {
            // Set the default
            fps = 15;
        }
    });
    return fps;
}

- (void)setBitrate:(NSInteger)bitrate {
    dispatch_async(_configOptQueue, ^{
        NSNumber *bitrateObj = @(bitrate);
        [self.zgUserDefaults setObject:bitrateObj forKey:ZGPublishTopicConfigBitrateKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.handler respondsToSelector:@selector(publishTopicConfigManager:bitrateDidChange:)]) {
                [self.handler publishTopicConfigManager:self bitrateDidChange:bitrate];
            }
        });
    });
}

- (NSInteger)bitrate {
    __block NSInteger bitrate = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigBitrateKey];
        if (n) {
            bitrate = [n integerValue];
        } else {
            // Set the default
            bitrate = 600000;
        }
    });
    return bitrate;
}

- (void)setPreviewViewMode:(ZegoViewMode)previewViewMode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *modeObj = @(previewViewMode);
        [self.zgUserDefaults setObject:modeObj forKey:ZGPublishTopicConfigPreviewViewModeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.handler respondsToSelector:@selector(publishTopicConfigManager:previewViewModeDidChange:)]) {
                [self.handler publishTopicConfigManager:self previewViewModeDidChange:previewViewMode];
            }
        });
    });
}

- (ZegoViewMode)previewViewMode {
    __block ZegoViewMode mode = ZegoViewModeAspectFit;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigPreviewViewModeKey];
        if (n) {
            mode = (ZegoViewMode)[n integerValue];
        } else {
            // Set the default
            mode = ZegoViewModeAspectFit;
        }
    });
    return mode;
}

- (void)setEnableHardwareEncode:(BOOL)enableHardwareEncode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(enableHardwareEncode);
        [self.zgUserDefaults setObject:obj forKey:ZGPublishTopicConfigEnableHardwareEncodeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.handler respondsToSelector:@selector(publishTopicConfigManager:enableHardwareEncodeDidChange:)]) {
                [self.handler publishTopicConfigManager:self enableHardwareEncodeDidChange:enableHardwareEncode];
            }
        });
    });
}

- (BOOL)isEnableHardwareEncode {
    __block BOOL isEnable = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigEnableHardwareEncodeKey];
        if (n) {
            isEnable = [n boolValue];
        } else {
            // Set the default
            isEnable = NO;
        }
    });
    return isEnable;
}

- (void)setMirrorMode:(ZegoVideoMirrorMode)mirrorMode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *modeObj = @(mirrorMode);
        [self.zgUserDefaults setObject:modeObj forKey:ZGPublishTopicConfigPreviewViewModeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.handler respondsToSelector:@selector(publishTopicConfigManager:mirrorModeDidChange:)]) {
                [self.handler publishTopicConfigManager:self mirrorModeDidChange:(ZegoVideoMirrorMode)mirrorMode];
            }
        });
    });
}

- (ZegoVideoMirrorMode)mirrorMode {
    __block ZegoVideoMirrorMode mode = ZegoVideoMirrorModeOnlyPreviewMirror;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigPreviewViewModeKey];
        if (n) {
            mode = (ZegoVideoMirrorMode)[n integerValue];
        } else {
            // Set the default
            mode = ZegoVideoMirrorModeOnlyPreviewMirror;
        }
    });
    return mode;
}


@end


#endif
