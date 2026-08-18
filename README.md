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

This module supports **iOS 15.0** and **tvOS 15.0** and above. It has been tested with iOS 15.0 and above.
Our minimum supported version is updated annually based on the OS version usage.

- Xcode >= 14.1 is supported.
- Swift >= 5.7.1 is supported.

Note: The SDK may build on earlier Xcode versions but it is not officially supported or tested.

## Platform support

Most RAT tracking APIs work on both iOS and tvOS. The following features are **not available on tvOS** (or are disabled by default):

| Feature | iOS | tvOS |
| --- | --- | --- |
| Page visits (SwiftUI / UIKit) | Yes | Yes |
| Custom events | Yes | Yes |
| Auto-tracking hooks (`UIApplication`, `UIViewController`, `UIWindowScene`) | Yes | Yes |
| WebKit app-to-web tracking | Yes | No |
| IDFA / advertising identifier | Yes | No (disabled by default) |
| Geo location collection | Yes | No (disabled by default) |
| Cellular / telephony metadata | Yes | No |
| Push notification auto-tracking | Yes | No |
| Battery metrics in automatic fields | Yes | No |

On tvOS, `shouldTrackLastKnownLocation` and `shouldTrackAdvertisingIdentifier` default to `false`.

# How to install

## Swift Package Manager

Open your project settings in Xcode and add a new package in 'Swift Packages' tab:

* Repository URL: `https://github.com/rakutenanalytics/ios-rakutenanalytics.git`
* Version settings: `12.0.0` "Up to Next Major"

Choose `RakutenAnalytics` product for your target. If you want to link other targets (Notification Service Extension, Notification Content Extension, etc), go to Build Phases of that target, then in Link Binary With Libraries click + button and add `RakutenAnalytics`.

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

# Configuring

You must have a RAT **account ID** and **application ID** to track events using the Rakuten Analytics Tracker.

For the configuration details, please refer to our documentation: [Configuring](https://pages.ghe.rakuten-it.com/rakutenanalytics/rakuten-analytics-documentation/docs/sdks/analytics-sdks/ios/explanations/installation)

# Using the SDK

For the details, please refer to [Using the SDK](https://pages.ghe.rakuten-it.com/rakutenanalytics/rakuten-analytics-documentation/docs/sdks/analytics-sdks/ios/explanations/usage) and [Advance Usage](https://pages.ghe.rakuten-it.com/rakutenanalytics/rakuten-analytics-documentation/docs/sdks/analytics-sdks/ios/how-to-guides/overview) documentation pages.

# Sample app

* iOS sample: `Sample/RakutenAnalyticsSample.xcodeproj`
* tvOS sample: `Sample/TvOSSample/TvOSSample.xcodeproj` — see [Sample/TvOSSample/README.md](Sample/TvOSSample/README.md) for setup and run instructions.
