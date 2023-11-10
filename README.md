# RAnalytics SDK

The **analytics** module provides APIs for tracking events and automatically sends a subset of lifecycle events to the Rakuten Analytics Tracker (RAT) service.

1. [RAnalytics SDK](#ranalytics-sdk)
1. [Requirements](#requirements)
1. [How to install](#how-to-install)
1. [Configuring](#configuring)
1. [Using the SDK](#using-the-sdk)
1. [Sample app](#sample-app)
1. [App Store Submission Procedure](#app-store-submission-procedure)
1. [Troubleshooting](#troubleshooting)
1. [FAQ](#faq)

# Requirements

This module supports iOS 12.0 and above. It has been tested with iOS 12.5 and above. Our minimum supported version is updated annually based on the OS version usage.

Xcode >= 14.1 is supported.
Swift >= 5.7.1 is supported.

Note: The SDK may build on earlier Xcode versions but it is not officially supported or tested.

# How to install

## CocoaPods

To use the module in its default configuration your `Podfile` should contain:

```ruby
pod 'RAnalytics'
```
Run `pod install` to install the module and its dependencies.

## Swift Package Manager

Open your project settings in Xcode and add a new package in 'Swift Packages' tab:

* Repository URL: `git@github.com:rakutenanalytics/ios-ranalytics.git`
* Version settings: 10.0.1 "Up to Next Major"

Choose `RAnalytics` product for your target. If you want to link other targets (Notification Service Extension, Notification Content Extension, etc), go to Build Phases of that target, then in Link Binary With Libraries click + button and add `RAnalytics`.

## Importing the module to use it in your app

### Swift
```
import RAnalytics
```

### Objective-C
```
@import RAnalytics;
```

# Configuring

## Credentials

You must have a RAT account ID and application ID to track events using the Rakuten Analytics Tracker.

## Build-time Configuration

Applications **MUST** configure their RAT identifiers (`RATAccountIdentifier` and `RATAppIdentifier`) in their `Info.plist` as follows:

| Key    | Value     |
|  -------- | -------- |
| `RATAccountIdentifier` | `YOUR_RAT_ACCOUNT_ID` (Number type) |
| `RATAppIdentifier` | `YOUR_RAT_APPLICATION_ID` (Number type) |

Otherwise:
- RAnalytics SDK **THROWS AN EXCEPTION** in **DEBUG MODE** when `RATAccountIdentifier` and `RATAppIdentifier` keys are missing in the app's `Info.plist`
- RAnalytics SDK tracking is **DISABLED** in **RELEASE MODE** when `RATAccountIdentifier` and `RATAppIdentifier` keys are missing in the app's `Info.plist`

## Using Kibana to verify successful integration

Kibana STG and PROD sites can be used to check events sent by your app.

To find all analytics data for your app, you can search for your Application Identifier `aid:<your app id>` or `app_name:<your bundle id>`.

To find data for a certain event type, such as one of the [standard events](#standard-events), you can add the `etype` to your search query, for example `aid:999 AND etype:_rem_launch`.

# Using the SDK

## Handle login

The member identifier needs to be set and unset manually in order to track login and logout events with the correct member identifier. In most cases, the value you set as member identifier should be the member's identifier. The member identifier can be extracted from the IDSDK ID token or passed as `String` value.

You should notify the RAnalytics SDK of the user's member identifier using `setMemberIdentifier`. 

```swift
    AnalyticsManager.shared().setMemberIdentifier(%member_identifier%)
```

Note: By setting the member identifier, `_rem_login` is automatically tracked.

## Handle login failure

If user login fails, notify the RAnalytics SDK using `setMemberError` as follows:

```swift
    AnalyticsManager.shared().setMemberError(error)
```

Note: By setting a member error, `_rem_login_failure` is automatically tracked.

## Handle logout

When a user logs out, notify the RAnalytics SDK using `removeMemberIdentifier` as follows:

```swift
    AnalyticsManager.shared().removeMemberIdentifier()
```

Note: By removing the member identifier, `_rem_logout` is automatically tracked.

## Track standard event

Events are created with `RAnalyticsEvent#initWithName:parameters:` and spooled by calling their track method.

#### Tracking generic events

Tracking a generic event relies on a tracker capable of processing the event currently being registered.

```swift
AnalyticsManager.Event(name: "my.event", parameters: ["foo": "bar"]).track()
```
#### Tracking RAT-specific events

A concrete tracker, `RAnalyticsRATTracker`, is automatically registered and interacts with the **Rakuten Analytics Tracker (RAT)**. You can also use `RAnalyticsRATTracker#eventWithEventType:parameters:` for creating events that will only be processed by RAT. For more information about the various parameters accepted by that service, see the [RAT Parameter Spec](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Parameter+Specifications).

> **Note:** Our SDK automatically tracks a number of RAT parameters for you, so you don't have to include those when creating an event: `acc`, `aid`, `etype`, `powerstatus`, `mbat`, `dln`, `loc`, `mcn`, `model`, `mnetw`, `mori`, `mos`, `online`, `cka`, `ckp`, `cks`, `ua`, `app_name`, `app_ver`, `res`, `ltm`, `ts1`, `tzo`, `userid` and `ver`.

```swift
RAnalyticsRATTracker.shared().event(eventType: "click", parameters:["pgn": "coupon page"]).track()
```

> You can override the `acc` and `aid` default values by including those keys in the `parameters` dictionary when you create an event.
> **Note:** `acc` and `aid` **MUST** be integers.

```swift
RAnalyticsRATTracker.shared().event(eventType: "click", parameters:["acc": 123, "aid": 456]).track()
```
### Standard events

The SDK will automatically send events to the Rakuten Analytics Tracker for certain actions. The event type parameter for all of these events are prefixed with `_rem_`. We also provide named constants for all of those.


| Event name    | Description     |
|  -------- | -------- |
| `_rem_init_launch` | Application is launched for the first time ever.     |
| `_rem_launch` | Application is launched.     |
| `_rem_end_session` | Application goes into background.     |
| `_rem_update` | Application is launched and its version number does not match the version number of the previous launch.     |
| `_rem_login` | User logged in successfully.     |
| `_rem_logout` | User logged out.     |
| `_rem_install` | Application version is launched for the first time.     |
| `_rem_visit` | A new page is shown. Application developers can also emit this event manually if they wish so, for instance to track pages that are not view controllers (e.g. a table cell). In that case, they should set the event's parameter `page_id` to a string that uniquely identifies the visit they want to track.     |
| `_rem_applink` | The application has been opened from a deeplink.     |
| `_rem_push_received` | A push notification has been received while the app was in background or in foreground.    |
| `_rem_push_notify` | A push notification has been opened while the app was active, or the app was opened from a push notification. A value that uniquely identifies the push notification is provided in the `tracking_id` parameter. See its definition below.    |
| `_rem_push_auto_register` | A pnp auto registration occured.    |
| `_rem_push_auto_unregister` | A pnp auto unregistration occured.    |

#### Requirements

The below table shows the required components of each standard event which is tracked automatically by the **analytics** module.


| Event name    | Required components     |
|  -------- | -------- |
| `_rem_login` | **authentication** module (3.10.1 or later).     |
| `_rem_logout` | **authentication** module (3.10.1 or later).    |

#### Automatically Generated State Attributes

The SDK will automatically generate certain attributes about the state of the device, and pass them to every registered tracker when asked to process an event.

### Tracking events in iOS Extensions

### Warning
Don't directly call the AnalyticsManager singleton to track events in your iOS Extensions as you will get:
- missing parameters such as member identifier
- incorrect endpoint URL

Use the iOS Extension Event Tracking feature instead.

#### How to use the iOS Extension Event Tracking feature
To enable iOS Extension Event Tracking set the following property in your **main app**:

```swift
AnalyticsManager.shared().enableExtensionEventTracking = true
```

Then you can track events in your iOS extensions using the following function:

```swift
AnalyticsEventPoster.post(name: "myEventName", parameters: ["key1": "value1"])
```

### Tracking events in `UIKit`'s `UIViewController`

Page visit events (etype = `pv`) are automatically tracked for `UIViewController` instances.

#### `UIViewController` restrictions

Page visit events are not tracked for these `UIViewController` subclasses:

- `UINavigationController`
- `UISplitViewController`
- `UIPageViewController`
- `UITabBarController`

#### `UIView` retrictions

Page visit events are not tracked when the `UIViewController`'s view type is:

- `UIAlertView`
- `UIActionSheet`
- `UIAlertController`

#### Other restrictions

- Private Apple classes are not tracked as page visit events.
- `UIView`'s window property type must be kind of `UIWindow` class

### Tracking events in SwiftUI views

To track page visit events (etype = `pv`) in your SwiftUI apps, call this function in your SwiftUI views body:

```
public func rviewOnAppear(pageName: String, perform action: (() -> Void)? = nil) -> some View
```

This function above calls SwiftUI's `onAppear` internally.
https://developer.apple.com/documentation/SwiftUI/AnyView/onAppear%28perform:%29

Example:

```swift
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: PageView()) {
                    Text("Page 1")
                }
                NavigationLink(destination: PageView()) {
                    Text("Page 2")
                }
            }.rviewOnAppear(pageName: "contentView") {
            }
        }
    }
}
```

### UI Interaction

The following code is an example that can be used to track button clicks. It uses RAT's standard `click` event and passes the page name, clicked element's id and goal id in the `pgn`, `target` and `gol` parameters, respectively.

```swift
@IBAction func buttonTapped(sender: UIButton) {
    RAnalyticsRATTracker.shared().event(eventType: "click",
                             parameters:["pgn": "Main",
                                         "target": "search_btn",
                                         "gol": "goal123456"]).track()
}
```

## Track custom event

**Note:** These example is using `RAnalyticsRATTracker` to send RAT specific parameters. If you are using a custom tracker, `RAnalyticsEvent` should be used instead.

The following is an example of tracking an event with custom parameters. It uses the standard `pv` RAT event used in the previous examples, and passes some custom `custom_param_##` parameters in the `cp` dictionary accepted by RAT for this purpose.

```swift
RAnalyticsRATTracker.shared().event(eventType: "pv",
                         parameters:["pgn": "Main",
                                     "cp": ["custom_param_1": "value",
                                            "custom_param_2": 10,
                                            "custom_param_3": true]]).track()
```

# Sample app

* Run `bundle exec fastlane ios build_sample`
  - By default the `RAnalyticsSample` app depends on the compiled `RAnalytics` framework which gets built via this command invocation. It will also install dependencies.
* Open `Samples/RAnalyticsSample.xcworkspace` in Xcode then run

# App Store Submission Procedure

Apple requests that you **disclose your usage of the advertising identifier (IDFA)** when releasing your application to the App Store.

![appstore-idfa.png](doc/appstore-idfa.png)*IDFA usage disclosure*

#### 1. Serve advertisements within the app.

Check this box if your app contains advertisements.

#### 2. Attribute this app installation to a previously served advertisement

Check this checkbox. The Rakuten SDK uses the IDFA for install attribution.

#### 3. Attribute an action taken within this app to a previously served advertisement

Check this checkbox. The Rakuten SDK uses the IDFA for re-engagment ads attribution.

#### 5. iOS Limited Ad Tracking

The Rakuten SDK fully complies with Apple requirement below:

Check the value of this property before performing any advertising tracking. If the value is NO, use the advertising identifier only for the following purposes: frequency capping, conversion events, estimating the number of unique users, security and fraud detection, and debugging. 

The Rakuten SDK only uses the IDFA for `conversion events, estimating the number of unique users, security and fraud detection`.

# Troubleshooting

## How to build your project without use_frameworks!

RAnalytics is a Swift framework and contains a custom module map.

If `use_frameworks!` is not defined in your app's Podfile the following Cocoapods error occurs:


> `Using Swift static libraries with custom module maps is currently not supported.`

To solve this problem:
1. Add `cocoapods-user-defined-build-types` plugin to your Podfile
2. Declare `RAnalytics` and its dependencies as `static_framework` as follows:

```
plugin 'cocoapods-user-defined-build-types'
enable_user_defined_build_types!

target 'MyApp' do
  pod 'RAnalytics', :build_type => :static_framework
end
```

**Note:** The `cocoapods-user-defined-build-types` plugin is developed by a third party and we cannot guarantee that its support will continue.

## RAnalytics Swift Package checkout tip

If you can't checkout the RAnalytics Swift Package in Xcode, please execute these 2 command lines:
```
/usr/libexec/Plistbuddy -c "Add :IDEPackageSupportUseBuiltinSCM bool 1" ~/Library/Preferences/com.apple.dt.Xcode.plist
xcodebuild -scheme MyScheme -resolvePackageDependencies -usePackageSupportBuiltinSCM
```

# FAQ

## Build and run module

* Clone or fork the [iOS analytics repository](git@github.com:rakutenanalytics/ios-ranalytics.git)  
* `cd` to the repository folder
* Run `bundle install --path vendor/bundle`

### Unit tests

* Run `bundle exec pod install` to install dependencies
* Open `CI.xcworkspace` in Xcode then build/run

### Building app for App Store

Xcode 13 introduced an option (**enabled** by default) to automatically manage app version numbering. Exporting your app with this option enabled breaks the Analytics SDK’s framework version tracking feature. 

When exporting for the App Store please disable the option “Manage Version and Build Number” in the Xcode UI. If you prefer to keep this option enabled, be aware that the SDK will not be able to track the versions of your embedded SDKs/frameworks.

## How page views are automatically tracked

We use method swizzling to automatically trigger a visit event every time a new view controller is presented, unless:
* The view controller is one of the known "chromes" used to coordinate "content" view controllers, i.e. one of `UINavigationController`, `UISplitViewController`, `UIPageViewController` and `UITabBarController`.
* The view controller is showing a system popup, i.e. `UIAlertView`, `UIActionSheet`, `UIAlertController` or `_UIPopoverView`.
* Either the view controller, its view or the window it's attached to is an instance of an Apple-private class, i.e. a class whose name has a `_` prefix and which comes from a system framework. This prevents many on-screen system accessories from generating bogus page views.
* The class of the window the view controller is attached to is a subclass of `UIWindow` coming from a system framework, i.e. the window is not a normal application window. Certain on-screen system accessories, such as the system keyboard's autocompletion word picker, would otherwise trigger events as well.

Those visit events are available to all trackers, and the view controller being the event's subject can be found in the currentPage property of the event state passed to `RAnalyticsTracker#processEvent:state:`.

The RAT tracker furthermore ignores view controllers that have no title, no navigation item title, and for which no URL was found on any webview part of their view hierarchy at the time `-viewDidLoad` was called, unless they have been subclassed by the application or one of the frameworks embedded in the application. This filters out events that would give no information about what page was visited in the application, such as events reporting a page named `UIViewController`. For view controllers with either a title, navigation item title or URL, the library also sets the `cp.title` and `cp.url` fields to the `pv` event it sends to RAT.

## Tracking search results with RAT

The code below shows an example of an event you could send to track which results get shown on a search page. It uses the standard `pv` RAT event used in the previous examples, and a number of standard RAT parameters. The parameters used are:

| RAT param | Description |
|  -------- | -------- |
| `lang` | The language used for the search. |
| `sq` | The search terms. |
| `oa` | `a` for requesting all search terms (AND), `o` for requesting one of them (OR). |
| `esq` | Terms that should be excluded from the results. |
| `genre` | Category for the results. |
| `tag` | An array of tags. |

```swift
RAnalyticsRATTracker.shared().event(eventType: "pv",
parameters:["pgn": "shop_search",
"pgt": "search",
"lang": "English",
"sq": "search query",
"oa": "a",
"esq": "excluded query",
"genre": "category",
"tag": ["tag 1", "tag 2"]]).track()
```

## Monitoring RAT traffic

You can monitor the tracker network activity by listening to the `RAnalyticsWillUploadNotification`, `RAnalyticsUploadFailureNotification` and `RAnalyticsUploadSuccessNotification` notifications.

## Verifying successful integration

If the SDK correctly integrated, the events sent to RAT for a logged-in user will contain an `easyid` field containing the user's member identfier. See [here](#using-kibana-to-verify-successful-integration) for a guide on how to check the events sent to RAT.

## Core Telephony values tracking: CTCarrier deprecation

We used [CTCarrier](https://developer.apple.com/documentation/coretelephony/ctcarrier) API to track values:

- `carrierName`
- `mobileCountryCode`
- `mobileNetworkCode`
- `isoCountryCode`
- `allowsVOIP`

Since iOS 16.4 `CTCarrier` is a **deprecated** API ([iOS 16.4 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-16_4-release-notes)) and **will be removed in future without any replacement**. As a part of the deprecation process `CTCarrier` values will always return `empty string` or `65535` as **default value**. 

`CTCarrier` has been used to provide `mcn`, `mcnd`, `simopn` and `simop` values. According to the `CTCarrier` changes, we **stop support** of `CTCarrier` API and will **remove** it after Apple removes this API from `Core Telephony` in the future iOS updates.

**Example of `mcn`, `mcnd`, `simopn` and `simop` values before/after CTCarrier deprecation:**

| Key | Description | Value before iOS 16.4 | Value after iOS 16.4 |
| -------- | -------- | -------- | -------- |
| `mcn` | The name of the primary carrier | `Rakuten` | `--` |
| `mcnd` | The name of the secondary carrier | `Rakuten` or empty string | `--` |
| `simopn` | The Service Provider Name | `Rakuten` | `--` |
| `simop` | The SIM operator code  | `44011` | `6553565535` |
