# RAnalytics
Records user activity and automatically sends tracking events to an analytics cloud service.

## Requirements
Xcode >= 14.1 is supported.
Swift >= 5.7.1 is supported.

Note: The SDK may build on earlier Xcode versions but it is not officially supported or tested.
 
## Installing with CocoaPods
To use the module in its default configuration your `Podfile` should contain:
 
```ruby
pod 'RAnalytics'
```

To use a specific version of the module e.g. `1.0.0` your `Podfile` should contain:

```ruby
pod 'RAnalytics', '1.0.0'
```
 
Run `pod install` to install the module and dependencies.

## Installing with Swift Package Manager
As an alternative to CocoaPods, this module can be also integrated as a Swift Package.<br>
To add a new package, open the 'Swift Package' tab in Xcode project settings, click the `+` button, then provide one of the following URLs:
* SSH: `git@github.com:rakutenanalytics/ios-ranalytics.git`
* HTTPS: `https://github.com/rakutenanalytics/ios-ranalytics.git`

We recommend using "Up to Next Major" version rule.
 
## Configuring
Applications must configure their `Info.plist` as follows:
 
Key         | Value
-------------------|-------------------
`RATAccountIdentifier` | `YOUR_RAT_ACCOUNT_ID` (Number)
`RATAppIdentifier` | `YOUR_RAT_APPLICATION_ID` (Number)
`RATEndpoint` | `YOUR_ENDPOINT` (String)
