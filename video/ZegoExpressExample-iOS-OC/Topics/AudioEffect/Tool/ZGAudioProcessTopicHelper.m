//
//  ZGAudioProcessTopicHelper.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessTopicHelper.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>
#import "ZGAudioProcessTopicConfigManager.h"

@implementation ZGAudioProcessTopicConfigMode

+ (instancetype)modeWithModeValue:(NSNumber * _Nullable)modeValue modeName:(NSString *)modeName isCustom:(BOOL)isCustom {
    ZGAudioProcessTopicConfigMode *m = [[ZGAudioProcessTopicConfigMode alloc] init];
    m.modeValue = modeValue;
    m.modeName = modeName;
    m.isCustom = isCustom;
    return m;
}

@end

@implementation ZGAudioProcessTopicHelper

+ (NSArray<ZGAudioProcessTopicConfigMode*>*)voiceChangerOptionModes {
    static dispatch_once_t onceToken;
    static NSArray<ZGAudioProcessTopicConfigMode*> *_voiceChangerOptionModes = nil;
    dispatch_once(&onceToken, ^{
        /*
         /// 变声器参数
         ///
         /// 开发者可以使用SDK的内置预置来改变变声器的参数。
         @interface ZegoVoiceChangerParam : NSObject

         /// 音调参数，取值范围 [-8.0, 8.0], 注意：变声音效只针对采集的声音有效。
         @property float pitch;

         @end


         /// 音频混响参数
         ///
         /// 开发者可以使用SDK的内置预置来改变混响的参数。
         @interface ZegoReverbParam : NSObject

         /// 混响阻尼，取值范围[0.0， 2.0]，控制混响的衰减程度，阻尼越大，衰减越大
         @property float damping;

         /// 干湿比，取值范围 大于等于 0.0。 控制混响与直达声和早期反射声之间的比 例，干(dry)的部分默认定为1，当干湿比设为较小时，湿(wet)的比例较大，此时混响较强
         @property float dryWetRatio;

         /// 余响，取值范围[0.0, 0.5]，用于控制混响的拖尾长度
         @property float reverberance;

         /// 房间大小，取值范围[0.0, 1.0]，用于控制产生混响“房间”的大小，房间越 大，混响越强
         @property float roomSize;

         @end
         **/
//        [[ZegoExpressEngine sharedEngine] setVoiceChangerParam:(nonnull ZegoVoiceChangerParam *)]
        ZegoVoiceChangerParam;
        _voiceChangerOptionModes =
        @[[ZGAudioProcessTopicConfigMode modeWithModeValue:@(EXPRESS_API_VOICE_CHANGER_WOMEN_TO_MEN) modeName:@"女声变男声" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(EXPRESS_API_VOICE_CHANGER_MEN_TO_WOMEN) modeName:@"男声变女声" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(EXPRESS_API_VOICE_CHANGER_WOMEN_TO_CHILD) modeName:@"女声变童声" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(EXPRESS_API_VOICE_CHANGER_MEN_TO_CHILD) modeName:@"男声变童声" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:nil modeName:@"自定义" isCustom:YES]];
    });
    return _voiceChangerOptionModes;
}

+ (NSArray<ZGAudioProcessTopicConfigMode*>*)reverbOptionModes {
    static dispatch_once_t onceToken;
    static NSArray<ZGAudioProcessTopicConfigMode*> *_reverbOptionModes = nil;
    dispatch_once(&onceToken, ^{
        _reverbOptionModes =
        @[[ZGAudioProcessTopicConfigMode modeWithModeValue:@(ExpressAPIAudioReverbModeConcertHall) modeName:@"音乐厅" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(ExpressAPIAudioReverbModeLargeAuditorium) modeName:@"大教堂" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(ExpressAPIAudioReverbModeWarmClub) modeName:@"俱乐部" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(ExpressAPIAudioReverbModeSoftRoom) modeName:@"房间" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:nil modeName:@"自定义" isCustom:YES]];
    });
    return _reverbOptionModes;
}

@end
#endif
