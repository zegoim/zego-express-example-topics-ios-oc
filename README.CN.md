# Zego Express Example Topics iOS (Objective-C)

Zego Express iOS (Objective-C) 示例专题 Demo

## 下载 SDK

此 Repository 中缺少运行 Demo 工程所需的 SDK `ZegoExpressEngine.framework`，需要下载并放入 Demo 工程的 `Libs` 文件夹中

[https://storage.zego.im/downloads/ZegoExpress-iOS.zip](https://storage.zego.im/downloads/ZegoExpress-iOS.zip)

> 请注意，压缩包中有两个文件夹：`iphoneos` 和 `iphoneos_simulator`，区别在于：

1. `iphoneos` 内的动态库仅包含真机的架构（armv7, arm64）。开发者在最终上架 App 时，需要使用此文件夹下的 `ZegoExpressEngine.framework`，否则可能被 App Store 拒绝。

2. `iphonos_simulator` 内的动态库包含了真机与模拟器架构（armv7, arm64, x86_64）。如果开发者需要使用到模拟器来开发调试，需要使用此文件夹下的 `ZegoExpressEngine.framework`。但是最终上架 App 时，要切换回 `iphoneos` 文件夹下的 Framework。

> 请解压缩 `ZegoExpressEngine.framework` 并将其放在 `Libs` 目录下

```tree
.
├── Libs
│   └── ZegoExpressEngine.framework
├── README.md
├── ZegoExpressExample-iOS-OC
└── ZegoExpressExample-iOS-OC.xcodeproj
```
