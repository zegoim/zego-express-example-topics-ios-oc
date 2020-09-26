//
//  ZGScreenCaptureManager.h
//  ZegoExpressExample-iOS-OC-Broadcast
//
//  Created by Patrick Fu on 2020/9/21.
//  Copyright © 2020 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGScreenCaptureManager : NSObject

+ (instancetype)sharedManager;

- (void)startBroadcastWithAppGroup:(NSString *)appGroup;

- (void)stopBroadcast;

- (void)handleSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType;

@end

NS_ASSUME_NONNULL_END
