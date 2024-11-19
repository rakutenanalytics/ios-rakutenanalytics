# Advanced configuration and usage

1. [Configure a custom endpoint](#configure-a-custom-endpoint)
1. [Location tracking](#location-tracking)
1. [IDFA tracking](#idfa-tracking)
1. [Configure page view tracking](#configure-page-view-tracking)
1. [Configure App-to-App referral tracking](#configure-app-to-app-referral-tracking)
1. [Configure automatic tracking](#configure-automatic-tracking)
1. [Duplicate events across multiple RAT Accounts](#duplicate-events-across-multiple-rat-accounts)
1. [Handling errors](#handling-errors)
1. [Configure debug logging](#configure-debug-logging)
1. [App to web tracking](#app-to-web-tracking)
1. [Configure the tracker batching delay](#configure-the-tracker-batching-delay)
1. [Support for App Extensions](#support-for-app-extensions)
1. [Creating a custom tracker](#creating-a-custom-tracker)
1. [Fetching a RP Cookie](#fetching-a-rp-cookie)
1. [App-to-App referral tracking](#app-to-app-referral-tracking)
1. [How to configure the database directory path](#how-to-configure-the-database-directory-path)
1. [How to set the app user agent in WKWebView](#how-to-set-the-app-user-agent-in-wkwebview)
1. [Event triggers](#event-triggers)

## Configure a custom endpoint

To use a custom endpoint when talking to the analytics backend add a `RATEndpoint` key to the app's info.plist and set it to the custom endpoint.

A custom endpoint can also be configured at runtime as below:

```swift
AnalyticsManager.shared().set(endpointURL: URL(string: "%custom_endpoint_url%"))
```

⚠️ The runtime endpoint you set is not persisted and is intended only for developer/QA testing.

**Note**: If you have implemenented a [custom tracker](#creating-a-custom-tracker) ensure that you have added your tracker to the manager before calling the set endpoint function.

## Location tracking

> Your app must first request permission to use location services for a valid reason, as shown in Apple's [CoreLocation documentation](https://developer.apple.com/documentation/corelocation?language=objc). **Monitoring the device location for no other purpose than tracking will get your app rejected by Apple.**

> See the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html) for more information on how to request location updates.

### Last Known Location Tracking

> **Warning:** The SDK does not _actively_ track the device's location even if the user has granted access to the app and the `shouldTrackLastKnownLocation` property is set to `true`. Instead, it passively monitors location updates captured by your application. 

Location tracking is enabled by default. If you want to prevent our SDK from tracking the last known location, you can set `shouldTrackLastKnownLocation` to `false`:

```swift
AnalyticsManager.shared().shouldTrackLastKnownLocation = false
```

### Geo Location Tracking

The SDK uses `GeoManager` to actively track location events for differnt states of the app based on access level to location services.

| Authorization Status | Tracks in App State |
| :---:   | :---: |
| `notDetermined`, `restricted`, `denied` | None. |
| `authorizedAlways` | Foreground, background and terminated. |
| `authorizedWhenInUse` | Foreground and background. |

Whilst tracking for location events the `GeoManager` captures location updates at regular intervals and/or on significant change in device's location when the app is being used actively. 

If the app is not being used actively the `GeoManager` depends only on significant change in device's location to gather location updates.

The `GeoManager` consists of a `GeoTracker` that spools the captured location updates every `60 seconds` which is set as default batching delay.

**NOTE:** Developer needs to enable `Location Updates` for `Background Modes` in `Signing & Capabilities` in Xcode. Also the `GeoManager` cannot track the device's location for terminated state if the user has not granted `Always Authorization` to the location services.

#### Start Location Collection

The `GeoManager` is a shared singleton that comes with a default `GeoConfiguration` to track location events. It also allows you to set a desired configuration for tracking location events.

Starts the process of location collection based on either the default configuration or a custom configuration.

###### Using Default Configuration

Start the location collection using default configuration as shown below:

```
GeoManager.shared.startLocationCollection()
```

The default `GeoConfiguration` object captures `.best` accurate location updates from `00:00` to `23:59` at regular intervals of `300 seconds` and/or on covering a distance of every `300 meters`.

###### Using Custom Configuration

> **Warning:** When creating a custom configuration, if any of the configuration's property does not meet the criteria to fall within specified range. The default value for the property will be used.

**NOTE**: 
1. `timeInterval` should be in the range of `60 to 1800` seconds.
2. `distanceInterval` should be in the range of `200 to 500` meters.
3. `accuracy` should be a value specified in type `GeoAccuracy`.
4. `startTime` should not be equal to or exceed `endTime`.

> **Warning:** The timer interval based collection only works when the app is in foreground. The distance based collection will work in all states of the app provided user has granted always access to location services.

The `GeoConfiguration` object to capture `.hundredMeters` accurate location updates from `08:00` to `20:00` at regular intervals of `300 seconds` and/or on covering a distance of every `400 meters` can be created as shown below:

```
let configuration = GeoConfiguration(distanceInterval: 400, 
                                     timeInterval: 300, 
                                     accuracy: .hundredMeters, 
                                     startTime: GeoTime(hours: 8, minutes: 0), 
                                     endTime: GeoTime(hours: 20, minutes: 0))
```

Start the location collection using a custom configuration as shown below:

```
GeoManager.shared.startLocationCollection(configuration: configuration)
```

- Note: This function should be called on the main thread, otherwise starting the location collection is not guaranteed.

#### Stop Location Collection

Stops any ongoing location collection process and deletes the custom configuration set.

```
GeoManager.shared.stopLocationCollection()
```

- Note: This function should be called on the main thread, otherwise stopping the location collection is not guaranteed.

#### Get Configuration

Returns the custom configuration that was set on starting the location collection. If no configuration was set, it returns nil.

```
guard let configuration = GeoManager.shared.getConfiguration() else {
    return
}
```

#### Request Location

Request a one-time delivery of the user’s current location.

```
GeoManager.shared.requestLocation { result in
    switch result {
    case .success(let locationModel):
        // Handle location request
    case .failure(let error):
        // Handle error on location request
    }
}
```

Requesting for a location update can include an optional `GeoActionParameters` as shown below:

```
let actionParameters = GeoActionParameters(actionType: "ButtonClick",
                                           actionLog: "Login page button click",
                                           actionId: "123",
                                           actionDuration: "3 seconds",
                                           additionalLog: "SSO Login")
                                           
GeoManager.shared.requestLocation(actionParameters: actionParameters) { result in
    switch result {
    case .success(let locationModel):
        // Handle location request
    case .failure(let error):
        // Handle error on location request
    }
}
```

- Note: This function should be called on the main thread, otherwise requesting the location collection is not guaranteed.

## IDFA tracking

The SDK automatically tracks the [advertising identifier (IDFA)](https://developer.apple.com/reference/adsupport/asidentifiermanager) by default but you can still disable it by setting `shouldTrackAdvertisingIdentifier` to `false`:

```swift
AnalyticsManager.shared().shouldTrackAdvertisingIdentifier = false
```

#### IDFA tracking on iOS 14.x and above

⚠️ If the available IDFA value is valid (non-zero'd) the RakutenAnalytics SDK will use it. This change was implemented in response to Apple's [announcement](https://developer.apple.com/news/?id=hx9s63c5) that they have delayed the below requirement to obtain permission for user tracking until early 2021.


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

By default the SDK automatically tracks page views/visits (`pv` etype in RAT).
The automatic tracking can be disabled by adding `_rem_visit` to disabled events list.
More details can be found in [Configure automatic tracking](#configure-automatic-tracking) section.

## Configure App-to-App referral tracking

By default the SDK automatically tracks the app-to-app referral tracking: `pv` and `deeplink` events are tracked.
The automatic tracking can be disabled by adding `_rem_applink` to disabled events list.
More details can be found in [Configure automatic tracking](#configure-automatic-tracking) and [App-to-App referral tracking](#app-to-app-referral-tracking) sections.

## Configure automatic tracking

##### Public API

If your app is coded in Objective-C, please import this header file in order to use our public Swift classes: 

```objc
#import <RakutenAnalytics/RAnalytics-Swift.h>
```

If your app is coded in Swift, please import the RakutenAnalytics framework: 

```swift
import RakutenAnalytics
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
    <string>_rem_applink</string>
    <string>_rem_push_received</string>
    <string>_rem_push_auto_register</string>
    <string>_rem_push_auto_unregister</string>
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
AnalyticsManager.shared().shouldTrackEventHandler = { _ in true }
```

* Disable all events at runtime 

```swift
AnalyticsManager.shared().shouldTrackEventHandler = { _ in false }
```

* Disable a given event at runtime 

```swift
AnalyticsManager.shared().shouldTrackEventHandler = { eventName in
    eventName != AnalyticsManager.Event.Name.sessionStart
}
```

Note: The runtime configuration overrides the build time configuration. If an event is disabled in the build time configuration and enabled in the runtime configuration the event will be tracked by RakutenAnalytics.

In order to override the build time configuration at runtime set `AnalyticsManager.shared().shouldTrackEventHandler` in `application(_:willFinishLaunchingWithOptions:)`: 

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AnalyticsManager.shared().shouldTrackEventHandler = { eventName in
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

# Handling errors

The SDK will automatically raise errors if the `errorHandler` is set as below:

```swift
AnalyticsManager.shared().errorHandler = { error in
    // Example: Report the error to Crashlytics
}
```

Use it to report the SDK errors to a backend such as Crashlytics as a [non-fatal error](https://firebase.google.com/docs/crashlytics/customize-crash-reports?platform=ios#log-excepts).

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

You can configure the SDK to inject a special tracking cookie called `ra_uid`, which allows RAT to track events between the app and in-app webviews. This functionality allows you to track either a single domain or multiple domains. The cookie is only injected on iOS 11.0 and later versions. This feaure is OFF by default. It can be enabled by setting `enableAppToWebTracking` to true.

```swift
AnalyticsManager.shared().enableAppToWebTracking = true
```

By default the cookie's domain will be set to the top-level Rakuten domain. Optionally, you can set a custom domain(s) on the tracking cookie with `setWebTrackingCookieMultipleDomains(:)` method:

```swift
// To set a custom tracking cookie to a domain
AnalyticsManager.shared().setWebTrackingCookieMultipleDomains(array: [".my-domain.co.jp"])

// To set custom tracking cookies to more than 1 domain
AnalyticsManager.shared().setWebTrackingCookieMultipleDomains(array: [".my-domain.co.jp", ".example-domain.com"])
```

Both `setWebTrackingCookieMultipleDomains` and `setWebTrackingCookieMultipleDomains` have an optional completion handler. This handler returns the array of edited tracking `HTTPCookie`.

```swift
AnalyticsManager.shared().setWebTrackingCookieMultipleDomains(array: [".my-domain.co.jp", ".example-domain.com"]) { [weak self] trackingCookies in
    // Edited cookie is available here as [HTTPCookie], the number of elements depends on the passed domain(s)
}
```

⚠️ The previous set domain API `setWebTrackingCookieDomain` is deprecated so if you are using that method, we suggest to update to use `setWebTrackingCookieMultipleDomains(:)` instead.

Two key parameters used in the `ra_uid` cookie are `ckp` and `cka`:
- **ckp**: This is the unique device identifier, used to track the device across all Rakuten applications.
- **cka**: This is the Advertising ID (IDFA), a unique, user-resettable identifier. It is used for advertising and analytics purposes. If the IDFA is not available, a default value of `00000000-0000-0000-0000-000000000000` is used.

#### `ra_uid` Cookie Format
The cookie is formatted using the `COOKIE_FORMAT`, which is defined as:
```swift
COOKIE_FORMAT = "rat_uid=%s;a_uid=%s"
```
In this format:  
* `rat_uid` takes the value of `ckp`.
* `a_uid` takes the value of `cka`.

#### Example of the `ra_uid` cookie value

For each domain you configure, the cookie will appear as follows in the request content:

```swift
// IDFA is available
ra_uid=rat_uid%3D82b93c49c8cc62a76e26346433dee49c%3Ba_uid%3Dad7ab8a4-83c8-4ae2-b31f-20b453a62621

// IDFA is not available
ra_uid=rat_uid%3D82b93c49c8cc62a76e26346433dee49c%3Ba_uid%3D00000000-0000-0000-0000-000000000000
```

## Configure the tracker batching delay

A tracker collects events and sends them to a backend in batches.

The batching delay is a configurable value with default set to 1 second.

⚠️ In our internal testing, we noticed no significant impact on battery usage when the batching delay was reduced to 1 sec in our demo app. However you should perform your own developer testing and QA to determine the appropriate batching delay for your app.

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

To search for App Extension events in Kibana use your **App Extension** name and not the application name.

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

RakutenAnalytics provides a public API to fetch the RP Cookie by instantiating `RAnalyticsRpCookieFetcher` class.

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

### SceneDelegate

If your app uses SceneDelegate, your app's `Info.plist` should contain `UISceneDelegateClassName` key in `UIApplicationSceneManifest` dictionary in order to make the `App-to-App referral tracking` working:
```
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array>
                <dict>
                    <key>UISceneDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                    ...
                </dict>
            </array>
        </dict>
    </dict>
```

### Create and open URL Scheme deeplink in 'referral' app
```swift
guard let  url = ReferralAppModel().urlScheme(appScheme: "app", pathComponent: "path", ref: "any"), UIApplication.shared.canOpenURL(url) else {
    return
}
UIApplication.shared.open(url, options: [:])
```

#### Parameters:

- `appScheme`: The app scheme name defined in `CFBundleURLSchemes` in the app's `Info.plist`.
- `pathComponent`: An optional path component to be appended to the app scheme. This can be used to specify a particular resource or endpoint within the domain. Example: `path/to/resource`. If this parameter is `nil` or an empty string, no path component will be added to the URL.
- `ref`: The referral identifier to be included in the URL. If this parameter is `nil` or an empty string, application bundle identifier will be added.

#### Example:

```
demoapp://app?ref=any&ref_acc=123&ref_aid=456&ref_link=campaignCode&ref_comp=news&custom_param1=japan&ref_custom_param2=rome&ref_custom_param1=italy&custom_param2=tokyo
```

Tracked Event (Kibana):

```
{
  ...
  "_source": {
    ...
    "ref": "any",
    "acc": 123,
    ...
    "etype": "deeplink",
    "aid": 456,
    ...
    "cp": {
      "custom_param1": "japan",
      "ref_type": "external",
      "ref_custom_param2": "rome",
      "custom_param2": "tokyo",
      "ref_comp": "news",
      "ref_link": "campaignCode",
      "ref_custom_param1": "italy"
    },
    ...
  },
  ...
}
```

### Create and open Universal Link deeplink in 'referral' app
```swift
guard let  url = ReferralAppModel().universalLink(domain: "domain.com", pathComponent: "path", ref: "any"), UIApplication.shared.canOpenURL(url) else {
    return
}
UIApplication.shared.open(url, options: [:])
```

#### Parameters:

- `domain`: The associated domain for the Universal Link. Example: `rakuten.co.jp`.
- `pathComponent`: An optional path component to be appended to the domain. This can be used to specify a particular resource or endpoint within the domain. Example: `path/to/resource`. If this parameter is `nil` or an empty string, no path component will be added to the URL.
- `ref`: The referral identifier to be included in the URL. If this parameter is `nil` or an empty string, application bundle identifier will be added.

#### Example:

```
https://domain.com/path?ref=any&ref_acc=123&ref_aid=456&ref_link=campaignCode&ref_comp=news&custom_param1=japan&custom_param2=tokyo&ref_custom_param2=rome&ref_custom_param1=italy
```

Tracked Event (Kibana):

```
{
  ...
  "_source": {
    ...
    "ref": "any",
    "acc": 123,
    ...
    "aid": 456,
    ...
    "etype": "deeplink",
    ...
    "cp": {
      "custom_param1": "japan",
      "ref_type": "external",
      "ref_custom_param2": "rome",
      "custom_param2": "tokyo",
      "ref_comp": "news",
      "ref_link": "campaignCode",
      "ref_custom_param1": "italy"
    },
    ...
  },
  ...
}
```

### Query in the Referral App Model

The query property in the `ReferralAppModel` creates a URL query string by encoding and joining different parameters. This property is helpful for generating a query string that can be added to a URL for HTTP requests.

#### Parameters
- `accountIdentifier`: A required property representing the account identifier.
- `applicationIdentifier`: A required property representing the application identifier.

#### Optional parameters

It is also possible to include the following _optional_ parameters when creating a deeplink:
- `link` - unique identifier of the referral trigger e.g., `"campaign-abc123"`
- `component` - component in the referral app e.g., `"checkout"`
- `customParameters` - `[String: String]` dictionary of key-value pairs e.g., `["custom1": "value1"]`

```swift
guard let model = ReferralAppModel(accountIdentifier: 123,
                                   applicationIdentifier: 456,
                                   link: "campaign-abc123",
                                   component: "checkout",
                                   customParameters: ["custom1": "value1"]) else {
    return
}
// create deeplink url from model using `urlScheme(appScheme:)` or `universalLink(domain:)`
```

#### Notes:
- The query property ensures that all characters in the keys and values are encoded according to [RFC 3986](ttps://datatracker.ietf.org/doc/html/rfc3986), which is essential for creating valid URL query strings.
- The order of parameters in the query string is determined by the order in which they are appended.

### Events sent to RAT

The SDK automatically sends two events to RAT:
- an etype `pv` visit event sent to the **referred** app's RAT account
- an etype `deeplink` event sent to the **referral** app's RAT account

## How to configure the database directory path
It is possible to change the database directory path in the app's `Info.plist`.

By default the database directory path is `Documents`. It is possible to store the database file in `Library/Application Support`:

- Enable `Library/Application Support` storage:
```xml
<key>RATStoreDatabaseInApplicationSupportDirectory</key>
<true/>
```

- Disable `Library/Application Support` storage:
```xml
<key>RATStoreDatabaseInApplicationSupportDirectory</key>
<false/>
```

⚠️ Note that **database migration is not supported** therefore if you use this setting in a pre-existing app you will lose any previously saved RAT events.

## How to set the app user agent in WKWebView

This feature allows to append the app user agent to the default WKWebView's user agent with this format:
{webview-user-agent} {app-bundle-identifier}/{CFBundleShortVersionString}

### At buildtime

- Enable the app user agent setting in WKWebView by configuring the app's Info.plist':
```xml
<key>RATSetWebViewAppUserAgentEnabled</key>
<true/>
```

- Disable the app user agent setting in WKWebView by configuring the app's Info.plist':
```xml
<key>RATSetWebViewAppUserAgentEnabled</key>
<false/>
```

#### Notes

If `RATSetWebViewAppUserAgentEnabled` is not set in the app's Info.plist, its value is set to true by default.

#### Warning

If `AnalyticsManager` is not launched from the main thread, then the `WKWebView` user agent will be set only in the next loop of the main Thread.
Therefore, `WKWebView` should not be instantiated at launch in this specific case.

### At runtime

- Enable the app user agent setting in WKWebView:
```swift
let webView = WKWebView()
webView.enableAppUserAgent(true)
```

- Enable the app user agent setting in WKWebView with a custom value:
```swift
let webView = WKWebView()
webView.enableAppUserAgent(true, with: "custom-app-user-agent-value")
```

- Disable the app user agent setting in WKWebView:
```swift
let webView = WKWebView()
webView.enableAppUserAgent(false)
```

## Internal JSON serialization

As there is a bug in the native JSON serialization for floating numbers on iOS, the internal JSON serialization should be used if your iOS app tracks events containing floating numbers in the events parameters.
In this specific case, your app's `Info.plist` should contain the key `RATEnableInternalSerialization` set to `true`:
```
<key>RATEnableInternalSerialization</key>
<true/>
```

## Event triggers

### UIApplication NSNotification

#### UIApplication.didFinishLaunchingNotification

A notification that posts immediately after the app finishes launching.
https://developer.apple.com/documentation/uikit/uiapplication/1622971-didfinishlaunchingnotification

When UIApplication.didFinishLaunchingNotification is received, these events are sent under certain conditions:

- `_rem_init_launch` is sent when the app is installed for the first time

- `_rem_install` is sent when the app is launched for the second time

- `_rem_install` and `_rem_update` are sent when the app has been updated to a new version

- `_rem_launch` is sent in any cases

- `_rem_credential_strategies` is sent in any cases with this boolean parameter:
    - key: strategies.password-manager
    - value: true or false

#### UIApplication.willEnterForegroundNotification

A notification that posts shortly before an app leaves the background state on its way to becoming the active app.
https://developer.apple.com/documentation/uikit/uiapplication/1622944-willenterforegroundnotification

- `_rem_launch` is sent in any cases

#### UIApplication.didBecomeActiveNotification

A notification that posts when the app becomes active.
https://developer.apple.com/documentation/uikit/uiapplication/1622953-didbecomeactivenotification

- `_rem_push_notify` is sent only if:
    - the app was previously opened from a push notification
    - UNUserNotificationCenter.current().delegate is set

#### UIApplication.didEnterBackgroundNotification

A notification that posts when the app enters the background.
https://developer.apple.com/documentation/uikit/uiapplication/1623071-didenterbackgroundnotification

- `_rem_end_session` is sent in any cases

### viewDidAppear

Notifies the view controller that its view was added to a view hierarchy.
https://developer.apple.com/documentation/uikit/uiviewcontroller/1621423-viewdidappear

- pv (page visit) is sent in any cases when a view controller did appear (viewDidAppear)

### APNS Remote Notifications

- `_rem_push_received` is sent when:
    - a push notification is received and intercepted by the Notification Service Extension
    - this Notification Service Extension's method is called:
        - didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void)

- `_rem_push_notify` is sent when:
    - the application is opened from a push notification
    - one of these AppDelegate's methods is called:
        - application:didReceiveRemoteNotification:
        - application:didReceiveRemoteNotification:fetchCompletionHandler:
        - userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler
        
### PNP Events

- `_rem_push_auto_register` is sent from RPushPNP SDK when:
    - the app becomes active
    - the user is not registered to PNP
    - the registration requests optimization is enabled
    - the push notifications status is authorized

- `_rem_push_auto_unregister` is sent from RPushPNP SDK when:
    - the app becomes active
    - the user is registered to PNP
    - the registration requests optimization is enabled
    - the push notifications status is denied

### SDKs NSNotification

#### IDSDK notifications

- `_rem_login` is sent when:
    - IDSDK login succeeds
    - this NSNotification is received: com.rakuten.esd.sdk.events.login.idtoken_memberid

- `_rem_login_failure` is sent when:
    - IDSDK login fails
    - this NSNotification is received: com.rakuten.esd.sdk.events.login.failure.idtoken_memberid

- `_rem_logout` is sent when:
    - IDSDK logout succeeds
    - this NSNotification is received: com.rakuten.esd.sdk.events.logout.idtoken_memberid

#### Custom notification

- `_analytics_custom` is sent when:
    - this NSNotification is received: com.rakuten.esd.sdk.events.custom
