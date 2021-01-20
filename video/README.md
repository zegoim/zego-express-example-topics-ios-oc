# Zego Express Video Example Topics iOS (Objective-C)

[English](README.md) | [中文](README_zh.md)

Zego Express Video Example Topics iOS Demo (Objective-C)

## Prepare the environment

Please ensure that the development environment meets the following technical requirements:

* Xcode 6.0 or higher
* iOS devices or simulators with iOS version no less than 8.0 and audio and video support (the real machine is recommended).
* iOS device already connected to Internet

## Download SDK

The SDK `ZegoExpressEngine.xcframework` required to run the Demo project is missing from this Repository, and needs to be downloaded and placed in the `Libs` folder of the Demo project

> You can use `Terminal` to run the `DownloadSDK.sh` script in this directory, it will automatically download the latest SDK and move it to the corresponding directory.

Or, manually download the SDK from the URL below, unzip it and put the `ZegoExpressEngine.xcframework` under `Libs`

[https://storage.zego.im/express/video/apple/zego-express-video-apple.zip](https://storage.zego.im/express/video/apple/zego-express-video-apple.zip)

```tree
.
├── Libs
│   └── ZegoExpressEngine.xcframework
├── README_zh.md
├── README.md
├── ZegoExpressExample-iOS-OC
└── ZegoExpressExample-iOS-OC.xcodeproj
```

## Running the sample code

1. Install Xcode: Open `AppStore`, search `Xcode`, download and install.

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/appstore-xcode.png" width=40% height=40%>

2. Open `ZegoExpressExample-iOS-OC.xcodeproj` with Xcode.

    Open Xcode, and click `File` -> `Open...` in the upper left corner.

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/xcode-open-file.png" width=70% height=70%>

    Find the `ZegoExpressExample-iOS-OC.xcodeproj` in the sample code folder downloaded and unzipped in the first step, and click `Open`.

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/xcode-select-file.png" width=70% height=70%>

3. Sign in Apple ID account.

    Open Xcode, click `Xcode` -> `Preference` in the upper left corner, select the `Account` tab, click the `+` sign in the lower left corner, and select Apple ID.

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/xcode-account.png" width=90% height=90%>

    Enter your Apple ID and password to sign in.

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/xcode-login-apple-id.png" width=70% height=70%>

4. Modify Apple Developer Certificate.

    Open Xcode, click the `ZegoExpressExample-iOS-OC` project in left side.

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/xcode-select-project.png" width=50% height=50%>

    Click on the `Signing & Capabilities` tab and select your developer certificate in `Team`.

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/team-signing.png" width=90% height=90%>

5. The AppID and AppSign required for SDK initialization are missing from the downloaded Demo source. Please refer to [Instructions for getting AppID and AppSign](https://doc.zego.im/API/HideDoc/GetExpressAppIDGuide/GetAppIDGuideline.html) to get AppID and AppSign. If you don't fill in the correct AppID and AppSign, the source code will not run properly, so you need to modify `ZGKeyCenter.m` under the directory `ZegoExpressExample-iOS-OC/Helper` to fill in the correct AppID and AppSign.

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/appid-appsign-en.png" width=80% height=80%>

6. Connect your iOS device to the computer, click `🔨 Generic iOS Device` in the upper left corner of Xcode to select the iOS device (or Simulator)

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/xcode-select-device.png" width=80% height=80%>

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/xcode-select-real-device.png" width=80% height=80%>

7. Click the Build button to compile and run.

    <img src="https://storage.zego.im/sdk-doc/Pics/iOS/ZegoExpressEngine/Common/build-and-run.png" width=50% height=50%>

## FAQ

1. `The app ID "im.zego.ZegoExpressExample-iOS-OC" cannot be registered to your development team. Change your bundle identifier to a unique string to try again.`

    Refer to **Modify Bundle Identifier and Apple Developer Certificate** above, switch to your own development certificate in `Targets` -> `Signing & Capabilities` and modify `Bundle Identifier` before running.

2. `dyld: Library not loaded`

    This is [bug](https://forums.developer.apple.com/thread/128435) of iOS 13.3.1, please upgrade to iOS 13.4 or above.
