//
//  ZGAudioPreprocessTopicHelper.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioPreprocess

#import "ZGAudioPreprocessTopicHelper.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>
#import "ZGAudioPreprocessTopicConfigManager.h"

@implementation ZGAudioPreprocessTopicConfigMode

+ (instancetype)modeWithModeValue:(NSNumber * _Nullable)modeValue modeName:(NSString *)modeName isCustom:(BOOL)isCustom {
    ZGAudioPreprocessTopicConfigMode *m = [[ZGAudioPreprocessTopicConfigMode alloc] init];
    m.modeValue = modeValue;
    m.modeName = modeName;
    m.isCustom = isCustom;
    return m;
}

@end

@implementation ZGAudioPreprocessTopicHelper

+ (NSArray<ZGAudioPreprocessTopicConfigMode*>*)voiceChangerOptionModes {
    static dispatch_once_t onceToken;
    static NSArray<ZGAudioPreprocessTopicConfigMode*> *_voiceChangerOptionModes = nil;
    dispatch_once(&onceToken, ^{
        _voiceChangerOptionModes =
        @[[ZGAudioPreprocessTopicConfigMode modeWithModeValue:@(EXPRESS_API_VOICE_CHANGER_WOMEN_TO_MEN) modeName:@"Women->Men" isCustom:NO],
          [ZGAudioPreprocessTopicConfigMode modeWithModeValue:@(EXPRESS_API_VOICE_CHANGER_MEN_TO_WOMEN) modeName:@"Men->Women" isCustom:NO],
          [ZGAudioPreprocessTopicConfigMode modeWithModeValue:@(EXPRESS_API_VOICE_CHANGER_WOMEN_TO_CHILD) modeName:@"Women->Child" isCustom:NO],
          [ZGAudioPreprocessTopicConfigMode modeWithModeValue:@(EXPRESS_API_VOICE_CHANGER_MEN_TO_CHILD) modeName:@"Men->Child" isCustom:NO],
          [ZGAudioPreprocessTopicConfigMode modeWithModeValue:nil modeName:@"Custom" isCustom:YES]];
    });
    return _voiceChangerOptionModes;
}

+ (NSArray<ZGAudioPreprocessTopicConfigMode*>*)reverbOptionModes {
    static dispatch_once_t onceToken;
    static NSArray<ZGAudioPreprocessTopicConfigMode*> *_reverbOptionModes = nil;
    dispatch_once(&onceToken, ^{
        _reverbOptionModes =
        @[[ZGAudioPreprocessTopicConfigMode modeWithModeValue:@(ExpressAPIAudioReverbModeConcertHall) modeName:@"ConcertHall" isCustom:NO],
          [ZGAudioPreprocessTopicConfigMode modeWithModeValue:@(ExpressAPIAudioReverbModeLargeRoom) modeName:@"LargeRoom" isCustom:NO],
          [ZGAudioPreprocessTopicConfigMode modeWithModeValue:@(ExpressAPIAudioReverbModeSoftRoom) modeName:@"SoftRoom" isCustom:NO],
          [ZGAudioPreprocessTopicConfigMode modeWithModeValue:@(ExpressAPIAudioReverbModeValley) modeName:@"Valley" isCustom:NO],
          [ZGAudioPreprocessTopicConfigMode modeWithModeValue:nil modeName:@"Custom" isCustom:YES]];
    });
    return _reverbOptionModes;
}

@end
#endif
