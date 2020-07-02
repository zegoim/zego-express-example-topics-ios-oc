//
//  ZGPlayStreamSettingTableViewController.h
//  ZegoExpressExample-iOS-OC
//
//  Created by Patrick Fu on 2020/6/30.
//  Copyright © 2020 Zego. All rights reserved.
//

#ifdef _Module_Play

#import <UIKit/UIKit.h>
#import "ZGPlayStreamViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGPlayStreamSettingTableViewController : UITableViewController

+ (instancetype)instanceFromStoryboard;

@property (nonatomic, weak) ZGPlayStreamViewController *presenter;
@property (nonatomic, copy) NSString *streamID;
@property (nonatomic, assign) BOOL enableHardwareDecoder;
@property (nonatomic, assign) int playVolume;

@end

NS_ASSUME_NONNULL_END

#endif
