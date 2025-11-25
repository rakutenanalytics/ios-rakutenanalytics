# Rakuten Analytics SDK

[![Build Status](https://app.bitrise.io/app/4b13c693939a9575/status.svg?token=dgmDnWxutQeMP9wR79z1oQ&branch=master)](https://app.bitrise.io/app/4b13c693939a9575) [![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=rakutenanalytics_ios-rakutenanalytics2&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=rakutenanalytics_ios-rakutenanalytics2)

The **analytics** module provides APIs for tracking events and automatically sends a subset of lifecycle events to the Rakuten Analytics Tracker (RAT) service.

1. [Requirements](#requirements)
1. [How to install](#how-to-install)
1. [Configuring](#configuring)
1. [Using the SDK](#using-the-sdk)
1. [Sample app](#sample-app)

For more detailed information, please refer to the [Documentation](https://pages.ghe.rakuten-it.com/rakutenanalytics/rakuten-analytics-documentation/docs/analytics-sdks/ios).

# Requirements

This module supports iOS 15.0 and above. It has been tested with iOS 15.0 and above. 
Our minimum supported version is updated annually based on the OS version usage.

- Xcode >= 14.1 is supported.
- Swift >= 5.7.1 is supported.

Note: The SDK may build on earlier Xcode versions but it is not officially supported or tested.

# How to install

## Swift Package Manager

Open your project settings in Xcode and add a new package in 'Swift Packages' tab:

* Repository URL: `https://github.com/rakutenanalytics/ios-rakutenanalytics.git`
* Version settings: `11.0.0` "Up to Next Major"

Choose `RakutenAnalytics` product for your target. If you want to link other targets (Notification Service Extension, Notification Content Extension, etc), go to Build Phases of that target, then in Link Binary With Libraries click + button and add `RakutenAnalytics`.

## CocoaPods

To use the module in its default configuration your `Podfile` should contain:

```ruby
pod 'RakutenAnalytics'
```
Run `pod install` to install the module and its dependencies.

## Importing the module to use it in your app

### Swift
```
import RakutenAnalytics
```

### Objective-C
```
@import RakutenAnalytics;
```

## Migration from RAnalytics to RakutenAnalytics 

At the moment there are no major API changes and diffrences between `RAnalytics` and `RakutenAnalytics`. The migration process relates only to reinstalling dependencies and updating imports.

### Swift Package Manager

To migrate from `RAnalytics` to `RakutenAnalytics` using Swift Package Manager, please, open your project settings in Xcode and remove `RAnalytics` dependency from Xcode Project. After that, please use this package url:

`https://github.com/rakutenanalytics/ios-rakutenanalytics.git`

instead of:

`ssh://git@gitpub.rakuten-it.com:7999/eco/core-ios-analytics.git`

To install `RakutenAnalytics` package dependency.

### Module imports

After installing `RakutenAnalytics` instead of `RAnalytics` dependency, please, update module imports in the project from:

```
import RAnalytics
```

to:

```
import RakutenAnalytics
```

### CocoaPods

To migrate from `RAnalytics` to `RakutenAnalytics` using CocoaPods, please, change `Podfile` the dependency from:

```
pod 'RAnalytics'
```

to:

```
pod 'RakutenAnalytics'
```

And run `pod install` command to install dependency.

# Configuring

You must have a RAT **account ID** and **application ID** to track events using the Rakuten Analytics Tracker.

For the configuration details, please refer to our documentation: [Configuring](https://pages.ghe.rakuten-it.com/rakutenanalytics/rakuten-analytics-documentation/docs/analytics-sdk/ios/ios-user-guide#configuring)

# Using the SDK

For the details, please refer to [Using the SDK](https://pages.ghe.rakuten-it.com/rakutenanalytics/rakuten-analytics-documentation/docs/analytics-sdk/ios/ios-user-guide#using-the-sdk) and [Advance Usage](https://pages.ghe.rakuten-it.com/rakutenanalytics/rakuten-analytics-documentation/docs/category/advanced-usage-3) documentation pages.

# Sample app

* Sample app located by path: `Sample/RakutenAnalyticsSample.xcodeproj`.
