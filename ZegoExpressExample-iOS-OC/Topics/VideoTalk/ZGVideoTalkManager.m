//
//  ZGVideoTalkManager.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2019/10/30.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGVideoTalkManager.h"

@interface ZGVideoTalkManager () <ZegoEventHandler>

@property (nonatomic, assign) ZegoRoomState roomState;
@property (nonatomic, copy) NSString *talkRoomID;

@property (nonatomic, strong) NSMutableArray<ZegoStream *> *remoteUserStreams;

@property (nonatomic, strong) ZegoExpressEngine *engine;

@end

@implementation ZGVideoTalkManager

#pragma mark - Public Methods

/// Initialize ZGVideoTalkManager instance
- (instancetype)initWithAppID:(unsigned int)appID appSign:(NSString *)appSign {
    self = [super init];
    if (self) {
        self.remoteUserStreams = [NSMutableArray<ZegoStream *> array];
        
        ZGLogInfo(@" 🚀 Initialize the ZegoExpressEngine");
        self.engine = [ZegoExpressEngine createEngineWithAppID:appID appSign:appSign isTestEnv:YES scenario:ZegoScenarioGeneral eventHandler:self];
        
        // Set debug verbose on
//        [self.engine setDebugVerbose:YES language:ZegoLanguageEnglish];
    }
    return self;
}


- (void)joinTalkRoom:(NSString *)roomID userID:(NSString *)userID {
    // Login room
    self.talkRoomID = roomID;
    ZGLogInfo(@" 🚪 Login room");
    [self.engine loginRoom:roomID user:[ZegoUser userWithUserID:userID] config:nil];
    
    // Get stream ID
    NSString *streamID = [self.dataSource localUserJoinTalkStreamID];
    if (streamID.length == 0) {
        ZGLogWarn(@" ❗️ Join talk room fail, data source does not provide streamID.");
        return;
    }
    
    // Set the publish video configuration
    [self.engine setVideoConfig:[ZegoVideoConfig configWithResolution:ZegoResolution720x1280]];
    
    // Get the local user's preview view and start preview
    UIView *previewView = [self.dataSource localUserPreviewView];
    ZGLogInfo(@" 🔌 Start preview");
    [self.engine startPreview:[ZegoCanvas canvasWithView:previewView viewMode:ZegoViewModeAspectFit]];
    
    // Local user start publishing
    ZGLogInfo(@" 📤 Start publishing stream");
    [self.engine startPublishing:streamID];
}

// It is recommended to stop publishing and logour room when stopping the video call.
// And you can destroy the engine when there is no need to call.
- (void)exitRoom {
    ZGLogInfo(@" 🔌 Stop preview");
    [self.engine stopPreview];
    ZGLogInfo(@" 📤 Stop publishing stream");
    [self.engine stopPublishing];
    ZGLogInfo(@" 🚪 Logout room");
    [self.engine logoutRoom:self.talkRoomID];
    ZGLogInfo(@" 🏳️ Destroy the ZegoExpressEngine");
    [ZegoExpressEngine destroyEngine];
}

#pragma mark - Setter

- (void)setEnableCamera:(BOOL)enableCamera {
    [self.engine enableCamera:enableCamera];
    _enableCamera = enableCamera;
}

- (void)setEnableMicrophone:(BOOL)enableMicrophone {
    [self.engine enableMicrophone:enableMicrophone];
    _enableMicrophone = enableMicrophone;
}

- (void)setEnableAudioOutput:(BOOL)enableAudioOutput {
    [self.engine muteAudioOutput:!enableAudioOutput];
    _enableAudioOutput = enableAudioOutput;
}

#pragma mark - Private Methods

- (void)internalStartPlayRemoteUserTalkWithUserID:(NSString *)userID {
    // Get th play view and start playing stream
    UIView *playView = [self.dataSource playViewForRemoteUserWithID:userID];
    
    ZegoStream *existStream = [self getTalkStreamInCurrentListWithUserID:userID];
    if (existStream) {
        [self.engine startPlayingStream:existStream.streamID canvas:[ZegoCanvas canvasWithView:playView viewMode:ZegoViewModeAspectFit]];
    }
}

- (void)addRemoteUserTalkStreams:(NSArray<ZegoStream *> *)streams {
    if (streams == nil) {
        return;
    }
    
    // Add a stream
    for (ZegoStream *stream in streams) {
        [self.remoteUserStreams addObject:stream];
    }
    
    NSMutableArray<NSString *> *addUserIDs = [NSMutableArray array];
    for (ZegoStream *stream in streams) {
        [addUserIDs addObject:stream.user.userID];
    }
    
    if ([self.delegate respondsToSelector:@selector(onRemoteUserDidJoinTalkInRoom:userIDs:)]) {
        [self.delegate onRemoteUserDidJoinTalkInRoom:self.talkRoomID userIDs:addUserIDs];
    }
    
    // Start playing stream
    for (NSString *userID in addUserIDs) {
        [self internalStartPlayRemoteUserTalkWithUserID:userID];
    }
}

- (void)removeRemoteUserTalkStreamWithIDs:(NSArray<NSString *> *)streamIDs {
    if (streamIDs == nil) {
        return;
    }
    
    // Remove exist stream
    NSMutableArray<ZegoStream*> *rmStreams = [NSMutableArray array];
    for (NSString *streamID in streamIDs) {
        ZegoStream *existObj = [self getTalkStreamInCurrentListWithStreamID:streamID];
        if (existObj) {
            [self.remoteUserStreams removeObject:existObj];
            [rmStreams addObject:existObj];
        }
        // Stop playing stream
        [self.engine stopPlayingStream:streamID];
    }
    
    NSMutableArray<NSString *> *rmUserIDs = [NSMutableArray array];
    for (ZegoStream *stream in rmStreams) {
        [rmUserIDs addObject:stream.user.userID];
    }
    if (rmUserIDs.count > 0) {
        if ([self.delegate respondsToSelector:@selector(onRemoteUserDidLeaveTalkInRoom:userIDs:)]) {
            [self.delegate onRemoteUserDidLeaveTalkInRoom:self.talkRoomID userIDs:rmUserIDs];
        }
    }
}

- (ZegoStream *)getTalkStreamInCurrentListWithUserID:(NSString *)userID {
    __block ZegoStream *existStream = nil;
    [self.remoteUserStreams enumerateObjectsUsingBlock:^(ZegoStream * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ZegoUser *user = obj.user;
        if ([user.userID isEqualToString:userID]) {
            existStream = obj;
            *stop = YES;
        }
    }];
    return existStream;
}

- (ZegoStream *)getTalkStreamInCurrentListWithStreamID:(NSString *)streamID {
    __block ZegoStream *existStream = nil;
    [self.remoteUserStreams enumerateObjectsUsingBlock:^(ZegoStream * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.streamID isEqualToString:streamID]) {
            existStream = obj;
            *stop = YES;
        }
    }];
    return existStream;
}

#pragma mark - ZegoExpress Room Event

/// Room state update callback.
- (void)onRoomStateUpdate:(ZegoRoomState)state errorCode:(int)errorCode room:(NSString *)roomID {
    ZGLogInfo(@" 🚪 Room State Changed: %lu，Room ID:%@", (unsigned long)state, roomID);
    self.roomState = state;
    if ([self.delegate respondsToSelector:@selector(onLocalUserJoinRoomStateUpdated:roomID:)]) {
        [self.delegate onLocalUserJoinRoomStateUpdated:state roomID:roomID];
    }
}

/// Room stream update, add or delete a stream to the room will trigger this callback.
- (void)onRoomStreamUpdate:(ZegoUpdateType)updateType streamList:(NSArray<ZegoStream *> *)streamList room:(NSString *)roomID {
    BOOL isTypeAdd = updateType == ZegoUpdateTypeAdd;
    
    for (ZegoStream *stream in streamList) {
        ZGLogInfo(@" %@ Stream: %@, Room ID: %@", isTypeAdd ? @"➕ Add":@"➖ Delete", stream.streamID, roomID);
    }
    
    if (isTypeAdd) {
        [self addRemoteUserTalkStreams:streamList];
    } else {
        NSArray<NSString *> *streamIDs = [streamList valueForKeyPath:@"streamID"];
        [self removeRemoteUserTalkStreamWithIDs:streamIDs];
    }
}


#pragma mark - ZegoExpress Play Event

- (void)onPlayerStateUpdate:(ZegoPlayerState)state errorCode:(int)errorCode stream:(NSString *)streamID {
    if (errorCode != 0) {
        ZGLogError(@" ❗️ Play Stream Error, streamID: %@ errorCode: %d", streamID, errorCode);
    } else if (state == ZegoPlayerStatePlaying && errorCode == 0) {
        ZGLogInfo(@" 📥 Playing Stream ID: %@", streamID);
    }
    
    ZegoStream *existStream = [self getTalkStreamInCurrentListWithStreamID:streamID];
    if (existStream &&
        [self.delegate respondsToSelector:@selector(onRemoteUserVideoStateUpdate:userID:)]) {
        [self.delegate onRemoteUserVideoStateUpdate:errorCode userID:existStream.user.userID];
    }
}


@end
