//
//  ZGAudioPreprocessTopicConfigManager.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioPreprocess

#import "ZGAudioPreprocessTopicConfigManager.h"
#import "ZGHashTableHelper.h"

NSString* const ZGAudioPreprocessTopicConfigVoiceChangerOpenKey = @"ZGAudioPreprocessTopicConfigVoiceChangerOpenKey";
NSString* const ZGAudioPreprocessTopicConfigVoiceChangerParamKey = @"ZGAudioPreprocessTopicConfigVoiceChangerParamKey";

NSString* const ZGAudioPreprocessTopicConfigVirtualStereoOpenKey = @"ZGAudioPreprocessTopicConfigVirtualStereoOpenKey";
NSString* const ZGAudioPreprocessTopicConfigVirtualStereoAngleKey = @"ZGAudioPreprocessTopicConfigVirtualStereoAngleKey";

NSString* const ZGAudioPreprocessTopicConfigReverbOpenKey = @"ZGAudioPreprocessTopicConfigReverbOpenKey";
NSString* const ZGAudioPreprocessTopicConfigReverbModeKey = @"ZGAudioPreprocessTopicConfigReverbModeKey";
NSString* const ZGAudioPreprocessTopicConfigCustomReverbRoomSizeKey = @"ZGAudioPreprocessTopicConfigCustomReverbRoomSizeKey";
NSString* const ZGAudioPreprocessTopicConfigCustomDryWetRatioKey = @"ZGAudioPreprocessTopicConfigCustomDryWetRatioKey";
NSString* const ZGAudioPreprocessTopicConfigCustomDampingKey = @"ZGAudioPreprocessTopicConfigCustomDampingKey";
NSString* const ZGAudioPreprocessTopicConfigCustomReverberanceKey = @"ZGAudioPreprocessTopicConfigCustomReverberanceKey";


@interface ZGAudioPreprocessTopicConfigManager ()
{
    dispatch_queue_t _configOptQueue;
}

@property (nonatomic) NSHashTable *configChangedHandlers;

@end

@implementation ZGAudioPreprocessTopicConfigManager

static ZGAudioPreprocessTopicConfigManager *instance = nil;

#pragma mark - public methods

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [ZGAudioPreprocessTopicConfigManager sharedInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [ZGAudioPreprocessTopicConfigManager sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        _configChangedHandlers = [ZGHashTableHelper createWeakReferenceHashTable];
        _configOptQueue = dispatch_queue_create("com.doudong.ZGAudioPreprocessTopicConfigOptQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)addConfigChangedHandler:(id<ZGAudioPreprocessTopicConfigChangedHandler>)handler {
    if (!handler) return;
    dispatch_async(_configOptQueue, ^{
        if (![self.configChangedHandlers containsObject:handler]) {
            [self.configChangedHandlers addObject:handler];
        }
    });
}

- (void)removeConfigChangedHandler:(id<ZGAudioPreprocessTopicConfigChangedHandler>)handler {
    if (!handler) return;
    dispatch_async(_configOptQueue, ^{
        [self.configChangedHandlers removeObject:handler];
    });
}

- (void)setVoiceChangerOpen:(BOOL)voiceChangerOpen {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(voiceChangerOpen);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigVoiceChangerOpenKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:voiceChangerOpenChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self voiceChangerOpenChanged:voiceChangerOpen];
                }
            }
        });
    });
}

- (BOOL)voiceChangerOpen {
    __block BOOL isOpen = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigVoiceChangerOpenKey];
        if (n) {
            isOpen = [n boolValue];
        } else {
            // 设置默认
            isOpen = NO;
        }
    });
    return isOpen;
}

- (void)setVoiceChangerParam:(float)voiceChangerParam {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(voiceChangerParam);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigVoiceChangerParamKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:voiceChangerParamChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self voiceChangerParamChanged:voiceChangerParam];
                }
            }
        });
    });
}

- (float)voiceChangerParam {
    __block float val = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigVoiceChangerParamKey];
        if (n) {
            val = [n floatValue];
        } else {
            // 设置默认
            val = 0;
        }
    });
    return val;
}

- (void)setVirtualStereoOpen:(BOOL)virtualStereoOpen {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(virtualStereoOpen);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigVirtualStereoOpenKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:virtualStereoOpenChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self virtualStereoOpenChanged:virtualStereoOpen];
                }
            }
        });
    });
}

- (BOOL)virtualStereoOpen {
    __block BOOL isOpen = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigVirtualStereoOpenKey];
        if (n) {
            isOpen = [n boolValue];
        } else {
            // 设置默认
            isOpen = NO;
        }
    });
    return isOpen;
}

- (void)setVirtualStereoAngle:(int)angle {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(angle);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigVirtualStereoAngleKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:virtualStereoAngleChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self virtualStereoAngleChanged:angle];
                }
            }
        });
    });
}

- (int)virtualStereoAngle {
    __block int val = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigVirtualStereoAngleKey];
        if (n) {
            val = [n intValue];
        } else {
            // 设置默认
            val = 0;
        }
    });
    return val;
}

- (void)setReverbOpen:(BOOL)reverbOpen {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(reverbOpen);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigReverbOpenKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:reverbOpenChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self reverbOpenChanged:reverbOpen];
                }
            }
        });
    });
}

- (BOOL)reverbOpen {
    __block BOOL isOpen = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigReverbOpenKey];
        if (n) {
            isOpen = [n boolValue];
        } else {
            // 设置默认
            isOpen = NO;
        }
    });
    return isOpen;
}

- (void)setReverbMode:(NSUInteger)reverbMode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(reverbMode);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigReverbModeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:reverbModeChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self reverbModeChanged:reverbMode];
                }
            }
        });
    });
}

- (NSUInteger)reverbMode {
    __block NSUInteger val = NSNotFound;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigReverbModeKey];
        if (n) {
            val = [n unsignedIntegerValue];
        } else {
            // 设置默认
            val = NSNotFound;
        }
    });
    return val;
}

- (void)setCustomReverbRoomSize:(float)roomSize {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(roomSize);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigCustomReverbRoomSizeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:customReverbRoomSizeChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self customReverbRoomSizeChanged:roomSize];
                }
            }
        });
    });
}

- (float)customReverbRoomSize {
    __block float val = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigCustomReverbRoomSizeKey];
        if (n) {
            val = [n floatValue];
        } else {
            // 设置默认
            val = 0;
        }
    });
    return val;
}

- (void)setCustomDryWetRatio:(float)dryWetRatio {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(dryWetRatio);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigCustomDryWetRatioKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:customDryWetRatioChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self customDryWetRatioChanged:dryWetRatio];
                }
            }
        });
    });
}

- (float)customDryWetRatio {
    __block float val = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigCustomDryWetRatioKey];
        if (n) {
            val = [n floatValue];
        } else {
            // 设置默认
            val = 0;
        }
    });
    return val;
}

- (void)setCustomDamping:(float)damping {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(damping);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigCustomDampingKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:customDampingChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self customDampingChanged:damping];
                }
            }
        });
    });
}

- (float)customDamping {
    __block float val = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigCustomDampingKey];
        if (n) {
            val = [n floatValue];
        } else {
            // 设置默认
            val = 0;
        }
    });
    return val;
}

- (void)setCustomReverberance:(float)reverberance {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(reverberance);
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:ZGAudioPreprocessTopicConfigCustomReverberanceKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioPreprocessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioPreprocessTopicConfigManager:customReverberanceChanged:)]) {
                    [handler audioPreprocessTopicConfigManager:self customReverberanceChanged:reverberance];
                }
            }
        });
    });
}

- (float)customReverberance {
    __block float val = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:ZGAudioPreprocessTopicConfigCustomReverberanceKey];
        if (n) {
            val = [n floatValue];
        } else {
            // 设置默认
            val = 0;
        }
    });
    return val;
}

@end
#endif
