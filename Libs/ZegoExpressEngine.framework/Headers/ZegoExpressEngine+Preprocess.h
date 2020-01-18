//
//  ZegoExpressEngine+Preprocess.h
//  ZegoExpressEngine
//
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZegoExpressEngine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZegoExpressEngine (Preprocess)

/// On/off echo cancellation
/// @discussion Turning on echo cancellation, the SDK filters the collected audio data to reduce the echo component in the audio. It needs to be set before starting the push, and the setting is invalid after the start of the push.
/// @param enable  Whether to enable echo cancellation, NO means to turn off echo cancellation, YES means to enable echo cancellation
- (void)enableAEC:(BOOL)enable;

/// Set echo cancellation mode
/// @discussion Switch different echo cancellation modes to control the extent to which echo data is eliminated. Need to be set before starting the push.
/// @param mode  Echo cancellation mode
- (void)setAECMode:(ZegoAECMode)mode;

/// On/off automatic gain
/// @discussion When the auto gain is turned on, the sound will be amplified, but it will affect the sound quality to some extent. Need to be set before starting the push.
/// @param enable Whether to enable automatic gain, NO means to turn off automatic gain, YES means to turn on automatic gain
- (void)enableAGC:(BOOL)enable;

/// On/off noise suppression
/// @discussion Turning on the noise suppression switch can reduce the noise in the audio data and make the human voice clearer. Need to be set before starting the push.
/// @param enable  Whether to enable noise suppression, NO means to turn off noise suppression, YES means to turn on noise suppression
- (void)enableANS:(BOOL)enable;

/// On/off beauty
/// @discussion Identify the portraits in the video for beauty. It can be set before and after the start of the push.
/// @param featureBitmask Bit mask format, you can choose to enable several features in ZegoBeautifyFeature at the same time
- (void)enableBeautify:(ZegoBeautifyFeature)featureBitmask;

/// Set beauty parameters
/// @param option Beauty configuration options
- (void)setBeautifyOption:(ZegoBeautifyOption *)option;

@end

NS_ASSUME_NONNULL_END