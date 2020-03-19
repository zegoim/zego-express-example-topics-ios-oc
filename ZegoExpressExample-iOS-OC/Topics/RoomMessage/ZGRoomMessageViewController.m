//
//  ZGRoomMessageViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2019/11/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_RoomMessage

#import "ZGRoomMessageViewController.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGUserIDHelper.h"
#import "ZGRoomMessageSelectUsersTableViewController.h"
#import <ZegoExpressEngine/ZegoExpressEngine.h>

@interface ZGRoomMessageViewController () <ZegoEventHandler, UITextFieldDelegate>

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, strong) NSMutableArray<ZegoUser *> *userList;
@property (nonatomic) ZGRoomMessageSelectUsersTableViewController *selectUsersVC;

@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomStateLabel;

@property (weak, nonatomic) IBOutlet UITextView *receivedMessageTextView;

@property (weak, nonatomic) IBOutlet UITextField *broadcastMessageTextField;
@property (weak, nonatomic) IBOutlet UITextField *barrageMessageTextField;
@property (weak, nonatomic) IBOutlet UITextField *customCommandTextField;

@end

@implementation ZGRoomMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.roomID = @"ChatRoom-1";
    self.receivedMessageTextView.text = @"";
    self.userList = [NSMutableArray array];
    self.title = [NSString stringWithFormat:@"ChatRoom  ( %d Users )", (int)self.userList.count + 1];
    
    self.roomIDLabel.text = [NSString stringWithFormat:@"RoomID: %@", self.roomID];
    self.roomStateLabel.text = @"Not Connected 🔴";
    
    [self createEngineAndLoginRoom];
}

- (void)createEngineAndLoginRoom {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedManager] globalConfig];
    
    ZGLogInfo(@" 🚀 Create ZegoExpressEngine");
    [ZegoExpressEngine createEngineWithAppID:appConfig.appID appSign:appConfig.appSign isTestEnv:appConfig.isTestEnv scenario:appConfig.scenario eventHandler:self];
    
    ZegoUser *user = [ZegoUser userWithUserID:[ZGUserIDHelper userID] userName:[ZGUserIDHelper userName]];
    
    // To receive the onRoomUserUpdate:userList:room: callback, you need to set the isUserStatusNotify parameter to YES.
    ZegoRoomConfig *roomConfig = [[ZegoRoomConfig alloc] init];
    roomConfig.isUserStatusNotify = YES;
    
    ZGLogInfo(@" 🚪 Login room. roomID: %@", self.roomID);
    [[ZegoExpressEngine sharedEngine] loginRoom:self.roomID user:user config:roomConfig];
}

#pragma mark - Actions

- (IBAction)selectUsersButtonClick:(UIButton *)sender {
    [self.navigationController pushViewController:self.selectUsersVC animated:YES];
}

- (IBAction)sendBroadcastMessageButtonClick:(UIButton *)sender {
    [self sendBroadcastMessage];
}


- (IBAction)sendBarrageMessageButtonClick:(UIButton *)sender {
    [self sendBarrageMessage];
}

- (IBAction)sendCustomCommandButtonClick:(UIButton *)sender {
    [self sendCustomCommand];
}

- (void)sendBroadcastMessage {
    NSString *message = self.broadcastMessageTextField.text;
    [[ZegoExpressEngine sharedEngine] sendBroadcastMessage:message roomID:self.roomID callback:^(int errorCode, unsigned long long messageID) {
        ZGLogInfo(@" 🚩 💬 Send broadcast message result errorCode: %d, messageID: %llu", errorCode, messageID);
        [self appendMessage:[NSString stringWithFormat:@" 💬 📤 Sent: %@", message]];
    }];
}

- (void)sendBarrageMessage {
    NSString *message = self.barrageMessageTextField.text;
    [[ZegoExpressEngine sharedEngine] sendBarrageMessage:message roomID:self.roomID callback:^(int errorCode, NSString * _Nonnull messageID) {
        ZGLogInfo(@" 🚩 🗯 Send broadcast message result errorCode: %d, messageID: %@", errorCode, messageID);
        [self appendMessage:[NSString stringWithFormat:@" 🗯 📤 Sent: %@", message]];
    }];
}

- (void)sendCustomCommand {
    NSString *command = self.customCommandTextField.text;
    NSArray<ZegoUser *> *toUserList = self.selectUsersVC.selectedUsers;
    [[ZegoExpressEngine sharedEngine] sendCustomCommand:command toUserList:toUserList roomID:self.roomID callback:^(int errorCode) {
        ZGLogInfo(@" 🚩 💭 Send custom command to %d users result errorCode: %d", (int)toUserList.count, errorCode);
        [self appendMessage:[NSString stringWithFormat:@" 💭 📤 Sent to %d users: %@", (int)toUserList.count, command]];
    }];
}

- (void)appendMessage:(NSString *)message {
    if (!message || message.length == 0) {
        return;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
    NSString *currentTime = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *oldText = self.receivedMessageTextView.text;
    NSString *newLine = oldText.length == 0 ? @"" : @"\n";
    NSString *newText = [NSString stringWithFormat:@"%@%@[%@] %@", oldText, newLine, currentTime, message];
    
    self.receivedMessageTextView.text = newText;
    if(newText.length > 0 ) {
        UITextView *textView = self.receivedMessageTextView;
        NSRange bottom = NSMakeRange(newText.length -1, 1);
        [textView scrollRangeToVisible:bottom];
        // an iOS bug, see https://stackoverflow.com/a/20989956/971070
        [textView setScrollEnabled:NO];
        [textView setScrollEnabled:YES];
    }
}

- (IBAction)clearBuffer:(UIButton *)sender {
    self.receivedMessageTextView.text = @"";
}

#pragma mark - Access SelectUserVC

- (ZGRoomMessageSelectUsersTableViewController *)selectUsersVC {
    if (!_selectUsersVC) {
        _selectUsersVC = [[ZGRoomMessageSelectUsersTableViewController alloc] init];
    }
    [_selectUsersVC updateRoomUserList:[self.userList copy]];
    return _selectUsersVC;
}

#pragma mark - ZegoEventHandler

- (void)onRoomStateUpdate:(ZegoRoomState)state errorCode:(int)errorCode extendedData:(NSDictionary *)extendedData roomID:(NSString *)roomID {
    if (errorCode != 0) {
        ZGLogError(@" 🚩 ❌ 🚪 Room state error, errorCode: %d", errorCode);
    } else {
        if (state == ZegoRoomStateConnected) {
            ZGLogInfo(@" 🚩 🚪 Login room success");
            self.roomStateLabel.text = @"Connected 🟢";
        } else if (state == ZegoRoomStateConnecting) {
            ZGLogInfo(@" 🚩 🚪 Requesting login room");
            self.roomStateLabel.text = @"Connecting 🟡";
        } else if (state == ZegoRoomStateDisconnected) {
            ZGLogInfo(@" 🚩 🚪 Logout room");
            self.roomStateLabel.text = @"Not Connected 🔴";
        }
    }
}


- (void)onRoomUserUpdate:(ZegoUpdateType)updateType userList:(NSArray<ZegoUser *> *)userList roomID:(NSString *)roomID {
    ZGLogInfo(@" 🚩 🕺 Room User Update Callback: %lu, UsersCount: %lu, roomID: %@", (unsigned long)updateType, (unsigned long)userList.count, roomID);
    
    if (updateType == ZegoUpdateTypeAdd) {
        for (ZegoUser *user in userList) {
            ZGLogInfo(@" 🚩 🕺 --- [Add] UserID: %@, UserName: %@", user.userID, user.userName);
            if (![self.userList containsObject:user]) {
                [self.userList addObject:user];
            }
        }
    } else if (updateType == ZegoUpdateTypeDelete) {
        for (ZegoUser *user in userList) {
            ZGLogInfo(@" 🚩 🕺 --- [Delete] UserID: %@, UserName: %@", user.userID, user.userName);
            __block ZegoUser *delUser = nil;
            [self.userList enumerateObjectsUsingBlock:^(ZegoUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.userID isEqualToString:user.userID] && [obj.userName isEqualToString:user.userName]) {
                    delUser = obj;
                    *stop = YES;
                }
            }];
            [self.userList removeObject:delUser];
        }
    }
    
    // Update Title
    self.title = [NSString stringWithFormat:@"%@  ( %d Users )", self.roomID, (int)self.userList.count + 1];
}

- (void)onIMRecvBroadcastMessage:(NSArray<ZegoBroadcastMessageInfo *> *)messageList roomID:(NSString *)roomID {
    ZGLogInfo(@" 🚩 💬 IM Recv Broadcast Message Callback: roomID: %@", roomID);
    
    for (int idx = 0; idx < messageList.count; idx ++) {
        ZegoBroadcastMessageInfo *info = messageList[idx];
        ZGLogInfo(@" 🚩 💬 --- message: %@, fromUserID: %@, sendTime: %llu", info.message, info.fromUser.userID, info.sendTime);
        
        [self appendMessage:[NSString stringWithFormat:@" 💬 %@ [FromUserID: %@]", info.message, info.fromUser.userID]];
    }
}

- (void)onIMRecvBarrageMessage:(NSArray<ZegoBarrageMessageInfo *> *)messageList roomID:(NSString *)roomID {
    ZGLogInfo(@" 🚩 🗯 IM Recv Barrage Message Callback: roomID: %@", roomID);
    
    for (int idx = 0; idx < messageList.count; idx ++) {
        ZegoBarrageMessageInfo *info = messageList[idx];
        ZGLogInfo(@" 🚩 🗯 --- message: %@, fromUserID: %@, sendTime: %llu", info.message, info.fromUser.userID, info.sendTime);
        
        [self appendMessage:[NSString stringWithFormat:@" 🗯 %@ [FromUserID: %@]", info.message, info.fromUser.userID]];
    }
}

- (void)onIMRecvCustomCommand:(NSString *)command fromUser:(ZegoUser *)fromUser roomID:(NSString *)roomID {
    ZGLogInfo(@" 🚩 💭 IM Recv Custom Command Callback: roomID: %@", roomID);
    ZGLogInfo(@" 🚩 💭 --- command: %@, fromUserID: %@", command, fromUser.userID);
    
    [self appendMessage:[NSString stringWithFormat:@" 💭 %@ [FromUserID: %@]", command, fromUser.userID]];
}

#pragma mark - Exit

- (void)viewDidDisappear:(BOOL)animated {
    if (self.isBeingDismissed || self.isMovingFromParentViewController
        || (self.navigationController && self.navigationController.isBeingDismissed)) {
        
        ZGLogInfo(@" 🚪 Exit the room");
        [[ZegoExpressEngine sharedEngine] logoutRoom:self.roomID];
        
        // Can destroy the engine when you don't need audio and video calls
        ZGLogInfo(@" 🏳️ Destroy ZegoExpressEngine");
        [ZegoExpressEngine destroyEngine:nil];
    }
    [super viewDidDisappear:animated];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.broadcastMessageTextField) {
        [self sendBroadcastMessage];
    } else if (textField == self.customCommandTextField) {
        [self sendCustomCommand];
    }
    return YES;
}


@end

#endif
