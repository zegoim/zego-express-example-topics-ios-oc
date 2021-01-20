//
//  ZGSoundLevelViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Paaatrick on 2019/12/2.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGSoundLevelViewController.h"
#import "ZGSoundLevelTableViewCell.h"
#import "ZGUserIDHelper.h"
#import "ZGKeyCenter.h"
#import "ZegoLog.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

@interface ZGSoundLevelViewController () <ZegoEventHandler>

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *userName;

@property (nonatomic, copy) NSString *localStreamID;

// Array of other streams in the room
@property (nonatomic, strong) NSMutableArray<ZegoStream *> *remoteStreamList;

@end

@implementation ZGSoundLevelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.roomID = @"SoundLevelRoom-1";
    self.userID = [ZGUserIDHelper userID];
    self.userName = [ZGUserIDHelper userName];
    self.remoteStreamList = [NSMutableArray array];
    [self setupUI];
    [self startLive];
}

- (void)setupUI {
    self.title = [NSString stringWithFormat:@"%@", self.roomID];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZGSoundLevelTableViewCell" bundle:nil] forCellReuseIdentifier:@"ZGSoundLevelTableViewCell"];
    self.tableView.separatorStyle = UITableViewCellEditingStyleNone;
}

- (void)startLive {
    ZGLogInfo(@" 🚀 Create ZegoExpressEngine");

    unsigned int appID = [ZGKeyCenter appID];
    NSString *appSign = [ZGKeyCenter appSign];
    BOOL isTestEnv = YES;

    [ZegoExpressEngine createEngineWithAppID:appID appSign:appSign isTestEnv:isTestEnv scenario:ZegoScenarioGeneral eventHandler:self];
    
    ZegoUser *user = [ZegoUser userWithUserID:self.userID userName:self.userName];
    
    ZegoRoomConfig *roomConfig = [ZegoRoomConfig defaultConfig];
    
    ZGLogInfo(@" 🚪 Login room. roomID: %@", self.roomID);
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomID user:user config:roomConfig];
    
    // Use userID as streamID
    self.localStreamID = [NSString stringWithFormat:@"%@", user.userID];
        
    // Start publishing
    ZGLogInfo(@" 📤 Start publishing stream. streamID: %@", self.localStreamID);
    [[ZegoExpressEngine sharedEngine] startPublishingStream:self.localStreamID];
    
    // Start monitoring
    ZGLogInfo(@" 🎼 Start sound level monitor");
    [[ZegoExpressEngine sharedEngine] startSoundLevelMonitor];
    
    ZGLogInfo(@" 🎼 Start audio frequency spectrum monitor");
    [[ZegoExpressEngine sharedEngine] startAudioSpectrumMonitor];
}

#pragma mark Streams Update Callback

// Refresh the remote streams list
- (void)onRoomStreamUpdate:(ZegoUpdateType)updateType streamList:(NSArray<ZegoStream *> *)streamList extendedData:(NSDictionary *)extendedData roomID:(NSString *)roomID {
    ZGLogInfo(@" 🚩 🌊 Room Stream Update Callback: %lu, StreamsCount: %lu, roomID: %@", (unsigned long)updateType, (unsigned long)streamList.count, roomID);
    
    if (updateType == ZegoUpdateTypeAdd) {
        for (ZegoStream *stream in streamList) {
            ZGLogInfo(@" 🚩 🌊 --- [Add] StreamID: %@, UserID: %@", stream.streamID, stream.user.userID);
            if (![self.remoteStreamList containsObject:stream]) {
                [self.remoteStreamList addObject:stream];
            }
            
            // Play remote stream without rendering
            ZGLogInfo(@" 📥 Start playing stream, streamID: %@", stream.streamID);
            [[ZegoExpressEngine sharedEngine] startPlayingStream:stream.streamID];
        }
    } else if (updateType == ZegoUpdateTypeDelete) {
        for (ZegoStream *stream in streamList) {
            ZGLogInfo(@" 🚩 🌊 --- [Delete] StreamID: %@, UserID: %@", stream.streamID, stream.user.userID);
            __block ZegoStream *delStream = nil;
            [self.remoteStreamList enumerateObjectsUsingBlock:^(ZegoStream * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.streamID isEqualToString:stream.streamID] && [obj.user.userID isEqualToString:stream.user.userID]) {
                    delStream = obj;
                    *stop = YES;
                }
            }];
            [self.remoteStreamList removeObject:delStream];
            
            // Stop playing the remote stream
            ZGLogInfo(@" 📥 Stop playing stream, streamID: %@", stream.streamID);
            [[ZegoExpressEngine sharedEngine] stopPlayingStream:stream.streamID];
        }
    }
    // Refresh tableview
    [self.tableView reloadData];
}

#pragma mark - Sound Level Callback

// Sound level callback for local stream
- (void)onCapturedSoundLevelUpdate:(NSNumber *)soundLevel {
    ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.soundLevel = soundLevel;
}

// Sound level callback for remote streams, key is stream ID, value is the sound level data corresponding to stream ID
- (void)onRemoteSoundLevelUpdate:(NSDictionary<NSString *,NSNumber *> *)soundLevels {
    NSInteger rowCount = [self.tableView numberOfRowsInSection:1];
    for (NSInteger row = 0; row < rowCount; row++) {
        ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
        if ([soundLevels objectForKey:cell.streamID]) {
            cell.soundLevel = soundLevels[cell.streamID];
        }
    }
}

#pragma mark - Frequency Spectrum Callback

// Audio frequency spectrum callback for local stream
- (void)onCapturedAudioSpectrumUpdate:(NSArray<NSNumber *> *)audioSpectrum {
    ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.spectrumList = audioSpectrum;
}

// Audio frequency spectrum callback for remote streams, key is stream ID, value is the spectrum data corresponding to stream ID
- (void)onRemoteAudioSpectrumUpdate:(NSDictionary<NSString *,NSArray<NSNumber *> *> *)audioSpectrums {
    NSInteger rowCount = [self.tableView numberOfRowsInSection:1];
    for (NSInteger row = 0; row < rowCount; row++) {
        ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
        if ([audioSpectrums objectForKey:cell.streamID]) {
            cell.spectrumList = audioSpectrums[cell.streamID];
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return self.remoteStreamList.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGSoundLevelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZGSoundLevelTableViewCell"];
    cell.userInteractionEnabled = NO;
    if (indexPath.section == 0) {
        cell.streamID = [NSString stringWithFormat:@"(Self) %@", self.localStreamID];
    } else {
        if (self.remoteStreamList.count > indexPath.row) {
            cell.streamID = self.remoteStreamList[indexPath.row].streamID;
        }
    }
    return cell;
}

#pragma mark - Exit

- (void)dealloc {
    ZGLogInfo(@" 🚪 Exit the room");
    [[ZegoExpressEngine sharedEngine] logoutRoom:self.roomID];
    
    // Can destroy the engine when you don't need audio and video calls
    ZGLogInfo(@" 🏳️ Destroy ZegoExpressEngine");
    [ZegoExpressEngine destroyEngine:nil];
}

@end
