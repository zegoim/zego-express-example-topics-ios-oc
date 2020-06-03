//
//  ZGPlayTopicConfigManager.h
//  ZegoExpressExample-iOS-OC
//
//  Created by jeffreypeng on 2019/8/12.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Play

#import <Foundation/Foundation.h>
#import <ZegoExpressEngine/ZegoExpressEngine.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGPlayTopicConfigManager;

/// Play stream topic setting change handler protocol
@protocol ZGPlayTopicConfigChangedHandler <NSObject>
@optional

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager playViewModeDidChange:(ZegoViewMode)playViewMode;

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager playStreamVolumeDidChange:(int)playStreamVolume;

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager enableHardwareDecodeDidChange:(BOOL)enableHardwareDecode;

@end

/// Play stream topic setting manager
/// @discussion By implementing `ZGPlayTopicConfigChangedHandler` protocol and adding it to the manager, you can receive the play settings update event for the play stream topic.
@interface ZGPlayTopicConfigManager : NSObject

+ (instancetype)sharedManager;

- (void)setConfigChangedHandler:(id<ZGPlayTopicConfigChangedHandler>)handler;

- (void)setPlayViewMode:(ZegoViewMode)playViewMode;

- (ZegoViewMode)playViewMode;

- (void)setPlayStreamVolume:(int)playStreamVolume;

- (int)playStreamVolume;

- (void)setEnableHardwareDecode:(BOOL)enableHardwareDecode;

- (BOOL)isEnableHardwareDecode;

@end

NS_ASSUME_NONNULL_END

#endif
