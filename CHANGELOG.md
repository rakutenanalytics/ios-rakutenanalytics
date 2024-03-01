# Changelog

## Unreleased

### Features
* [CONRAT-32240](https://jira.rakuten-it.com/jira/browse/CONRAT-32240): Multi domain support.

## 10.0.2 (2024-02-15)

### Crash fixes
* [CONRAT-32190](https://jira.rakuten-it.com/jira/browse/CONRAT-32190): Fix a crash that occurs when watchOS interact with iOS in terminat state.

### Features
* [CONRAT-30888](https://jira.rakuten-it.com/jira/browse/CONRAT-30888): Add Privacy Manifest file with Privacy info usage description and Required Reason API.

### Improvements
* [CONRAT-30314](https://jira.rakuten-it.com/jira/browse/CONRAT-30314): Show an empty page in Sample app to test pv event tracking.
* [CONRAT-32046](https://jira.rakuten-it.com/jira/browse/CONRAT-32046): Change Geo Tracker batching delay from 15 minutes to 60 seconds.
* [CONRAT-32200](https://jira.rakuten-it.com/jira/browse/CONRAT-32200): Fix local CI build to support macOS Sonoma.

### Unit tests
* [CONRAT-29129](https://jira.rakuten-it.com/jira/browse/CONRAT-29129): BDD test cases for dln field Device Language.
* [CONRAT-30217](https://jira.rakuten-it.com/jira/browse/CONRAT-30217): Migrate ClassManipulatorUIApplicationTests.m to Swift.
* [CONRAT-30240](https://jira.rakuten-it.com/jira/browse/CONRAT-30240): Fix ReferralAppTrackingSceneDelegateSpec failure on Bitrise.
* [CONRAT-30252](https://jira.rakuten-it.com/jira/browse/CONRAT-30252): Remove `ObjcInteropSpec.m`.
* [CONRAT-30452](https://jira.rakuten-it.com/jira/browse/CONRAT-30452): Refactor test file suffix to Spec.

### Docs
* [CONRAT-30239](https://jira.rakuten-it.com/jira/browse/CONRAT-30239): Update Readme about migration of RAE to IDSDK.
* [CONRAT-31053](https://jira.rakuten-it.com/jira/browse/CONRAT-31053): Update README about CTCarrier API deprecation.
* [CONRAT-30618](https://jira.rakuten-it.com/jira/browse/CONRAT-30618): Remove RAnalytics/Core from README.
* [CONRAT-31467](https://jira.rakuten-it.com/jira/browse/CONRAT-31467): Update information about time interval based collection.

## 10.0.1 (2023-06-23)

### Improvements
* [CONRAT-29393](https://jira.rakuten-it.com/jira/browse/CONRAT-29393): Add more tests to CKP in DeviceIdentifierHandlerSpec.
* [CONRAT-29521](https://jira.rakuten-it.com/jira/browse/CONRAT-29521): Change payload format of action parameters for `loc` events.

## 10.0.0 (2023-06-05)

### Features
* [CONRAT-27822](https://jira.rakuten-it.com/jira/browse/CONRAT-27822): Update rsdks parameter format.
* [CONRAT-28242](https://jira.rakuten-it.com/jira/browse/CONRAT-28242): Expose public methods of GeoManager in Geo module.
* [CONRAT-28248](https://jira.rakuten-it.com/jira/browse/CONRAT-28248): Add GeoTracker to Geo Module.
* [CONRAT-28353](https://jira.rakuten-it.com/jira/browse/CONRAT-28353): Save Configuration from application for GeoManager.
* [CONRAT-28669](https://jira.rakuten-it.com/jira/browse/CONRAT-28669): Implement timer based location collection.
* [CONRAT-28793](https://jira.rakuten-it.com/jira/browse/CONRAT-28793): Implement distance based location collection.
* [CONRAT-28380](https://jira.rakuten-it.com/jira/browse/CONRAT-28380): Implement stop location collection.
* [CONRAT-28904](https://jira.rakuten-it.com/jira/browse/CONRAT-28904): Add background modes location updates capability.
* [CONRAT-29001](https://jira.rakuten-it.com/jira/browse/CONRAT-29001): Save default configuration when nil is passed in startLocationCollection.
* [CONRAT-29102](https://jira.rakuten-it.com/jira/browse/CONRAT-29102): Carrier Identification.

### Improvements
* [SDKCF-6199](https://jira.rakuten-it.com/jira/browse/SDKCF-6199): Move sharedPayload to RAnalyticsState extension and rename it to corePayload.
* [SDKCF-6210](https://jira.rakuten-it.com/jira/browse/SDKCF-6210): Remove unused DependenciesFactory protocol.
* [CONRAT-27844](https://jira.rakuten-it.com/jira/browse/CONRAT-27844): Remove unused extension - URLSession+Result.
* [CONRAT-27882](https://jira.rakuten-it.com/jira/browse/CONRAT-27882): Improve rsdks tests in CoreHelpersSpec by injecting Bundle.allFrameworks in CoreHelpers.
* [CONRAT-27917](https://jira.rakuten-it.com/jira/browse/CONRAT-27917): Add app_info parameter for update event.
* [CONRAT-27898](https://jira.rakuten-it.com/jira/browse/CONRAT-27898): Add pitari and geo cocoapods dependencies to RModulesList.plist file.
* [CONRAT-28085](https://jira.rakuten-it.com/jira/browse/CONRAT-28085): Remove all deprecated public APIs.
* [CONRAT-28071](https://jira.rakuten-it.com/jira/browse/CONRAT-28071): Remove SDKTracker.
* [CONRAT-28459](https://jira.rakuten-it.com/jira/browse/CONRAT-28459): Move Geo Classes to Core.
* [CONRAT-28481](https://jira.rakuten-it.com/jira/browse/CONRAT-28481): Refactor GeoTracker to handle negative values.
* [CONRAT-28496](https://jira.rakuten-it.com/jira/browse/CONRAT-28496): Refactor Public Methods Exposed in GeoManager.
* [CONRAT-28527](https://jira.rakuten-it.com/jira/browse/CONRAT-28527): Replace ActionParameters by GeoActionParameters.
* [CONRAT-28251](https://jira.rakuten-it.com/jira/browse/CONRAT-28251): Move GeoTracker from GeoManager to AnalyticsManager.
* [CONRAT-28597](https://jira.rakuten-it.com/jira/browse/CONRAT-28597): Refactor GeoConfiguration.
* [CONRAT-28751](https://jira.rakuten-it.com/jira/browse/CONRAT-28751): Process loc event with AnalyticsManager in order to add additional state parameters.
* [CONRAT-28743](https://jira.rakuten-it.com/jira/browse/CONRAT-28743): Refactor 'loc' field with action Parameters in single Map Object.
* [CONRAT-28813](https://jira.rakuten-it.com/jira/browse/CONRAT-28813): Remove GeoSharedPreferences.
* [CONRAT-29099](https://jira.rakuten-it.com/jira/browse/CONRAT-29099): Remove unused dependencies in GeoManager.
* [CONRAT-29118](https://jira.rakuten-it.com/jira/browse/CONRAT-29118): Improve didDetermineState delegate based on region id.
* [CONRAT-29127](https://jira.rakuten-it.com/jira/browse/CONRAT-29127): Refactor 'dln' field to retrieve correct device language.

### Bug fixes
* [CONRAT-28848](https://jira.rakuten-it.com/jira/browse/CONRAT-28848): Make the maximum upload time interval configurable in RAnalyticsSender for GeoTracker.
* [CONRAT-28925](https://jira.rakuten-it.com/jira/browse/CONRAT-28925): Fix missing action parameters on request location.
* [CONRAT-28848](https://jira.rakuten-it.com/jira/browse/CONRAT-28848): Handle background timer calculation for GeoTracker.
* [CONRAT-29004](https://jira.rakuten-it.com/jira/browse/CONRAT-29004): Fix configured time interval functionality for start/stop location collection.
* [CONRAT-29331](https://jira.rakuten-it.com/jira/browse/CONRAT-29331): Fix the issue by refraining from sending empty simopn and simop values.

### Changes
* [CONRAT-27817](https://jira.rakuten-it.com/jira/browse/CONRAT-27817): Remove dependency on RSDKUtils.
* [CONRAT-27901](https://jira.rakuten-it.com/jira/browse/CONRAT-27901): Create a documentation for Internal JSON Serialization in ADVANCED_USAGE.md
* [CONRAT-28901](https://jira.rakuten-it.com/jira/browse/CONRAT-28901): Add documentation for Location Tracking in ADVANCED_USAGE.md

### Sonarqube fixes
* [CONRAT-28044](https://jira.rakuten-it.com/jira/browse/CONRAT-28044): Fix Reachability.swift SonarQube issues.
* [CONRAT-28054](https://jira.rakuten-it.com/jira/browse/CONRAT-28054): Fix CoreInfosCollector SonarQube issue.
* [CONRAT-28056](https://jira.rakuten-it.com/jira/browse/CONRAT-28056): Fix String+Extensions.swift SonarQube issues.
* [CONRAT-28957](https://jira.rakuten-it.com/jira/browse/CONRAT-28957): Fix LocationModel internal init - SonarQube issue.
* [CONRAT-28958](https://jira.rakuten-it.com/jira/browse/CONRAT-28958): Remove the unnecessary Boolean literal in LocationModel - SonarQube Issue.
* [CONRAT-29000](https://jira.rakuten-it.com/jira/browse/CONRAT-29000): Remove backticks (`) from "internal" and rename it to inner in RAnalyticsInternalOrigin - Sonarqube Issue.
* [CONRAT-29007](https://jira.rakuten-it.com/jira/browse/CONRAT-29007): Rename this field "_endpointURL" to match the regular expression ^[a-z][a-zA-Z0-9]*$. - SonarQube issue.

### Unit tests
* [CONRAT-27983](https://jira.rakuten-it.com/jira/browse/CONRAT-27983): Improve the RAT Tracking tests with CoreHelpers injection.
* [CONRAT-28146](https://jira.rakuten-it.com/jira/browse/CONRAT-28146): Fix RP Cookie Fetcher Integration Spec failing test.
* [CONRAT-28195](https://jira.rakuten-it.com/jira/browse/CONRAT-28195): Create BDD tests for isTrackableAsPageVisit.
* [CONRAT-28528](https://jira.rakuten-it.com/jira/browse/CONRAT-28528): Improve UIViewControllerExtensionsSpec BDD Tests in oder to test the fix made in CONRAT-28236.
* [CONRAT-28931](https://jira.rakuten-it.com/jira/browse/CONRAT-28931): Add missed Test cases for Action Parameters in requestLocation.
* [CONRAT-28951](https://jira.rakuten-it.com/jira/browse/CONRAT-28951): Create a separate folder for Geo BDD Test Files.

### Docs
* [CONRAT-29006](https://jira.rakuten-it.com/jira/browse/CONRAT-29006): Add comments to GeoManager public functions about main thread warnings.
* [CONRAT-29314](https://jira.rakuten-it.com/jira/browse/CONRAT-29314): Update README.md for UIKit's pv event.

## 9.8.1 (2023-03-23)

### Crash fixes
* [SDKCF-28236](https://jira.rakuten-it.com/jira/browse/SDKCF-28236): Fix a crash that occurs when a view controller's view is nil.

## 9.8.0 (2023-01-30)

### Features
* [SDKCF-6124](https://jira.rakuten-it.com/jira/browse/SDKCF-6124): Override User Agent value in WKWebView.

### Improvements
* [SDKCF-6047](https://jira.rakuten-it.com/jira/browse/SDKCF-6047): Improve CKP code coverage to 100%.
* [SDKCF-6197](https://jira.rakuten-it.com/jira/browse/SDKCF-6197): Add description to each RAT key in PayloadParameterKeys.

### Changes
* [SDKCF-6109](https://jira.rakuten-it.com/jira/browse/SDKCF-6109): Remove Push events tracking logic from RAnalytics.

### Build fixes
* [SDKCF-6198](https://jira.rakuten-it.com/jira/browse/SDKCF-6198): Fix the sample app build.

## 9.7.0 (2022-11-29)

### Features
* [SDKCF-5839](https://jira.rakuten-it.com/jira/browse/SDKCF-5839): Implement the easy RAT integration verification method.
RAnalytics SDK throws an exception in DEBUG MODE when `RATAccountIdentifier` and `RATAppIdentifier` keys are missing in the app's Info.plist
RAnalytics SDK tracking is disabled in RELEASE MODE when `RATAccountIdentifier` and `RATAppIdentifier` keys are missing in the app's Info.plist
* [SDKCF-5876](https://jira.rakuten-it.com/jira/browse/SDKCF-5876): Enable/Disable App-to-App referral tracking.
* [SDKCF-6001](https://jira.rakuten-it.com/jira/browse/SDKCF-6001): Add a public API in Analytics SDK to retrieve Device ID (ckp value).
* [SDKCF-6007](https://jira.rakuten-it.com/jira/browse/SDKCF-6007): Set date header in HTTP request.

### Improvements
* [SDKCF-5880](https://jira.rakuten-it.com/jira/browse/SDKCF-5880): Secure the Easy ID storage and handle the Easy ID migration from the user defaults to the keychain.
* [SDKCF-6008](https://jira.rakuten-it.com/jira/browse/SDKCF-6008): Use init instead of ratRequest in order to improve the internal API of RAnalytics.

### Doc improvements
* [SDKCF-5892](https://jira.rakuten-it.com/jira/browse/SDKCF-5892): Add the release workflow documentation.

### Build fixes
* [SDKCF-5738](https://jira.rakuten-it.com/jira/browse/SDKCF-5738): Fix AnalyticsManager failing tests by simulating Cookie Store Observer.
* [SDKCF-5927](https://jira.rakuten-it.com/jira/browse/SDKCF-5927): Xcode 14 CI build compatibility with Bitrise.
* [SDKCF-5928](https://jira.rakuten-it.com/jira/browse/SDKCF-5928): Fixed SPM Sample build lanes signing error on Xcode 14.
* [SDKCF-6069](https://jira.rakuten-it.com/jira/browse/SDKCF-6069): Refactor documentation generation process

### Warning fixes
* [SDKCF-5917](https://jira.rakuten-it.com/jira/browse/SDKCF-5917): Fix `_RanalyticsSwiftLoader` warning for Projects based on Cocoapods.
* [SDKCF-5918](https://jira.rakuten-it.com/jira/browse/SDKCF-5918): Fix CLLocationManager.locationServicesEnabled() warning in Xcode 14.0 (14A309).

### Unit tests
* [SDKCF-5936](https://jira.rakuten-it.com/jira/browse/SDKCF-5936): Add BDD Tests to ApplicationSceneManifest.
* [SDKCF-5953](https://jira.rakuten-it.com/jira/browse/SDKCF-5953): Fix the Page Visit failing tests in RAnalyticsRATTrackerProcessSpec.
* [SDKCF-5954](https://jira.rakuten-it.com/jira/browse/SDKCF-5954): Create BDD Tests for getWebViewURL function.
* [SDKCF-5955](https://jira.rakuten-it.com/jira/browse/SDKCF-5955): Fix RAnalyticsCookieInjectorSpec failing tests by using a mock of WKHTTPCookieStore.
* [SDKCF-5956](https://jira.rakuten-it.com/jira/browse/SDKCF-5956): Migrate RpCookieTests to BDD Tests.
* [SDKCF-5962](https://jira.rakuten-it.com/jira/browse/SDKCF-5962): Use the cookies storage of URLSessionMock.

## 9.6.0 (2022-09-22)

### Features
* [SDKCF-5829](https://jira.rakuten-it.com/jira/browse/SDKCF-5829): SceneDelegate support for App-to-App referral tracking.
* [SDKCF-5873](https://jira.rakuten-it.com/jira/browse/SDKCF-5873): Fix the SceneDelegate support for App-to-App referral tracking.

### Improvements
* [SDKCF-5306](https://jira.rakuten-it.com/jira/browse/SDKCF-5306): update RModulesList.plist:
Remove RPing, RDiscover, RFeedback SDKs
Add RSDKUtils SDK
* [SDKCF-5635](https://jira.rakuten-it.com/jira/browse/SDKCF-5635): Create a constant for logout_method RAT extra parameter.
* [SDKCF-5657](https://jira.rakuten-it.com/jira/browse/SDKCF-5657): Create a constant for push_notify_value RAT extra parameter.
* [SDKCF-5609](https://jira.rakuten-it.com/jira/browse/SDKCF-5609): Refactor UIDevice extension for Swift 5.7/Xcode 14 compatibility.
* [SDKCF-5814](https://jira.rakuten-it.com/jira/browse/SDKCF-5814): Move rem_launch cp's keys to CpParameterKeys enum.
* [SDKCF-5815](https://jira.rakuten-it.com/jira/browse/SDKCF-5815): Move rem_login cp's keys to CpParameterKeys enum.

### Build fixes
* [SDKCF-5816](https://jira.rakuten-it.com/jira/browse/SDKCF-5816): Update the provisioning profiles for the Sample apps.
* [SDKCF-5829](https://jira.rakuten-it.com/jira/browse/SDKCF-5829): Fix a Sonarqube issue for parameter naming convention:
`Rename this variable "_analyticsManager" to match the regular expression ^[a-z][a-zA-Z0-9]*$.`

### Doc fixes
* [SDKCF-5818](https://jira.rakuten-it.com/jira/browse/SDKCF-5818): Replace shouldTrackEvent by shouldTrackEventHandler in the documentation.

## 9.5.0 (2022-06-09)

### Improvements
* [SDKCF-5475](https://jira.rakuten-it.com/jira/browse/SDKCF-5475): Added new RAT events `_rem_push_auto_register` and `_rem_push_auto_unregister` to support Push Notification Platform (PNP) opt-in/opt-out tracking.
* [SDKCF-5369](https://jira.rakuten-it.com/jira/browse/SDKCF-5369): Added convenience properties `accountIdentifier` and `applicationIdentifier` to the `RAnalyticsRATTracker` public API.
* [SDKCF-5335](https://jira.rakuten-it.com/jira/browse/SDKCF-5335): String type is allowed again for plist values `RATAccountIdentifier` and `RATAppIdentifier` due to the Number type only requirement being too strict for app teams.

## 9.4.1 (2022-05-20)

⚠️ **Important:** RAnalytics SDK versions v9.1.0 until v9.4.0 have an issue where the device id (RAT ckp) format was changed from the <v9.1.0 format. This resulted in the wrong unique user count being calculated by RAT. To fix this issue you should update your SDK version to at least v9.4.1, where we have reverted device id to match the previous format.

### Bug fixes
* [SDKCF-5296](https://jira.rakuten-it.com/jira/browse/SDKCF-5296): Updated the device id format to match the format that was previously generated by the `RDeviceIdentifier` module.

## 9.4.0 (2022-05-10)

⚠️ **Important:** Do not use this version because it has an issue that results in wrong unique user count being calculated by RAT. Upgrade to at least v9.4.1. See the v9.4.1 changelog for details.

### Features
* [SDKCF-4817](https://jira.rakuten-it.com/jira/browse/SDKCF-4817): Added public APIs to set/unset the ID SDK member identifier. Apps are no longer required to use the analytics-idtoken add-on library.
* [SDKCF-5250](https://jira.rakuten-it.com/jira/browse/SDKCF-5250): Added ability to override the RAT account number in custom events.

### Bug fixes
* [SDKCF-4252](https://jira.rakuten-it.com/jira/browse/SDKCF-4252): Fixed issue with `ra_uid` still being shown after disabling app to web tracking.
* [SDKCF-3951](https://jira.rakuten-it.com/jira/browse/SDKCF-3951): Debug logging of event payloads are now split to fix a truncation issue.

### Improvements
* [SDKCF-4884](https://jira.rakuten-it.com/jira/browse/SDKCF-4884): Added recommendation on how to keep the automatic version tracking feature of the SDK working properly in Xcode 13. See the [README guide](index.html#knowledge-base) for more details.
* [SDKCF-5109](https://jira.rakuten-it.com/jira/browse/SDKCF-5109): mcn/mcnd values are now set as empty when airplane mode is active.

## 9.3.0 (2022-03-25)

⚠️ **Important:** Do not use this version because it has an issue that results in wrong unique user count being calculated by RAT. Upgrade to at least v9.4.1. See the v9.4.1 changelog for details.

### Features
* [SDKCF-4998](https://jira.rakuten-it.com/jira/browse/SDKCF-4998): Added support for tracking conversions associated with push notification messages. See the [guide](index.html#push-conversion-tracking) for details.

### Improvements
* [SDKCF-4819](https://jira.rakuten-it.com/jira/browse/SDKCF-4819): Added [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/) to CI pipeline using Fastlane [plugin](https://github.com/alteral/fastlane-plugin-dependency_check_ios_analyzer). This tool will flag usage of dependencies that have publicly disclosed vulnerabilities.

## 9.2.0 (2022-02-18)

⚠️ **Important:** Do not use this version because it has an issue that results in wrong unique user count being calculated by RAT. Upgrade to at least v9.4.1. See the v9.4.1 changelog for details.

### Features
* [SDKCF-2161](https://jira.rakuten-it.com/jira/browse/SDKCF-2161): Apps can set a handler to be notified of errors in the SDK. These errors can be logged as a non-fatal issue to a reporting backend e.g. Firebase Crashlytics. See the [error handling guide](advanced_usage.html#handling-errors).
* [SDKCF-4796](https://jira.rakuten-it.com/jira/browse/SDKCF-4796): Added an extension helper `rviewOnAppear` for tracking SwiftUI views. See the [tracking events guide](index.html#tracking-events) "Tracking events in SwiftUI views" section.
* [SDKCF-4870](https://jira.rakuten-it.com/jira/browse/SDKCF-4870): Added support for the new push received event which is sent when a push notification is received and intercepted by a Notification Service Extension. See the [event triggers guide](advanced_usage.html#event-triggers).

### Bug fixes
* [SDKCF-4695](https://jira.rakuten-it.com/jira/browse/SDKCF-4695): Added offline connection handling in `RAnalyticsRpCookieFetcher.getRpCookieCompletionHandler()`.
* [SDKCF-4789](https://jira.rakuten-it.com/jira/browse/SDKCF-4789): Made return explicit to fix compatibility issue with earlier Swift version.
* [SDKCF-4803](https://jira.rakuten-it.com/jira/browse/SDKCF-4803): Added logic to clear the events cache after extension events are processed.

### Improvements
* [SDKCF-4389](https://jira.rakuten-it.com/jira/browse/SDKCF-4389): The SDK now supports Swift Package Manager (SPM). For integration steps see [getting started](index.html#getting-started).
* [SDKCF-4790](https://jira.rakuten-it.com/jira/browse/SDKCF-4790) / [SDKCF-4824](https://jira.rakuten-it.com/jira/browse/SDKCF-4824): Documented Xcode version support and aligned Swift version support with our other SDKs.

## 9.1.1 (2022-01-14)

⚠️ **Important:** Do not use this version because it has an issue that results in wrong unique user count being calculated by RAT. Upgrade to at least v9.4.1. See the v9.4.1 changelog for details.

### Bug fixes
* [SDKCF-4773](https://jira.rakuten-it.com/jira/browse/SDKCF-4773) / [SDKCF-4780](https://jira.rakuten-it.com/jira/browse/SDKCF-4780): Fixed issues with the extension event tracking implementation.

## 9.1.0 (2022-01-06)

⚠️ **Important:** Do not use this version because it has an issue that results in wrong unique user count being calculated by RAT. Upgrade to at least v9.4.1. See the v9.4.1 changelog for details.

### Bug fixes
* [SDKCF-4765](https://jira.rakuten-it.com/jira/browse/SDKCF-4765): Fixed issue where the public binary was missing the Analytics version in the `rsdks` RAT event payload field. 

### Improvements
* [SDKCF-4698](https://jira.rakuten-it.com/jira/browse/SDKCF-4698): Improved the support for tracking of events from extensions for the RPushPNP SDK's Rich Push feature. The tracking can be enabled using the new `AnalyticsManager` property `enableExtensionEventTracking`, which is disabled by default.
* [SDKCF-4705](https://jira.rakuten-it.com/jira/browse/SDKCF-4705): Added logic to prevent sending duplicate push notify events.
* [SDKCF-4649](https://jira.rakuten-it.com/jira/browse/SDKCF-4649): Simplified setting of UserID/EasyID status in RAT payload. The SDK will no longer send `NO_LOGIN_FOUND` in the `userid` field. Instead, `userid` will be set for legacy Mobile SDK logged-in users or `easyid` will be set for ID SDK logged-in users.
* [SDKCF-4580](https://jira.rakuten-it.com/jira/browse/SDKCF-4580): Replaced `RDeviceIdentifier` dependency with `UIDevice.identifierForVendor`. Apps no longer need to configure a special keychain access group for device id tracking.
* [SDKCF-4567](https://jira.rakuten-it.com/jira/browse/SDKCF-4567) / [SDKCF-4568](https://jira.rakuten-it.com/jira/browse/SDKCF-4568): Migrated `WebTrackingCookieDomainBlock` and `BatchingDelayBlock` to Swift. The source migration to Swift is complete.

## 9.0.0 (2021-11-16)

### Breaking changes
* [SDKCF-4358](https://jira.rakuten-it.com/jira/browse/SDKCF-4358): The minimum supported OS version is now iOS 12.0.
* [SDKCF-4016](https://jira.rakuten-it.com/jira/browse/SDKCF-4016): Removed deprecated `RAnalyticsRATTracker` `endpointAddress()` function. `endpointURL` should be used instead.
* [SDKCF-4486](https://jira.rakuten-it.com/jira/browse/SDKCF-4486): Removed deprecated `AnalyticsManager` `shouldTrackPageView` property. `RAnalyticsManager#shouldTrackEventHandler` should be used instead. See the [Configure automatic tracking](advanced_usage.html#configure-automatic-tracking) guide.

### Features
* [SDKCF-4233](https://jira.rakuten-it.com/jira/browse/SDKCF-4233): Apps can now set the database directory path to `Library/Application Support` instead of the default `Documents` path. Note that **database migration is not supported** therefore if you use this setting in a pre-existing app you will lose any previously saved RAT events. See the [feature guide](advanced_usage.html#how-to-configure-the-database-directory-path).

### Bug fixes
* [SDKCF-4463](https://jira.rakuten-it.com/jira/browse/SDKCF-4463): Applied a workaround to prevent an Apple IDFA native crash in `UUID.unconditionallyBridgeFromObjectiveC`.
* [SDKCF-4565](https://jira.rakuten-it.com/jira/browse/SDKCF-4565): Fixed issue where the member identifier (Easy ID) was not saved to UserDefaults.
* [SDKCF-4547](https://jira.rakuten-it.com/jira/browse/SDKCF-4547): Suppressed unwanted TelephonyHandler error logs on simulator.

### Improvements
* [SDKCF-4350](https://jira.rakuten-it.com/jira/browse/SDKCF-4350) / [SDKCF-4423](https://jira.rakuten-it.com/jira/browse/SDKCF-4423): Refactored module to use common code from [RSDKUtils library](https://github.com/rakutentech/ios-sdkutils).
* [SDKCF-4455](https://jira.rakuten-it.com/jira/browse/SDKCF-4455): Fixed module code to be compatible with Xcode 12.3, which some customers are still using to build their app.
* [SDKCF-4484](https://jira.rakuten-it.com/jira/browse/SDKCF-4484): Migrated `RAnalyticsProgressNotifications` and `RAnalyticsPushTrackingUtility` constants to Swift.
* [SDKCF-4483](https://jira.rakuten-it.com/jira/browse/SDKCF-4483): Migrated all `RAnalyticsEvent` event declarations to Swift.

## 8.3.0 (2021-10-22)

### Features
* [SDKCF-4178](https://jira.rakuten-it.com/jira/browse/SDKCF-4178): Added new feature to track app-to-app referrals. See the [feature guide](advanced_usage.html#app-to-app-referral-tracking).
* [SDKCF-3927](https://jira.rakuten-it.com/jira/browse/SDKCF-3927): Added new feature to track events to multiple RAT accounts. See the [feature guide](advanced_usage.html#duplicate-events-across-multiple-rat-accounts).

### Bug fixes
* [SDKCF-4286](https://jira.rakuten-it.com/jira/browse/SDKCF-4286): Improved database handling to reduce likelihood of rare crash occurring.

### Improvements
* Completed migration of main module code to Swift with [phase six](https://jira.rakuten-it.com/jira/issues/?jql=labels%20%3D%20swift-migration-phase-6).

## 8.2.2 (2021-10-07)

* [SDKCF-4310](https://jira.rakuten-it.com/jira/browse/SDKCF-4310): Fixed a rare crash that can occur when the formatted string of the event payload is logged.

## 8.2.1 (2021-07-30)

* **Important Note:** If you are using Xcode 13 to build your app, and you experience the issue below, you should upgrade your dependency to this version.
* [SDKCF-4023](https://jira.rakuten-it.com/jira/browse/SDKCF-4023): Fixed Xcode 13 beta 3 issue where the unit tests target hangs at launch and the process gets terminated by the watchdog. Moved `AnalyticsManager` out of the Objective-C `+ (void)load` to prevent the deadlock.

## 8.2.0 (2021-07-21)

* [SDKCF-3847](https://jira.rakuten-it.com/jira/browse/SDKCF-3847): Added guide about [tracking member identifier state](index.html#id-sdk-and-omni-compatibility) when the app is using ID-SDK and OMNI.
* [SDKCF-4012](https://jira.rakuten-it.com/jira/browse/SDKCF-4012): Fixed build error caused by protocol naming conflict between RAnalytics v8.1.0 and latest RPushPNP SDK v4.x.
* [SDKCF-3895](https://jira.rakuten-it.com/jira/browse/SDKCF-3895): The module now recognizes and tracks 5G network type in the `mnetw` (mobile network) field.
* [SDKCF-3870](https://jira.rakuten-it.com/jira/browse/SDKCF-3870): Added tracking of dual SIMs in new event fields `mcnd` (mobile carrier name "dual") and `mnetwd` (mobile network "dual"). 
* Continued migration of module code to Swift. Includes migration phase [five](https://jira.rakuten-it.com/jira/issues/?jql=labels%20%3D%20swift-migration-phase-5).

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

* The module can now be built and deployed as a binary framework. See [Confluence](https://confluence.rakuten-it.com/confluence/display/MAGS/iOS+Analytics+SDK+on+GitHub+-+Make+SDK+public) for details.
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
