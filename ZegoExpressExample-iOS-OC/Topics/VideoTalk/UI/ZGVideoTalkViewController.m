//
//  ZGVideoTalkViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2019/10/30.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_VideoTalk

#import "ZGVideoTalkViewController.h"
#import "ZGVideoTalkManager.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGUserIDHelper.h"

// The number of displays per row of the stream view
NSInteger const ZGVideoTalkStreamViewColumnPerRow = 3;
// Stream view spacing
CGFloat const ZGVideoTalkStreamViewSpacing = 8.f;


@interface ZGVideoTalkUserVideoViewObject : NSObject

@property (nonatomic, assign) BOOL isLocalUser;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, strong) UIView *videoView;

@end

@implementation ZGVideoTalkUserVideoViewObject
@end


@interface ZGVideoTalkViewController () <ZGVideoTalkDelegate, ZGVideoTalkDataSource>

@property (weak, nonatomic) IBOutlet UISwitch *cameraSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *microphoneSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *audioOutputSwitch;

@property (nonatomic, weak) IBOutlet UIView *talkUserContainerView;

// Video view of participating video call users
@property (nonatomic, strong) NSMutableArray<ZGVideoTalkUserVideoViewObject *> *joinUserVideoViewObjs;

@property (nonatomic, copy) NSString *joinTalkUserID;
@property (nonatomic, copy) NSString *joinTalkStreamID;

@property (nonatomic, strong) ZGVideoTalkManager *manager;

@end

@implementation ZGVideoTalkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get the userID and userName
    self.joinTalkUserID = ZGUserIDHelper.userID;
    self.joinTalkStreamID = [NSString stringWithFormat:@"s-%@", self.joinTalkUserID];
    self.joinUserVideoViewObjs = [NSMutableArray<ZGVideoTalkUserVideoViewObject *> array];
    
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];
    self.manager = [[ZGVideoTalkManager alloc] initWithAppID:appConfig.appID appSign:appConfig.appSign];
    self.manager.enableCamera = YES;
    self.manager.enableMicrophone = YES;
    self.manager.enableAudioOutput = YES;
    
    [self.manager setDataSource:self];
    [self.manager setDelegate:self];
    
    [self setupUI];
    
    // Join talk room
    [self.manager joinTalkRoom:self.roomID userID:self.joinTalkUserID];
}


#pragma mark - Actions

- (IBAction)onToggleCameraSwitch:(UISwitch *)sender {
    self.manager.enableCamera = sender.on;
}

- (IBAction)onToggleMicrophoneSwitch:(UISwitch *)sender {
    self.manager.enableMicrophone = sender.on;
}

- (IBAction)onToggleEnableAudioOutputSwitch:(UISwitch *)sender {
    self.manager.enableAudioOutput = sender.on;
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.isBeingDismissed || self.isMovingFromParentViewController
        || (self.navigationController && self.navigationController.isBeingDismissed)) {
        [self.manager exitRoom];
    }
    [super viewDidDisappear:animated];
}

#pragma mark - UI

- (void)setupUI {
    self.cameraSwitch.on = self.manager.enableCamera;
    self.microphoneSwitch.on = self.manager.enableMicrophone;
    self.audioOutputSwitch.on = self.manager.enableAudioOutput;
    [self invalidateJoinTalkStateDisplay];
    
    // Add local user video view object
    [self addLocalUserVideoViewObject];
    [self rearrangeJoinUserVideoViews];
}

- (void)invalidateJoinTalkStateDisplay {
    ZegoRoomState roomState = self.manager.roomState;
    NSString *stateTitle = nil;
    if (roomState == ZegoRoomStateConnected) {
        stateTitle = @"Joined";
    } else if (roomState == ZegoRoomStateDisconnected) {
        stateTitle = @"Not Joined";
    } else if (roomState == ZegoRoomStateConnecting) {
        stateTitle = @"Requesting to Join";
    }
    self.navigationItem.title = stateTitle;
}


- (void)rearrangeJoinUserVideoViews {
    // Rearrange participant flow view
    for (ZGVideoTalkUserVideoViewObject *obj in self.joinUserVideoViewObjs) {
        if (obj.videoView != nil) {
            [obj.videoView removeFromSuperview];
        }
    }
    
    NSInteger columnPerRow = ZGVideoTalkStreamViewColumnPerRow;
    CGFloat viewSpacing = ZGVideoTalkStreamViewSpacing;
    CGFloat screenWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    CGFloat playViewWidth = (screenWidth - (columnPerRow + 1)*viewSpacing) /columnPerRow;
    CGFloat playViewHeight = 1.5f * playViewWidth;
    
    NSInteger i = 0;
    for (ZGVideoTalkUserVideoViewObject *obj in self.joinUserVideoViewObjs) {
        if (obj.videoView == nil) {
            continue;
        }
        
        NSInteger cloumn = i % columnPerRow;
        NSInteger row = i / columnPerRow;
        
        CGFloat x = viewSpacing + cloumn * (playViewWidth + viewSpacing);
        CGFloat y = viewSpacing + row * (playViewHeight + viewSpacing);
        obj.videoView.frame = CGRectMake(x, y, playViewWidth, playViewHeight);
        
        [self.talkUserContainerView addSubview:obj.videoView];
        i++;
    }
}

#pragma mark - VideoViewObject Methods

- (ZGVideoTalkUserVideoViewObject *)addLocalUserVideoViewObject {
    UIView *view = [UIView new];
    ZGVideoTalkUserVideoViewObject *localVVObj = [ZGVideoTalkUserVideoViewObject new];
    localVVObj.isLocalUser = YES;
    localVVObj.userID = self.joinTalkUserID;
    localVVObj.videoView = view;
    
    [self.joinUserVideoViewObjs addObject:localVVObj];
    return localVVObj;
}

- (ZGVideoTalkUserVideoViewObject *)getLocalUserVideoViewObject {
    ZGVideoTalkUserVideoViewObject *localUserObj = nil;
    for (ZGVideoTalkUserVideoViewObject *obj in self.joinUserVideoViewObjs) {
        if ([obj.userID isEqualToString:self.joinTalkUserID]) {
            localUserObj = obj;
            break;
        }
    }
    return localUserObj;
}

- (void)addRemoteUserVideoViewObjectIfNeedWithUserID:(NSString *)userID {
    if ([self getUserVideoViewObjectWithUserID:userID]) {
        return;
    }
    
    ZGVideoTalkUserVideoViewObject *vvObj = [ZGVideoTalkUserVideoViewObject new];
    vvObj.isLocalUser = NO;
    vvObj.userID = userID;
    vvObj.videoView = [UIView new];
    [self.joinUserVideoViewObjs addObject:vvObj];
}

- (void)removeUserVideoViewObjectWithUserID:(NSString *)userID {
    ZGVideoTalkUserVideoViewObject *obj = [self getUserVideoViewObjectWithUserID:userID];
    if (obj) {
        [self.joinUserVideoViewObjs removeObject:obj];
        [obj.videoView removeFromSuperview];
    }
}

- (ZGVideoTalkUserVideoViewObject *)getUserVideoViewObjectWithUserID:(NSString *)userID {
    __block ZGVideoTalkUserVideoViewObject *existObj = nil;
    [self.joinUserVideoViewObjs enumerateObjectsUsingBlock:^(ZGVideoTalkUserVideoViewObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userID isEqualToString:userID]) {
            existObj = obj;
            *stop = YES;
        }
    }];
    return existObj;
}


#pragma mark - ZGVideoTalkDelegate


- (void)onLocalUserJoinRoomStateUpdated:(ZegoRoomState)state roomID:(nonnull NSString *)roomID {
    if ([roomID isEqualToString:self.roomID]) {
        // Modify page title based on room status
        [self invalidateJoinTalkStateDisplay];
    }
}

- (void)onRemoteUserDidJoinTalkInRoom:(nonnull NSString *)talkRoomID userIDs:(nonnull NSArray<NSString *> *)userIDs {
    if (![talkRoomID isEqualToString:self.roomID] || userIDs.count == 0) {
        return;
    }
    
    // Refresh data source
    for (NSString *userID in userIDs) {
        [self addRemoteUserVideoViewObjectIfNeedWithUserID:userID];
    }
    [self rearrangeJoinUserVideoViews];
}

- (void)onRemoteUserDidLeaveTalkInRoom:(nonnull NSString *)talkRoomID userIDs:(nonnull NSArray<NSString *> *)userIDs {
    if (![talkRoomID isEqualToString:self.roomID] || userIDs.count == 0) {
        return;
    }
    
    // Refresh data source
    for (NSString *userID in userIDs) {
        [self removeUserVideoViewObjectWithUserID:userID];
    }
    [self rearrangeJoinUserVideoViews];
}

- (void)onRemoteUserVideoStateUpdate:(int)stateCode userID:(nonnull NSString *)userID {
    // Processing changes in the video playback status of remote call users
}

#pragma mark - ZGVideoTalkDataSource

- (nonnull NSString *)localUserJoinTalkStreamID {
    return self.joinTalkStreamID;
}

- (nonnull UIView *)localUserPreviewView {
    return [self getLocalUserVideoViewObject].videoView;
}

- (nonnull UIView *)playViewForRemoteUserWithID:(nonnull NSString *)userID {
    return [self getUserVideoViewObjectWithUserID:userID].videoView;
}



@end

#endif
