//
//  ZGVideoTalkLoginViewController.m
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2019/10/30.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_VideoTalk

#import "ZGVideoTalkLoginViewController.h"
#import "ZGVideoTalkViewController.h"

NSString *const ZGVideoTalkTopicKey_roomID = @"kRoomID";

@interface ZGVideoTalkLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;

@end

@implementation ZGVideoTalkLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.roomIDTextField.text = [self savedValueForKey:ZGVideoTalkTopicKey_roomID];
}


- (IBAction)onLoginRoom:(UIButton *)sender {
    NSString *roomID = self.roomIDTextField.text;
    if (roomID.length > 0) {
        [self saveValue:roomID forKey:ZGVideoTalkTopicKey_roomID];
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"VideoTalk" bundle:nil];
        
        ZGVideoTalkViewController *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGVideoTalkViewController class])];
        vc.roomID = roomID;
        
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [ZegoHudManager showMessage:@"❗️Empty Room ID"];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


@end

#endif
