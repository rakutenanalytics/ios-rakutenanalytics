# Available targets & Functionality

- `RakutenAnalyticsSample` - basic target for Sample app. Utilize Swift Package Manager to install `RakutenAnalyticsSDK` dependency and `.xcodeproj` file for building/running.
- `RakutenAnalyticsSampleDest` - target to build Destination app to represent app-to-app tracking functionality. Utilize Swift Package Manager to install `RakutenAnalyticsSDK` dependency and `.xcodeproj` file for building/running.
- `RakutenAnalyticsSampleSwiftUI` - target to build SwiftUI based application to represent tracking functionality with SwiftUI Views. Utilize Swift Package Manager to install `RakutenAnalyticsSDK` dependency and `.xcodeproj` file for building/running.
- `RakutenAnalyticsSamplePod` - target to build CocoaPods based `RakutenAnalyticsSDK` dependency. Utilize CocoaPods for installation and `.xcworkspace` file for building/running.

# How to build and run

## Swift Package Manager

To build and run Sample application using Swift Package Manager:
- Open `RakutenAnalyticsSample.xcodeproj`
- Wait until all related dependencies will be ready
- Build and run

**Note:** `RakutenAnalyticsSamplePod` application target cannot be run using Swift Package Manager. To build and run use CocoaPods instead.

## CocoaPods

To build and run Sample application using CocoaPods:
- Run `pod install` command in terminal
- Open `RakutenAnalyticsSample.xcworkspace`
- Build and run
