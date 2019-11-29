//
//  ZGVideoTalkManager.h
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2019/10/30.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZegoExpressEngine/ZegoExpressEngine.h>

NS_ASSUME_NONNULL_BEGIN


@class ZGVideoTalkDemo;

@protocol ZGVideoTalkDataSource <NSObject>

@required

/// Get the publish stream ID of a local user
/// @return Stream ID of local user
- (NSString *)localUserJoinTalkStreamID;

/// Get a preview view of a local user
/// @return Preview view of local user
- (UIView *)localUserPreviewView;

/// Get the play view of a remote user
/// @param userID Remote user's userID
/// @return Remote user's play view
- (UIView *)playViewForRemoteUserWithID:(NSString *)userID;

@end

@protocol ZGVideoTalkDelegate <NSObject>

@required

/// Local user joins the room state change event.
- (void)onLocalUserJoinRoomStateUpdated:(ZegoRoomState)state roomID:(NSString *)roomID;

/// Remote user joins the chat room event.
- (void)onRemoteUserDidJoinTalkInRoom:(NSString *)talkRoomID userIDs:(NSArray<NSString *> *)userIDs;

/// Remote user leaves the chat room event.
- (void)onRemoteUserDidLeaveTalkInRoom:(NSString *)talkRoomID userIDs:(NSArray<NSString *> *)userIDs;

/// Remote user state change event.
/// @param stateCode Indicates an error has occurred when stateCode != 0.
/// @param userID Remote user ID
- (void)onRemoteUserVideoStateUpdate:(int)stateCode userID:(NSString *)userID;

@end

@interface ZGVideoTalkManager : NSObject

/// Whether to enable the camera
@property (nonatomic, assign) BOOL enableCamera;

/// Whether to enable the microphone
@property (nonatomic, assign) BOOL enableMicrophone;

/// Whether to enable audio output
@property (nonatomic, assign) BOOL enableAudioOutput;

/// Room login state
@property (nonatomic, readonly) ZegoRoomState roomState;

/// Login room ID
@property (nonatomic, readonly) NSString *talkRoomID;

/// DataSource
@property (nonatomic, weak) id<ZGVideoTalkDataSource> dataSource;

/// Delegate
@property (nonatomic, weak) id<ZGVideoTalkDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;

/// Initialize ZGVideoTalkManager instance
- (instancetype)initWithAppID:(unsigned int)appID appSign:(NSString *)appSign;

/// Join video chat room
- (void)joinTalkRoom:(NSString *)roomID userID:(NSString *)userID;

/// Leave the char room and free resources
- (void)exitRoom;


@end

NS_ASSUME_NONNULL_END
