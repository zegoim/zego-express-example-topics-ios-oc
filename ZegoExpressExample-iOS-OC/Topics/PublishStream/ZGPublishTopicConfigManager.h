//
//  ZGPublishTopicConfigManager.h
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2019/10/25.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import <Foundation/Foundation.h>
#import <ZegoExpressEngine/ZegoExpressEngine.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGPublishTopicConfigManager;


/// Publish stream topic setting change handler protocol
@protocol ZGPublishTopicConfigChangedHandler <NSObject>
@optional

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager resolutionDidChange:(CGSize)resolution;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager fpsDidChange:(NSInteger)fps;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager bitrateDidChange:(NSInteger)bitrate;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager previewViewModeDidChange:(ZegoViewMode)previewViewMode;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager streamExtraInfoDidChange:(NSString *)extraInfo;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager enableHardwareEncodeDidChange:(BOOL)enableHardwareEncode;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager mirrorModeDidChange:(ZegoVideoMirrorMode)mirrorMode;

@end

/// Publish stream topic setting manager
/// @discussion By implementing `ZGPublishTopicConfigChangedHandler` protocol and adding it to the manager, you can receive the publish settings update event for the publish stream topic.
@interface ZGPublishTopicConfigManager : NSObject

+ (instancetype)sharedManager;

- (void)setConfigChangedHandler:(id<ZGPublishTopicConfigChangedHandler>)handler;

- (void)setResolution:(CGSize)resolution;

- (CGSize)resolution;

- (void)setFps:(NSInteger)fps;

- (NSInteger)fps;

- (void)setBitrate:(NSInteger)bitrate;

- (NSInteger)bitrate;

- (void)setPreviewViewMode:(ZegoViewMode)previewViewMode;

- (ZegoViewMode)previewViewMode;

- (void)setStreamExtraInfo:(NSString *)extraInfo;

- (NSString *)streamExtraInfo;

- (void)setEnableHardwareEncode:(BOOL)enableHardwareEncode;

- (BOOL)isEnableHardwareEncode;

- (void)setMirrorMode:(ZegoVideoMirrorMode)mirrorMode;

- (ZegoVideoMirrorMode)mirrorMode;

@end


NS_ASSUME_NONNULL_END

#endif
