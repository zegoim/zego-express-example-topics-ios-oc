# Zego Express Example Topics iOS (Objective-C)

zego express example topics for ios developer.

## Download SDK

[https://storage.zego.im/downloads/ZegoExpress-iOS.zip](https://storage.zego.im/downloads/ZegoExpress-iOS.zip)

> Note that there are two folders in the zip file: `iphoneos` and `iphoneos_simulator`, differences:

1. `iphoneos` is only used for real machine debugging. The user needs to use `ZegoExpressEngine.framework` under this file when it is finally released, otherwise it may be played back by Apple.

2. `iphonos_simulator` contains libraries for real machine and emulator debugging. If you use simulator debugging during user development, you need to import `ZegoExpressEngine.framework` under this folder. But when it's finally released, you have to switch back to the framework under the `iphoneos` folder.

> Please unzip and put the ZegoExpressEngine.framework under Libs/

```
.
├── Libs
│   └── ZegoExpressEngine.framework
├── README.md
├── ZegoExpressExample-iOS-OC
└── ZegoExpressExample-iOS-OC.xcodeproj
```
