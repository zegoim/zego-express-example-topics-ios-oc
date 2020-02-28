# Zego Express Example Topics iOS (Objective-C)

zego express example topics for ios developer.

## Download SDK

The SDK `ZegoExpressEngine.framework` required to run the Demo project is missing from this Repository, and needs to be downloaded and placed in the `Libs` folder of the Demo project

[https://storage.zego.im/downloads/ZegoExpress-iOS.zip](https://storage.zego.im/downloads/ZegoExpress-iOS.zip)

> Note that there are two folders in the zip file: `iphoneos` and `iphoneos_simulator`, differences:

1. The dynamic framework in `iphoneos` contains only the architecture of the real machine (armv7, arm64). Developers need to use `ZegoExpressEngine.framework` in this folder when distributing the app, otherwise it may be rejected by App Store.

2. The dynamic framework in `iphonos_simulator` contains the real machine and simulator architecture (armv7, arm64, x86_64). If developers need to use the simulator to develop and debug, they need to use `ZegoExpressEngine.framework` in this folder. But when the app is finally distributed, you need to switch back to the Framework under the `iphoneos` folder.

> Please unzip and put the `ZegoExpressEngine.framework` under `Libs`

```tree
.
├── Libs
│   └── ZegoExpressEngine.framework
├── README.md
├── ZegoExpressExample-iOS-OC
└── ZegoExpressExample-iOS-OC.xcodeproj
```
