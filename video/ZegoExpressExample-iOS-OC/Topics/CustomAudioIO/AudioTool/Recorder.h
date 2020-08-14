//
//  Recorder.h
//  ZegoExpressExample-iOS-OC
//
//  Created by zego on 2020/7/20.
//  Copyright © 2020 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

@class Recorder;

typedef void (^XBAudioUnitPlayerOutputBlock)(Recorder * _Nonnull player, AudioUnitRenderActionFlags * _Nonnull ioActionFlags, const AudioTimeStamp * _Nonnull inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList * _Nonnull ioData);

NS_ASSUME_NONNULL_BEGIN

@interface Recorder : NSObject

@property (nonatomic,copy) XBAudioUnitPlayerOutputBlock bl_output;

- (instancetype)initWithSampleRate:(Float64)sampleRate bufferSize:(int)bufferSize;

- (void)start;

- (void)stop;
@end

NS_ASSUME_NONNULL_END
