# Advanced configuration and usage

1. [Configure a custom endpoint](#configure-a-custom-endpoint)
1. [Location tracking](#location-tracking)
1. [IDFA tracking](#idfa-tracking)
1. [Configure page view tracking](#configure-page-view-tracking)
1. [Configure automatic tracking](#configure-automatic-tracking)
1. [Duplicate events across multiple RAT Accounts](#duplicate-events-across-multiple-rat-accounts)
1. [Manually set a user identifier](#manually-set-a-user-identifier)
1. [Configure debug logging](#configure-debug-logging)
1. [App to web tracking](#app-to-web-tracking)
1. [Configure the tracker batching delay](#configure-the-tracker-batching-delay)
1. [Support for App Extensions](#support-for-app-extensions)
1. [Creating a custom tracker](#creating-a-custom-tracker)
1. [Fetching a RP Cookie](#fetching-a-rp-cookie)
1. [App-to-App referral tracking](#app-to-app-referral-tracking)
1. [Event triggers](#event-triggers)

## Configure a custom endpoint

To use a custom endpoint when talking to the analytics backend add a `RATEndpoint` key to the app's info.plist and set it to the custom endpoint. e.g. to use the RAT staging environment set `RATEndpoint` to `[https://stg.rat.rakuten.co.jp/](https://stg.rat.rakuten.co.jp/)`.

A custom endpoint can also be configured at runtime as below:

```swift
AnalyticsManager.shared().set(endpointURL: URL(string: "https://rat.rakuten.co.jp/"))
```

⚠️ The runtime endpoint you set is not persisted and is intended only for developer/QA testing.

**Note**: If you have implemenented a [custom tracker](#creating-a-custom-tracker) ensure that you have added your tracker to the manager before calling the set endpoint function.


## Location tracking

> **Warning:** The SDK does not _actively_ track the device's location even if the user has granted access to the app and the RAnalyticsManager::shouldTrackLastKnownLocation property is set to `true`. Instead, it passively monitors location updates captured by your application. 

> Your app must first request permission to use location services for a valid reason, as shown in Apple's [CoreLocation documentation](https://developer.apple.com/documentation/corelocation?language=objc). **Monitoring the device location for no other purpose than tracking will get your app rejected by Apple.**

> See the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html) for more information on how to request location updates.


Location tracking is enabled by default. If you want to prevent our SDK from tracking the last known location, you can set RAnalyticsManager::shouldTrackLastKnownLocation to `false`:

```swift
AnalyticsManager.shared().shouldTrackLastKnownLocation = false
```

## IDFA tracking

The SDK automatically tracks the [advertising identifier (IDFA)](https://developer.apple.com/reference/adsupport/asidentifiermanager) by default but you can still disable it by setting RAnalyticsManager::shouldTrackAdvertisingIdentifier to `false`:

```swift
AnalyticsManager.shared().shouldTrackAdvertisingIdentifier = false
```

#### IDFA tracking on iOS 14.x and above

⚠️ If the available IDFA value is valid (non-zero'd) the RAnalytics SDK will use it. This change was implemented in response to Apple's [announcement](https://developer.apple.com/news/?id=hx9s63c5) that they have delayed the below requirement to obtain permission for user tracking until early 2021.


If the app is built with the iOS 14 SDK and embeds the [AppTrackingTransparency framework](https://developer.apple.com/documentation/apptrackingtransparency), the Analytics SDK uses IDFA on iOS 14.x and greater only when the user has authorized tracking. Your app can display the IDFA tracking authorization popup by adding a `NSUserTrackingUsageDescription` key in your Info.plist and calling the [requestTrackingAuthorization function](https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/3547037-requesttrackingauthorization).

```swift
ATTrackingManager.requestTrackingAuthorization { status in
    switch status {
    case .authorized:
        // Now that tracking is authorized we can get the IDFA
        let idfa = ASIdentifierManager.shared().advertisingIdentifier
        
    default: () // IDFA is not authorized
    }
}
```

## Configure page view tracking

By default the SDK automatically tracks page views/visits (`pv` etype in RAT). The automatic tracking can be disabled by setting `RAnalyticsManager#shouldTrackPageView` to `false`. This property is now deprecated and we recommend to use the below feature [Configure automatic tracking](#configure-automatic-tracking) instead.


## Configure automatic tracking

##### Public API

If your app is coded in Objective-C, please import this header file in order to use our public Swift classes: 

```objc
#import <RAnalytics/RAnalytics-Swift.h>
```

If your app is coded in Swift, please import the RAnalytics framework: 

```swift
import RAnalytics
```

### Automatics events tracking configuration

#### Build time configuration

* Create and add this file to your Xcode project: `RAnalyticsConfiguration.plist`
* Open the file and add the events you do not want to track to a `RATDisabledEventsList` string array. For example, to disable all the automatic events: 

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>RATDisabledEventsList</key>
    <array>
    <string>_rem_init_launch</string>
    <string>_rem_launch</string>
    <string>_rem_end_session</string>
    <string>_rem_update</string>
    <string>_rem_login</string>
    <string>_rem_login_failure</string>
    <string>_rem_logout</string>
    <string>_rem_install</string>
    <string>_rem_visit</string>
    <string>_rem_push_notify</string>
    <string>_rem_sso_credential_found</string>
    <string>_rem_login_credential_found</string>
    <string>_rem_credential_strategies</string>
    <string>_analytics_custom</string>
    </array>
</dict>
</plist>
```

#### Runtime configuration

It's also possible to enable or disable events at runtime:

* Enable all events at runtime 

```swift
AnalyticsManager.shared().shouldTrackEvent = { _ in true }
```

* Disable all events at runtime 

```swift
AnalyticsManager.shared().shouldTrackEvent = { _ in false }
```

* Disable a given event at runtime 

```swift
AnalyticsManager.shared().shouldTrackEvent = { eventName in
    eventName != AnalyticsManager.Event.Name.sessionStart
}
```

Note: The runtime configuration overrides the build time configuration. If an event is disabled in the build time configuration and enabled in the runtime configuration the event will be tracked by RAnalytics.

In order to override the build time configuration at runtime set `AnalyticsManager.shared().shouldTrackEvent` in `application(_:willFinishLaunchingWithOptions:)`: 

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AnalyticsManager.shared().shouldTrackEvent = { eventName in
            ...
        }
        return true
    }
}
```

## Duplicate events across multiple RAT Accounts

The `RAnalyticsRATTracker` can be configured to mirror events to multiple RAT accounts. Once configured, the SDK will automatically duplicate any events destined for the original accountId and applicationId defined in the `Info.plist` to all added duplicate accounts.

#### Buildtime config

Add `RAnalyticsConfiguration.plist` to your Xcode project. Within this `plist` file, add an array and for each account, create a dict with `RATAccountIdentifier` and `RATAppIdentifier` keys and an optional `RATNonDuplicatedEventsList` keyed array to disable tracking on specific events.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>RATDuplicateAccounts</key>
    <array>
        <dict>
        <key>RATAccountIdentifier</key>
        <integer>199</integer>
        <key>RATAppIdentifier</key>
        <integer>2</integer>
        </dict>
        <dict>
        <key>RATAccountIdentifier</key>
        <integer>200</integer>
        <key>RATAppIdentifier</key>
        <integer>1</integer>
        <key>RATNonDuplicatedEventsList</key>
        <array>
            <string>_rem_init_launch</string>
            <string>_rem_launch</string>
        </array>
    </dict>
    </array>
</dict>
</plist>
```

#### Runtime config

User can also add secondary accounts at runtime. Custom events will be mirrored to accounts declared at runtime. Ignores the build-time `RATNonDuplicatedEventsList` key when set.

⚠️ Won't duplicate an event if that event on the main account is disabled.

```swift
RAnalyticsRATTracker.shared().addDuplicateAccount(accountId: myRATACC2, applicationId: myRATAID2)
RAnalyticsRATTracker.shared().addDuplicateAccount(accountId: myRATACC3, applicationId: myRATAID3)
```

Disabling an event at runtime:

```swift
RAnalyticsRATTracker.shared().shouldDuplicateRATEventHandler = { eventName, duplicateAccountId
    return eventName != "_rem_end_session" && duplicateAccountId == 999
}
```

## Manually set a user identifier

From version 5.2.0 there is a new `setUserIdentifier:` API available for your app to manually set the tracking user identifier. After calling the API the user identifier that you set will be used for subsequent tracked events.

```swift
RAnalyticsManager.sharedInstance.setUserIdentifier("a_user_identifier")
```

Use cases:

* App retrieves the encrypted easy ID using other SDKs or REST API then sets it using the `setUserIdentifier:` method.
* App can do this every time the app is launched/opened, or when new a user logs in.
* App should set the user identifier to nil when the user logs out.

## Configure debug logging

To configure the module's internal debug logging use `AnalyticsManager#set(loggingLevel:)`.

To set logging to debug level (and above i.e. also print info/warning/error logs) use the following function call: 

```swift
AnalyticsManager.shared().set(loggingLevel: .debug)
```

⚠️ For user privacy and app security the module will _not_ print **verbose** or **debug** logs in a release build.

By default the module will show error logs, even in a release build. To disable the module's logs completely call: 

```swift
AnalyticsManager.shared().set(loggingLevel: .none)
```

⚠️ The plist flag `RMSDKEnableDebugLogging` has been deprecated and has no effect now. You must use the above `AnalyticsManager` API function to configure logging levels.

## App to web tracking

You can configure the SDK to inject a special tracking cookie which allows RAT to track events between the app and in-app webviews. The cookie is only injected on iOS 11.0 and later versions. This feaure is OFF by default. It can be enabled by setting RAnalyticsManager::enableAppToWebTracking to true.

```swift
AnalyticsManager.shared().enableAppToWebTracking = true
```

By default the cookie's domain will be set to the top-level Rakuten domain. Optionally, you can set a custom domain on the tracking cookie with RAnalyticsManager::setWebTrackingCookieDomainWithBlock:

```swift
AnalyticsManager.shared().setWebTrackingCookieDomain { () -> String? in
    return ".my-domain.co.jp"
}
```

## Configure the tracker batching delay

A tracker collects events and sends them to a backend in batches.

The batching delay is a configurable value with default set to 1 second.

⚠️ In our [internal testing](https://jira.rakuten-it.com/jira/browse/SDKCF-1596) we noticed no significant impact on battery usage when the batching delay was reduced to 1 sec in our demo app. However you should perform your own developer testing and QA to determine the appropriate batching delay for your app.


You can configure a different delay with the `AnalyticsTracker#setBatchingDelay:` and `AnalyticsTracker#setBatchingDelayWithBlock:` methods.


### Example 1: Configure batching interval of 10 seconds

```swift
RAnalyticsRATTracker.shared().set(batchingDelay: 10.0)
```

### Example 2: Dynamic batching interval

#### - no batching for the first 10 seconds after app launch

#### - 10 second batching between 10 and 30 seconds after app launch

#### - 60 second batching after 30 seconds after app launch

```swift
public class CustomClass: NSObject {

    fileprivate var startTime: TimeInterval

    override init() {
        startTime = NSDate().timeIntervalSinceReferenceDate
        super.init()
    }

    public func setup() {
        RAnalyticsRATTracker.shared().set(batchingDelayBlock: { () -> TimeInterval in
            let secondsSinceStart = NSDate().timeIntervalSinceReferenceDate - startTime

            if (secondsSinceStart < 10)
            {
                return 0
            }
            else if (secondsSinceStart < 30)
            {
                return 10
            }
            else
            {
                return 60
            }
        })
    }
}
```

## Support for App Extensions

The SDK can be added as a dependency to an App Extension target (e.g. Today Widget) and will compile successfully. The SDK's APIs such as track (to track a custom event) can be used from an App Extension.


#### Requirements

App Extensions need to follow the requirements at [Configuring RAT](readme.html#configuring-rat).

* You MUST configure your RAT `accountId` and `applicationId` in the **App Extension** info.plist (in addition to your main app's info.plist)
* To send events to a different endpoint you can set a `RATEndpoint` key in the **App Extension** info.plist

#### Viewing App Extension events in Kibana

To search for App Extension events in [Kibana](https://confluence.rakuten-it.com/confluence/display/RAT/How+to+Check+Data+that+is+being+Sent+to+RAT#HowtoCheckDatathatisbeingSenttoRAT-Step2:[ServerSide]ChecktheeventonRATserver) use your **App Extension** name and not the application name e.g. use `app_name:jp.co.rakuten.sdk.ecosystemdemo.today` as the search term not `app_name:jp.co.rakuten.sdk.ecosystemdemo`.

#### Limitations

A known limitation due to app sandboxing is that the SDK cannot automatically fill the `userid` (normally contains a logged-in user's encrypted easy id) field in the payload of automatically tracked events such as `_rem_launch` when an event is sent by an App Extension.

#### Track encrypted easy id

To send the encrypted easy id in custom events you can add a Podfile dependency on [RAuthenticationCore](https://documents.developers.rakuten.com/ios-sdk/authentication-latest/#authentication-installing) to the App Extension target, load the user's account using `RAuthenticationAccount` method `loadAccountWithName:service:error:` and then manually set the `userid` key to the loaded account's `trackingIdentifier`:

```swift
RAnalyticsRATTracker.shared().event(eventType: "custom_name", parameters: ["userid": account.trackingIdentifier]).track()
```

## Creating a custom tracker

Custom trackers can be added to the manager.

Create a class and implement the `AnalyticsTracker` protocol. Its `process(event:state:)` method will receive an event with a name and parameters, and a state with attributes automatically generated by the SDK.

The custom tracker in the code sample below only prints a few diagnostic messages. A real custom tracker would upload data to a server.

```swift
public class CustomTracker: NSObject, AnalyticsTracker {
    public static let MyEventName = "customtracker.myeventname"
    public func process(event: AnalyticsManager.Event, state: AnalyticsManager.State) -> Bool {
        switch event.name {
        case AnalyticsManager.Event.Name.initialLaunch:
            print("I've just been launched!")
            return true
        case AnalyticsManager.Event.Name.login:
            print("User with tracking id '\(state.userid)' just logged in!")
            return true
        case MyEventName:
            print("Received my event!")
            return true
        // ...
        }

        // Unknown event
        return false
    }
}
```

The custom tracker can then be added to the `RAnalyticsManager`:

```swift
// Add CustomTracker to the manager
RAnalyticsManager.shared().add(CustomTracker())

// Tracking events can now be sent to the custom tracker
AnalyticsManager.Event(name: CustomTrackerMyEventName, parameters: nil).track()
```

## Fetching a RP Cookie

RAnalytics provides a public API to fetch the RP Cookie by instantiating `RAnalyticsRpCookieFetcher` class.

Note: the completion handler of `getRpCookieCompletionHandler` may be called on a background queue.

```swift
// Create a RP Cookie Fetcher
let fetcher = RAnalyticsRpCookieFetcher(cookieStorage: HTTPCookieStorage.shared)

// Get the RP Cookie
fetcher?.getRpCookieCompletionHandler({ cookie, _ in
    guard let cookie = cookie else {
        return
    }
    print(cookie)
})
```

## App-to-App referral tracking

App to app referral tracking of deeplinks from 'referral' apps to 'referred' apps allows teams to track the behavior of users.

Note that:
- The Analytics SDK _automatically_ tracks incoming deeplinks in the referred app as long as they are in the expected format.
- To generate deeplinks in the referral app in the correct format you should use the `ReferralAppModel` helpers.

### Create and open URL Scheme deeplink in 'referral' app
```swift
guard let  url = ReferralAppModel().urlScheme(appScheme: "app"), UIApplication.shared.canOpenURL(url) else {
    return
}
UIApplication.shared.open(url, options: [:])
```

### Create and open Universal Link deeplink in 'referral' app
```swift
guard let  url = ReferralAppModel().universalLink(domain: "domain.com"), UIApplication.shared.canOpenURL(url) else {
    return
}
UIApplication.shared.open(url, options: [:])
```

### Optional parameters

It is also possible to include the following _optional_ parameters when creating a deeplink:
- `link` - unique identifier of the referral trigger e.g., `"campaign-abc123"`
- `component` - component in the referral app e.g., `"checkout"`
- `customParameters` - `[String: String]` dictionary of key-value pairs e.g., `["custom1": "value1"]`

```swift
guard let model = ReferralAppModel(link: "campaign-abc123",
                                   component: "checkout",
                                   customParameters: ["custom1": "value1"]) else {
    return
}
// create deeplink url from model using `urlScheme(appScheme:)` or `universalLink(domain:)`
```

See the [feature page](https://confluence.rakuten-it.com/confluence/display/MAGS/RAnalytics+SDK%3A+App+to+App+tracking#RAnalyticsSDK:ApptoApptracking-FunctionalSpec) sections "Standard Referral Parameters" and "Custom Referral Parameters" for more details.

### Events sent to RAT

If Analytics SDK v8.3.0 or later is integrated in the referred-to app, the SDK automatically sends two events to RAT:
- an etype `pv` visit event sent to the **referred** app's RAT account
- an etype `deeplink` event sent to the **referral** app's RAT account

See the [feature page](https://confluence.rakuten-it.com/confluence/display/MAGS/RAnalytics+SDK%3A+App+to+App+tracking) or [RAT's guide](https://confluence.rakuten-it.com/confluence/x/SOs1rw) to understand more about app-to-app referral tracking with RAT.

## Event triggers

### UIApplication NSNotification

#### UIApplication.didFinishLaunchingNotification

A notification that posts immediately after the app finishes launching.
https://developer.apple.com/documentation/uikit/uiapplication/1622971-didfinishlaunchingnotification

When UIApplication.didFinishLaunchingNotification is received, these events are sent under certain conditions:

- _rem_init_launch is sent when the app is installed for the first time

- _rem_install is sent when the app is launched for the second time

- _rem_install and _rem_update are sent when the app has been updated to a new version

- _rem_launch is sent in any cases

- _rem_credential_strategies is sent in any cases with this boolean parameter:
    - key: strategies.password-manager
    - value: true or false

#### UIApplication.willEnterForegroundNotification

A notification that posts shortly before an app leaves the background state on its way to becoming the active app.
https://developer.apple.com/documentation/uikit/uiapplication/1622944-willenterforegroundnotification

- _rem_launch is sent in any cases

#### UIApplication.didBecomeActiveNotification

A notification that posts when the app becomes active.
https://developer.apple.com/documentation/uikit/uiapplication/1622953-didbecomeactivenotification

- _rem_push_notify is sent only if:
    - the app was previously opened from a push notification
    - UNUserNotificationCenter.current().delegate is set

#### UIApplication.didEnterBackgroundNotification

A notification that posts when the app enters the background.
https://developer.apple.com/documentation/uikit/uiapplication/1623071-didenterbackgroundnotification

- _rem_end_session is sent in any cases

### viewDidAppear

Notifies the view controller that its view was added to a view hierarchy.
https://developer.apple.com/documentation/uikit/uiviewcontroller/1621423-viewdidappear

- pv (page visit) is sent in any cases when a view controller did appear (viewDidAppear)

### APNS Remote Notifications

- _rem_push_notify is sent when:
    - the application is opened from a push notification
    - one of these AppDelegate's methods is called:
        - application:didReceiveRemoteNotification:
        - application:didReceiveRemoteNotification:fetchCompletionHandler:
        - userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler

### SDKs NSNotification

#### RAE SDK notifications

- _rem_login is sent when:
    - RAE login succeeds
    - one of these NSNotifications is received:
        - com.rakuten.esd.sdk.events.login.password
        - com.rakuten.esd.sdk.events.login.one_tap
        - com.rakuten.esd.sdk.events.login.other

- _rem_login_failure is sent when:
    - RAE login fails
    - this NSNotification is received: com.rakuten.esd.sdk.events.login.failure

- _rem_logout is sent when:
    - RAE logout succeeds
    - one of these NSNotifications is received:
        - com.rakuten.esd.sdk.events.logout.local
        - com.rakuten.esd.sdk.events.logout.global

- _rem_sso_credential_found is sent when:
    - the RAE login webview page is loaded
    - this NSNotification is received: is com.rakuten.esd.sdk.events.ssocredentialfound

- _rem_login_credential_found is sent when:
    - password extension button is tapped
    - this NSNotification is received: is com.rakuten.esd.sdk.events.logincredentialfound

- pv (page visit) is sent when:
    - the forgot password button or the privacy policy button or the help button or the create account button is tapped
    - this NSNotification is received: com.rakuten.esd.sdk.events.ssodialog

#### IDSDK notifications

- _rem_login is sent when:
    - IDSDK login succeeds
    - this NSNotification is received: com.rakuten.esd.sdk.events.login.idtoken_memberid

- _rem_login_failure is sent when:
    - IDSDK login fails
    - this NSNotification is received: com.rakuten.esd.sdk.events.login.failure.idtoken_memberid

- _rem_logout is sent when:
    - IDSDK logout succeeds
    - this NSNotification is received: com.rakuten.esd.sdk.events.logout.idtoken_memberid

### RDiscover SDK notifications

- _rem_discover_discoverpage_visit is sent when:
    - willMoveToWindow: is called in the Discover view (https://developer.apple.com/documentation/uikit/uiview/1622563-willmovetowindow)
    - this notification is received: com.rakuten.esd.sdk.events.discover.visitPage

- _rem_discover_discoverpage_tap is sent in any cases when:
    - collectionView:didSelectItemAtIndexPath: is called in the Discover view (https://developer.apple.com/documentation/uikit/uicollectionviewdelegate/1618032-collectionview?language=objc)
    - this NSNotification is received: com.rakuten.esd.sdk.events.discover.tapPage
    
- _rem_discover_discoverpage_redirect is sent when:
    - collectionView:didSelectItemAtIndexPath: is called in the Discover view (https://developer.apple.com/documentation/uikit/uicollectionviewdelegate/1618032-collectionview?language=objc)
    - the landing page is opened
    - this NSNotification is received: com.rakuten.esd.sdk.events.discover.redirectPage

#### Custom notification

- _analytics_custom is sent when:
    - this NSNotification is received: com.rakuten.esd.sdk.events.custom
