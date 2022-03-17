# RAnalytics
Records user activity and automatically sends tracking events to an analytics cloud service.

## Requirements
Xcode 12.5.x or Xcode 13+

Swift >= 5.4 is supported.

Note: The SDK may build on earlier Xcode versions but it is not officially supported or tested.

## Users
It is intended to be used only by Rakuten approved applications.
 
## Installing with CocoaPods
To use the module in its default configuration your `Podfile` should contain:
 
```ruby
pod 'RAnalytics', :source => 'https://github.com/rakutentech/ios-analytics-framework.git'
```

To use a specific version of the module e.g. `1.0.0` your `Podfile` should contain:

```ruby
pod 'RAnalytics', '1.0.0', :source => 'https://github.com/rakutentech/ios-analytics-framework.git'
```
 
Run `pod install` to install the module and dependencies.

## Installing with Swift Package Manager
As an alternative to CocoaPods, this module can be also integrated as a Swift Package.<br>
To add a new package, open the 'Swift Package' tab in Xcode project settings, click the `+` button, then provide one of the following URLs:
* SSH: `git@github.com:rakutentech/ios-analytics-framework.git`
* HTTPS: `https://github.com/rakutentech/ios-analytics-framework.git`

We recommend using "Up to Next Major" version rule.
 
## Configuring
Applications must configure their `Info.plist` as follows:
 
Key         | Value
-------------------|-------------------
`RATAccountIdentifier` | `YOUR_RAT_ACCOUNT_ID` (Number)
`RATAppIdentifier` | `YOUR_RAT_APPLICATION_ID` (Number)
`RATEndpoint` | `YOUR_ENDPOINT` (String)
 
For more information (including full configuration instructions, how to get support, API usage, and a full change log) please visit the internal documentation site of the `RAnalytics` SDK or raise an inquiry with your Rakuten contact.
