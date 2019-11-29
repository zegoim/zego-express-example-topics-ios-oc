//
//  ZGUserIDHelper.m
//  ZegoExpressExample-iOS-OC
//
//  Copyright © 2018 Zego. All rights reserved.
//

#import "ZGUserIDHelper.h"
#import "ZGUserDefaults.h"
#import <sys/utsname.h>

#if TARGET_OS_OSX
#import <IOKit/IOKitLib.h>
#elif TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

NSString* kZGUserIDKey = @"user_id";
NSString* kZGUserNameKey = @"user_name";

@interface ZGUserIDHelper ()

@end

static NSString *_userID = nil;

static NSString *_userName = nil;

@implementation ZGUserIDHelper

+ (ZGUserDefaults *)myUserDefaults {
    return [[ZGUserDefaults alloc] init];
}

+ (NSString *)userID {
    if (_userID.length == 0) {
        NSUserDefaults *ud = [self myUserDefaults];
        NSString *userID = [ud stringForKey:kZGUserIDKey];
        if (userID.length > 0) {
            _userID = userID;
        } else {
            srand((unsigned)time(0));
            userID = [NSString stringWithFormat:@"%@@%u", [ZGUserIDHelper getDeviceModel], (unsigned)rand()%100000];
            _userID = userID;
            [ud setObject:userID forKey:kZGUserIDKey];
            [ud synchronize];
        }
    }
    
    return _userID;
}

+ (NSString *)userName {
    if (_userName.length == 0) {
        NSUserDefaults *ud = [self myUserDefaults];
        NSString *userName = [ud stringForKey:kZGUserNameKey];
        if (userName.length > 0) {
            _userName = userName;
        } else {
            userName = [ZGUserIDHelper getDeviceModel];
            _userName = userName;
            [ud setObject:userName forKey:kZGUserNameKey];
            [ud synchronize];
        }
    }
    
    return _userName;
}

#if TARGET_OS_OSX
+ (NSString *)getDeviceUUID {
    io_service_t platformExpert;
    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    if (platformExpert) {
        CFTypeRef serialNumberAsCFString;
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
        if (serialNumberAsCFString) {
            return (__bridge_transfer NSString*)(serialNumberAsCFString);
        }
    }
    
    return @"hello";
}
#elif TARGET_OS_IOS
+ (NSString *)getDeviceUUID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}
#endif

+ (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
}


@end
