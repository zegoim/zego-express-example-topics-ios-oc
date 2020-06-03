//
//  ZGPlayTopicConfigManager.m
//  ZegoExpressExample-iOS-OC
//
//  Created by jeffreypeng on 2019/8/12.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Play

#import "ZGPlayTopicConfigManager.h"
#import "ZGUserDefaults.h"
#import "ZGHashTableHelper.h"

NSString* const ZGPlayTopicConfigPlayViewModeKey = @"ZGPlayTopicConfigPlayViewModeKey";

NSString* const ZGPlayTopicConfigPlayStreamVolumeKey = @"ZGPlayTopicConfigPlayStreamVolumeKey";

NSString* const ZGPlayTopicConfigEnableHardwareDecodeKey = @"ZGPlayTopicConfigEnableHardwareDecodeKey";

@interface ZGPlayTopicConfigManager ()
{
    dispatch_queue_t _configOptQueue;
}

@property (nonatomic) ZGUserDefaults *zgUserDefaults;
@property (nonatomic, weak) id<ZGPlayTopicConfigChangedHandler> handler;

@end

@implementation ZGPlayTopicConfigManager

static ZGPlayTopicConfigManager *instance = nil;

#pragma mark - public methods

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [ZGPlayTopicConfigManager sharedManager];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [ZGPlayTopicConfigManager sharedManager];
}

- (instancetype)init {
    if (self = [super init]) {
        _zgUserDefaults = [[ZGUserDefaults alloc] init];
        _configOptQueue = dispatch_queue_create("com.doudong.ZGPlayTopicConfigOptQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setConfigChangedHandler:(id<ZGPlayTopicConfigChangedHandler>)handler {
    _handler = handler;
}

- (void)setPlayViewMode:(ZegoViewMode)playViewMode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(playViewMode);
        [self.zgUserDefaults setObject:obj forKey:ZGPlayTopicConfigPlayViewModeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.handler respondsToSelector:@selector(playTopicConfigManager:playViewModeDidChange:)]) {
                [self.handler playTopicConfigManager:self playViewModeDidChange:playViewMode];
            }
        });
    });
}

- (ZegoViewMode)playViewMode {
    __block ZegoViewMode viewMode = ZegoViewModeAspectFit;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *obj = [self.zgUserDefaults objectForKey:ZGPlayTopicConfigPlayViewModeKey];
        if (obj) {
            viewMode = (ZegoViewMode)[obj integerValue];
        } else {
            viewMode = ZegoViewModeAspectFit;
        }
    });
    return viewMode;
}

- (void)setPlayStreamVolume:(int)playStreamVolume {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(playStreamVolume);
        [self.zgUserDefaults setObject:obj forKey:ZGPlayTopicConfigPlayStreamVolumeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.handler respondsToSelector:@selector(playTopicConfigManager:playStreamVolumeDidChange:)]) {
                [self.handler playTopicConfigManager:self playStreamVolumeDidChange:playStreamVolume];
            }
        });
    });
}

- (int)playStreamVolume {
    __block int volume = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *obj = [self.zgUserDefaults objectForKey:ZGPlayTopicConfigPlayStreamVolumeKey];
        if (obj) {
            volume = [obj intValue];
        } else {
            volume = 100;
        }
    });
    return volume;
}

- (void)setEnableHardwareDecode:(BOOL)enableHardwareDecode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(enableHardwareDecode);
        [self.zgUserDefaults setObject:obj forKey:ZGPlayTopicConfigEnableHardwareDecodeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.handler respondsToSelector:@selector(playTopicConfigManager:enableHardwareDecodeDidChange:)]) {
                [self.handler playTopicConfigManager:self enableHardwareDecodeDidChange:enableHardwareDecode];
            }
        });
    });
}

- (BOOL)isEnableHardwareDecode {
    __block BOOL isEnable = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *obj = [self.zgUserDefaults objectForKey:ZGPlayTopicConfigEnableHardwareDecodeKey];
        if (obj) {
            isEnable = [obj boolValue];
        } else {
            isEnable = NO;
        }
    });
    return isEnable;
}

@end

#endif
