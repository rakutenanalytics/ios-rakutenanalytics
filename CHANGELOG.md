# Changelog

## 8.1.1 (2021-06-29)

* [SDKCF-3903](https://jira.rakuten-it.com/jira/browse/SDKCF-3903): Fixed serialization of floating numbers in experimental custom serializer.
* [SDKCF-3907](https://jira.rakuten-it.com/jira/browse/SDKCF-3907): Added [troubleshooting](index.html#troubleshooting) tip for building the SDK without defining `use_frameworks!`.

## 8.1.0 (2021-06-09)

* [SDKCF-3604](https://jira.rakuten-it.com/jira/browse/SDKCF-3604): Replaced RSDKA_SWIFT_NAME with NS_SWIFT_NAME to fix build error for specific customer.
* [SDKCF-3823](https://jira.rakuten-it.com/jira/browse/SDKCF-3823): Fixed serialization of decimals [issue](https://bugs.swift.org/browse/SR-7054) by using an experimental replacement of JSONDecoder. This is currently only enabled for a specific customer.
* [SDKCF-3545](https://jira.rakuten-it.com/jira/browse/SDKCF-3545): Changed Rakuten company name references.
* [SDKCF-3851](https://jira.rakuten-it.com/jira/browse/SDKCF-3851): Added ability to track events while scrolling.
* [SDKCF-3843](https://jira.rakuten-it.com/jira/browse/SDKCF-3843): Improved retry logic and error handling for RP cookie.
* [SDKCF-3612](https://jira.rakuten-it.com/jira/browse/SDKCF-3612): Added support to build SDK as xcframework.
* Continued migration of module code to Swift. Includes migration phases [three](https://jira.rakuten-it.com/jira/issues/?jql=labels%20%3D%20swift-migration-phase-3) and [four](https://jira.rakuten-it.com/jira/issues/?jql=labels%20%3D%20swift-migration-phase-4).

## 8.0.1 (2021-03-17)

* [SDKCF-3460](https://jira.rakuten-it.com/jira/browse/SDKCF-3460): Removed sensitive/internal information from public header files so that they will not be exposed in the framework.

## 8.0.0 (2021-03-04)

* The module can now be built and deployed as a binary framework. See [Confluence](https://confluence.rakuten-it.com/confluence/display/MTSD/iOS+Analytics+SDK+on+GitHub+-+Make+SDK+public) for details.
* [SDKCF-3163](https://jira.rakuten-it.com/jira/browse/SDKCF-3163): Added runtime and buildtime configuration of the automatically tracked events. See [Configure automatic tracking](advanced_usage.html#configure-automatic-tracking).
* [SDKCF-3190](https://jira.rakuten-it.com/jira/browse/SDKCF-3190): `RAnalyticsManager#shouldTrackPageView` has been deprecated. Apps can use the newly introduced `RAnalyticsManager#shouldTrackEventHandler` property instead.
* Partly migrated the module code to Swift. Includes migration phases [one](https://jira.rakuten-it.com/jira/issues/?jql=labels%20%3D%20swift-migration-phase-1) and [two](https://jira.rakuten-it.com/jira/issues/?jql=labels%20%3D%20swift-migration-phase-2) which consists mainly of private classes.

## 7.0.1 (2021-02-12)

* [SDKCF-3218](https://jira.rakuten-it.com/jira/browse/SDKCF-3218) / [SDKCF-3152](https://jira.rakuten-it.com/jira/browse/SDKCF-3152): Fixed crash that can occur if there are pending database operations when app terminates. Database operations will now be cancelled if app is terminating.

## 7.0.0 (2020-12-16)

* [SDKCF-2922](https://jira.rakuten-it.com/jira/browse/SDKCF-2922): Added ability to configure the RAT endpoint at runtime. See [Configure a custom endpoint](advanced_usage.html#configure-a-custom-endpoint).
* [SDKCF-2920](https://jira.rakuten-it.com/jira/browse/SDKCF-2920): Improved custom domains support in App to Web Tracking feature. See [App to Web tracking](advanced_usage.html#app-to-web-tracking).
* **Breaking change**[SDKCF-2888](https://jira.rakuten-it.com/jira/browse/SDKCF-2888): Minimum supported version has been changed to iOS 11.0.
* **Breaking API change** Custom RAnalyticsTracker trackers must implement the new RAnalyticsEndpointSettable protocol.
* **Breaking API change** Removed deprecated `RAnalyticsRATTracker#getRpCookieCompletionHandler()`. Apps can use RAnalyticsRpCookieFetcher instead.

## 6.0.0 (2020-11-25)

* [SDKCF-2921](https://jira.rakuten-it.com/jira/browse/SDKCF-2921): Added tracking support for rich push notifications.
* [SDKCF-2938](https://jira.rakuten-it.com/jira/browse/SDKCF-2938): Fixed issue where push notification tracking event may not have been sent when UNUserNotification was disabled & app was in background on iOS 10.x.
* **Breaking API change**: Updated parameter type in `AnalyticsManager#set(loggingLevel:)` API due to the support added for building the module code as a framework.

## 5.3.0 (2020-10-30)

* [SDKCF-2843](https://jira.rakuten-it.com/jira/browse/SDKCF-2843): Added API to enable App to Web tracking. By default this feature is disabled. See [App to Web tracking](advanced_usage.html#app-to-web-tracking).
* [SDKCF-2784](https://jira.rakuten-it.com/jira/browse/SDKCF-2784): Added API to configure logging level from app. The plist flag `RMSDKEnableDebugLogging` is now deprecated. See [Configure debug logging](advanced_usage.html#configure-debug-logging) for usage.

## 5.2.2 (2020-09-18)

* [SDKCF-2826](https://jira.rakuten-it.com/jira/browse/SDKCF-2826): Simplified the approach for handling IDFA. If the available IDFA value is valid (non-zero'd) the RAnalytics SDK will use it. This change was implemented in response to Apple's [announcement](https://developer.apple.com/news/?id=hx9s63c5) that they have delayed the requirement to obtain permission for user tracking until "early next year".
* [SDKCF-2749](https://jira.rakuten-it.com/jira/browse/SDKCF-2749): Fixed warning that status bar orientation UI methods are called from non-UI thread.

## 5.2.1 (2020-09-14)

* [SDKCF-2777](https://jira.rakuten-it.com/jira/browse/SDKCF-2777): Fixed a crash related to CTRadioAccessTechnologyDidChangeNotification.

## 5.2.0 (2020-09-02)

* [SDKCF-2659](https://jira.rakuten-it.com/jira/browse/SDKCF-2659): Implemented support for iOS 14 IDFA permission changes. See [IDFA tracking](advanced_usage.html#idfa-tracking).
* [SDKCF-2658](https://jira.rakuten-it.com/jira/browse/SDKCF-2658): Added `RAnalyticsManager.setUserIdentifier(userIdentifier:)` to allow apps to manually set a user identifier. See [Manually set a user identifier](advanced_usage.html#manually-set-a-user-identifier).
* [SDKCF-2695](https://jira.rakuten-it.com/jira/browse/SDKCF-2695): Added value for user identifier in user logged out state.
* [SDKCF-2732](https://jira.rakuten-it.com/jira/browse/SDKCF-2732): Added support for the new Corelocation authorization delegate method on iOS 14.
* [SDKCF-2411](https://jira.rakuten-it.com/jira/browse/SDKCF-2411): Changed the approach of calculating push notification open count rate. See [Push Notification Open Rate](readme.html#push-notification-open-rate).

## 5.1.0 (2020-07-17)

* [SDKCF-2606](https://jira.rakuten-it.com/jira/browse/SDKCF-2606): Changed the default batching delay to 1 second. See [Configure the Tracker Batching Delay](advanced_usage.html#configure-the-tracker-batching-delay).
* [SDKCF-1654](https://jira.rakuten-it.com/jira/browse/SDKCF-1654): Fixed crash that can occur when Firebase SDK is also integrated.
* [SDKCF-2077](https://jira.rakuten-it.com/jira/browse/SDKCF-2077): Fixed bug where a device laying flat in landscape mode could set the wrong orientation mode in the event payload.

## 5.0.2 (2020-07-06)

* [SDKCF-2561](https://jira.rakuten-it.com/jira/browse/SDKCF-2561): Made storing of RAT cookies in shared cookie storage optional. The option was added to temporarily workaround a specific backend issue for a specific customer. **Warning**: You should not need to use this option, however if you choose do so it may impact your RAT tracking statistics.

## 5.0.1 (2020-04-30)

* [SDKCF-2291](https://jira.rakuten-it.com/jira/browse/SDKCF-2291): Fixed Swift naming macro build error in Xcode 11.4.
* [SDKCF-1561](https://jira.rakuten-it.com/jira/browse/SDKCF-1561): Send empty `mnetw` (network type - WiFi/4G/3G) field in the RAT event payload when device is offline.

## 5.0.0 (2020-02-27)

* [SDKCF-2017](https://jira.rakuten-it.com/jira/browse/SDKCF-2017): Removed all `UIWebView` references from code to comply with Apple [announcement](https://developer.apple.com/news/?id=12232019b)
* [SDKCF-1253](https://jira.rakuten-it.com/jira/browse/SDKCF-1253): Removed the deprecated `shouldUseStagingEnvironment` flag
* [SDKCF-1957](https://jira.rakuten-it.com/jira/browse/SDKCF-1957): Updated batching delay documentation to reference battery usage testing
* [SDKCF-1955](https://jira.rakuten-it.com/jira/browse/SDKCF-1955): Added missing module names to SDK Tracker's module map list
* [SDKCF-1562](https://jira.rakuten-it.com/jira/browse/SDKCF-1562): Added empty `mcn` (carrier name) field to the RAT event payload that will be sent when device is connected to WiFi

## 4.1.0 (2019-10-28)

* [SDKCF-1523](https://jira.rakuten-it.com/jira/browse/SDKCF-1523): Move RP cookie fetch functionality from RAT subspec to Core subspec so that it is available to modules that only have a dependency on Core

## 4.0.0 (2019-01-16)

* [SDKCF-740](https://jira.rakuten-it.com/jira/browse/SDKCF-740): Drop support for iOS versions below iOS 10.0

## 3.2.0 (2018-11-29)

* [SDKCF-16](https://jira.rakuten-it.com/jira/browse/SDKCF-16): Add an option to disable PageView (PV) tracking
* [SDKCF-759](https://jira.rakuten-it.com/jira/browse/SDKCF-759): Allow the SDK to send Performance Tracking info to RAT
* [SDKCF-801](https://jira.rakuten-it.com/jira/browse/SDKCF-801): Fix a bug where RAnalyticsIsAppleClass crash in Xcode 10.1

## 3.1.1 (2018-09-05)

* [SDKCF-619](https://jira.rakuten-it.com/jira/browse/SDKCF-619): Check object is valid before adding it to record array. Fixes crash observed in customer's Crashlytics report
* [SDKCF-612](https://jira.rakuten-it.com/jira/browse/SDKCF-612): Add README section about tracking events from App Extension targets

## 3.1.0 (2018-06-25)

* [SDKCF-158](https://jira.rakuten-it.com/jira/browse/SDKCF-158): Make RAT endpoint configurable in plist
* [SDKCF-149](https://jira.rakuten-it.com/jira/browse/SDKCF-149): Make keychain sharing optional
* [SDKCF-68](https://jira.rakuten-it.com/jira/browse/SDKCF-68): Support multiple app targets using different subspecs
* [SDKCF-18](https://jira.rakuten-it.com/jira/browse/SDKCF-18): Add type validation for acc and aid values
* [SDKCF-99](https://jira.rakuten-it.com/jira/browse/SDKCF-99): Fixed bug where "online":false status is shown in payload for some RAT events on iOS 8

## 3.0.0 (2018-04-13)

* [REM-25315](https://jira.rakuten-it.com/jira/browse/REM-25315): Read RAT Account ID and Application ID from app's info.plist.
* [REM-25524](https://jira.rakuten-it.com/jira/browse/REM-25524) / [REM-25547](https://jira.rakuten-it.com/jira/browse/REM-25547): Add Swift sample app and update Objective-C sample app to match latest analytics module API.
* [REM-25864](https://jira.rakuten-it.com/jira/browse/REM-25864): Redesign module and separate functionality into `Core` and `RAT` CocoaPods subspecs.
* [REM-25317](https://jira.rakuten-it.com/jira/browse/REM-25317): Add SDK Tracker to track build information and non-Apple frameworks usage.

## 2.13.0 (2018-01-11)

* [REM-24194](https://jira.rakuten-it.com/jira/browse/REM-24194): Add support for App Extensions.
* [REM-24746](https://jira.rakuten-it.com/jira/browse/REM-24746): Send Rp cookie to RAT.

## 2.12.0 (2017-11-13)

* [REM-24171](https://jira.rakuten-it.com/jira/browse/REM-24171): Disable debug log for Analytics module.

## 2.11.0 (2017-10-10)

* [REM-23653](https://jira.rakuten-it.com/jira/browse/REM-23653): Track Shared Web Credentials usage.

## 2.10.1 (2017-09-06)

* [REM-21934](https://jira.rakuten-it.com/jira/browse/REM-21934): Fixed duplicate `_rem_push_notify` event sent to RAT.

## 2.10.0 (2017-06-21)

* [REM-21497](https://jira.rakuten-it.com/jira/browse/REM-21497): Added RATTracker::configureWithDeliveryStrategy: API so that applications can configure the batching delay for sending events. The default batching delay is 60 seconds which is unchanged from previous module versions.

## 2.9.0 (2017-03-30)

* [REM-19145](https://jira.rakuten-it.com/jira/browse/REM-19145): Reduced the memory footprint of automatic page view tracking by half by not keeping a strong reference to the previous view controller anymore. This comes with a minor change: RSDKAnalyticsState::lastVisitedPage is now deprecated, and always `nil`.

## 2.8.2 (2017-02-06)

* [REM-18839](https://jira.rakuten-it.com/jira/browse/REM-18839): The `RSDKAnalyticsSessionStartEventName` "launch event" was not being triggered for most launches.
* [REM-18565](https://jira.rakuten-it.com/jira/browse/REM-18565): The `page_id` parameter was completely ignored by the RAT tracker when processing a `RSDKAnalyticsPageVisitEventName` "visit event".
* [REM-18384](https://jira.rakuten-it.com/jira/browse/REM-18384): The library was blocking calls to `-[UNNotificationCenterDelegate userNotificationCenter:willPresentNotification:withCompletionHandler]`, effectively disabling the proper handling of user notifications on iOS 10+ in apps that relied on the new `UserNotifications` framework.
* [REM-18438](https://jira.rakuten-it.com/jira/browse/REM-18438), [REM-18437](https://jira.rakuten-it.com/jira/browse/REM-18437) & [REM-18436](https://jira.rakuten-it.com/jira/browse/REM-18436): The library is now smarter as to what should trigger a `RSDKAnalyticsPageVisitEventName` "visit event".
    * Won't trigger the event anymore:
        * Common chromes: `UINavigationController`, `UISplitViewController`, `UIPageViewController` and `UITabBarController` view controllers.
        * System popups: `UIAlertView`, `UIActionSheet`, `UIAlertController` & `_UIPopoverView`.
        * Apple-private views, windows and view controllers.
        * Subclasses of `UIWindow` that are not provided by the app.
    * Furthermore, the RAT tracker additionally ignores view controllers that have no title, no navigation item title, and for which no URL was found on any webview part of their view hierarchy at the time `-viewDidLoad` was called, unless they have been subclassed by the application.
        * For view controllers with either a title, navigation item title or URL, the library now adds the `cp.title` and `cp.url` fields to the `pv` event sent to RAT.
* Fixed missing automatic import of the `UserNotifications` framework on iOS 10+.
* Fixed bogus imports in a few header files.

## 2.8.1 (2016-11-29)

* [REM-17889](https://jira.rakuten-it.com/jira/browse/REM-17889): Fixed potential security issue where full push notification message was sent to RAT.
* [REM-17890](https://jira.rakuten-it.com/jira/browse/REM-17890): Fixed missing event after a push notification while app is active.
* [REM-17927](https://jira.rakuten-it.com/jira/browse/REM-17927): Fixed missing `ref_type` attribute on `pv` RAT event after a push notification.

## 2.8.0 (2016-11-11)

* [REM-16656](https://jira.rakuten-it.com/jira/browse/REM-16656): Added collection and tracking of Discover events to Analytics module.
* [REM-14422](https://jira.rakuten-it.com/jira/browse/REM-14422): Added tracking of push notifications to standard event tracking.
* [REM-17621](https://jira.rakuten-it.com/jira/browse/REM-17621): Fixed initial launch events being fired twice.
* [REM-17862](https://jira.rakuten-it.com/jira/browse/REM-17862): Fixed issue where AppDelegate swizzling disabled deep linking.
* Added the missing endpointAddress property to RATTracker.
* Fixed issue where Easy ID was being sent even though user was logged out.
* Fixed the case where a device has no SIM and the carrier name always displayed the wrong carrier name, and the module sent that wrong name to the server.
* Fixed an incorrect debug message in Xcode console stating that no tracker processed a RAT event, when the RAT tracker did in fact process the event successfully.

## 2.7.1 (2016-10-11)

* [REM-17208](https://jira.rakuten-it.com/jira/browse/REM-17208): Fixed a crash happening for some Ichiba users when the RAT tracker cannot properly create its backing store because SQLite is in a corrupt state. Instead of a runtime assertion, we're now silently ignoring the error and disabling tracking through RAT for the session instead.
* [REM-16279](https://jira.rakuten-it.com/jira/browse/REM-16279) & [REM-16280](https://jira.rakuten-it.com/jira/browse/REM-16280) Add cp.sdk_info and cp.app_info parameters to _rem_install event.
* [REM-14062](https://jira.rakuten-it.com/jira/browse/REM-14062) Track _rem_visit event.

## 2.7.0 (2016-09-28)

* Major rewrite.
* Support for custom event trackers.
* Automatic KPI tracking from other parts of our SDK: login/logout, sessions, application lifecycles.
* Deprecated RSDKAnalyticsManager::spoolRecord:, RSDKAnalyticsItem and RSDKAnalyticsRecord.

## 2.6.0 (2016-07-27)

* Added the automatic tracking of the advertising identifier (IDFA) if not turned off explicitly by setting RSDKAnalyticsManager::shouldTrackAdvertisingIdentifier to `NO`. It is sent as the `cka` standard RAT parameter.
* In addition to `ua` (user agent), the library now also sends the `app_name` and `app_ver` parameters to RAT. The information in those fields is essentially the same as in `ua`, but is split in order to optimize queries and aggregation of KPIs on the backend.
* [REM-12024](https://jira.rakuten-it.com/jira/browse/REM-12024): Added RSDKAnalyticsManager::shouldUseStagingEnvironment.
* Deprecated `locationTrackingEnabled` and `isLocationTrackingEnabled` (in RSDKAnalyticsManager). Please use RSDKAnalyticsManager::shouldTrackLastKnownLocation instead.
* Improved naming conventions for Swift 3.
* Added support for generics.
* [REMI-1105](https://jira.rakuten-it.com/jira/browse/REMI-1105): Fix background upload timer only firing once, due to being requested from a background queue.
* Added [AppStore Submission Procedure](readme.html#appstore-submission-procedure) section to the documentation.
* Improved documentation: added table of contents, full changelog and more detailed tutorial.

## 2.5.6 (2016-06-24)

* [REMI-1052](https://jira.rakuten-it.com/jira/browse/REM-1052) Fixed wrong version number being sent.
* Fixed Xcode 6 build.

## 2.5.5 (2016-06-06)

* Added all the system frameworks used by the module to both its `podspec` and its `modulemap`, so they get weakly-linked automatically.
* [REM-10217](https://jira.rakuten-it.com/jira/browse/REM-10217) Removed the dependency on `RakutenAPIs`.

## 2.5.4 (2016-04-04)

* [REM-11534](https://jira.rakuten-it.com/jira/browse/REM-11534) Wrong online status was reported.
* [REM-11533](https://jira.rakuten-it.com/jira/browse/REM-11533) Wrong battery usage was reported.
* [REM-3761](https://jira.rakuten-it.com/jira/browse/REM-3761) Documentation did not link to the RAT application form.
* Documentation improvement.

## 2.5.3 (2015-09-02)

* Moved to `gitpub.rakuten-it.com`.

## 2.5.1 (2015-08-24)

* Fixed the `modulemap`.

## 2.5.0 (2015-08-12)

* [REM-2378](https://jira.rakuten-it.com/jira/browse/REM-2378) Export version number using `NSUserDefaults` (internal SDK KPI tracking).

## 2.4.1 (2015-06-25)

* Better Swift support.

## 2.4.0 (2015-04-21)

* `SDK-2947` Fixed bugs and comply with new requirements.

## 2.3.4 (2015-04-01)

* `SDK-2901` Cocoapods 0.36 now requires `source`.

## 2.3.3 (2015-03-18)

* `SDK-2761` (sample app) Numeric fields accepted arbitrary text.
* `SDK-2729` Location was being sent to RAT even when tracking was disabled.

## 2.3.2 (2015-03-10)

* `SDK-2859` Handle device information exceptions.

## 2.3.1 (2015-03-08)

* Fixed sample build error.

## 2.3.0 (2015-03-07)

* Fixed bad value for session cookie.
* Better validation of input.
* Better error reporting.
* Added HockeyApp SDK to sample app.

## 2.2.3 (2014-12-15)

* Updated dependency on `RSDKDeviceInformation`.

## 2.2.2 (2014-10-30)

* Added internal tracking (for SDK KPIs)

## 2.2.1 (2014-10-09)

* Fixed bugs on iOS 8

## 2.2.0 (2014-09-22)

* Added `RSDKAnalyticsItem`.
* The `ts1` RAT field is now expressed in seconds (previously in milliseconds).

## 2.1.0 (2014-06-24)

* Removed dependency on [FXReachability](https://github.com/nicklockwood/FXReachability)
* Added `RSDKAnalyticsRecord.easyId` property.

## 2.0.0 (2014-06-13)

* Major rewrite

## 1.0.0 (2013-08-15)

* Initial release
