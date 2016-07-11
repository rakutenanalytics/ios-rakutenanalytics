@tableofcontents
@section analytics-module Introduction
The **analytics** module provides APIs for tracking user activity and automatically send reports to the Rakuten Analytics servers.

@attention This module tracks the [IDFA][idfa] by default, to track installation and conversion rates. Please see the
 @ref analytics-appstore "AppStore Submission Procedure" section below for more information.

@section analytics-installing Installing
Please refer to [the Ecosystem SDK documentation](https://www.raksdtd.com/ios/) for a detailed step-by-step guide to installing the SDK.

If you would rather use this SDK module as a standalone library, your `Podfile` should contain:

    source 'https://github.com/CocoaPods/Specs.git'
    source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

    pod 'RSDKAnalytics'

Running `pod install` will install the module and its dependencies.

@section analytics-tutorial Getting started
@attention This module depends on the [deviceinformation](../deviceinformation-latest) module for
 retrieving the device's unique identifier, and that module requires keychain
 access to be properly configured. Please refer to @ref device-information-keychain-setup "Setting up the keychain"
 for the right way to do so.

@attention Without this, RSDKAnalyticsManager::spoolRecord: will raise a `NSObjectInaccessibleException`.

@subsection analytics-register Registering a new application
* [Registration Form](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Introduction+Application+Form) (from `r-intra`)
* Support email for administrative tasks: dev-rat@mail.rakuten.com

@subsection analytics-configuration Configuration
No configuration is required to start recording user activity, but a couple of things can
be fine-tuned:

#### Using the Staging environment
The module can be configured to use staging environment when talking to the backend, by
setting RSDKAnalyticsManager::shouldUseStagingEnvironment to `YES`:

    // Swift:
    RSDKAnalyticsManager.shared().shouldUseStagingEnvironment = true
    
    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldUseStagingEnvironment = YES;

@note The RAT staging server requires an ATS exception at the moment. See [RATQ-329](https://jira.rakuten-it.com/jira/browse/RATQ-329) for more information and tracking progress.

#### Last known location tracking (opt-in)
If your application uses location tracking, you can optionally let our SDK send that piece of information
automatically to RAT by setting RSDKAnalyticsManager::shouldTrackLastKnownLocation
to `YES`:

    // Swift:
    RSDKAnalyticsManager.shared().shouldTrackLastKnownLocation = true
    
    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldTrackLastKnownLocation = YES;

@warning Even with this property set to `YES`, the module will not track the
 device's location if your application is not also doing so, i.e. the
 application requested access to the device's location and the user granted it.
 Please refer to the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html)
 for more information on how to request location updates.
@warning Applications typically add something like this to their `UIApplicationDelegate`:
@warning
~~~{.m}
	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
		// ...
		self.locationManager = CLLocationManager.new;
		self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
		return YES;
	}
	
	- (void)applicationDidBecomeActive:(UIApplication *)application
	{
		[self.locationManager startUpdatingLocation];
	}
	
	- (void)applicationWillResignActive:(UIApplication *)application
	{
		[self.locationManager stopUpdatingLocation];
	}
~~~

#### IDFA tracking (opt-out)
Our SDK automatically tracks the [advertising identifier (IDFA)][idfa] by default. Although not recommended,
developers can still disable this by setting RSDKAnalyticsManager::shouldTrackAdvertisingIdentifier to `NO`:

    // Swift
    RSDKAnalyticsManager.shared().shouldTrackAdvertisingIdentifier = false

    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldTrackAdvertisingIdentifier = NO;

@subsection analytics-recording Recording activity
Records are created with RSDKAnalyticsRecord::recordWithAccountId:serviceId:
and spooled by calling RSDKAnalyticsManager::spoolRecord:.

The properties of RSDKAnalyticsRecord closely match the fields described in the
[Rakuten Analytics Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
JSON file. There are a few exceptions, mainly due to their corresponding field's name
being too obscure, but each property's documentation mentions both the short and long
names of the field it eventually maps to.

@note For more information about each property, please read
 the [RAT Specification](https://rakuten.atlassian.net/wiki/display/SDK/RAT+Specification).

Calling RSDKAnalyticsManager::spoolRecord: gathers extra values from the system
(such as the current time, information about the device the application is
running on and the type of network it is using to connect to the internet) and
returns immediately. The insertion into the local database and the upload of the
records to the Rakuten Analytics servers both happen on background queues.

~~~{.m}
	// Create a new record
	RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:123 serviceId:456];
	
	// Setup some parameters
	record.currencyCode  = @"USD";
	// …

	// Add some items
	RSDKAnalyticsItem *item = [RSDKAnalyticsItem itemWithIdentifier:@"shopId/itemId"];
	item.quantity = 4;
	item.price    = 158.75;
	[record addItem:item];
	// …

	// Spool the record!
	[RSDKAnalyticsManager spoolRecord:record];
~~~

For a list of valid `accountId` and `serviceId` values, please refer to the
[Services and accounts](https://git.rakuten-it.com/projects/RG/repos/rg/browse/aid_acc_Map.json)
JSON file.

@note Please see @ref analytics-register to learn how to register new applications.

@subsection analytics-network-monitoring Monitoring network activity
Developers who want to monitor the module's network activity can do so by listening
to the @ref RSDKAnalyticsWillUploadNotification, @ref RSDKAnalyticsUploadFailureNotification
and @ref RSDKAnalyticsUploadSuccessNotification notifications. For example:

~~~{.m}
	[[NSNotificationCenter defaultCenter]
		addObserverForName:RSDKAnalyticsUploadSuccessNotification
		object:nil
		queue:[NSOperationQueue currentQueue]
		usingBlock:^(NSNotification *note) {
			NSLog(@"Successfully sent these records: %@", note.object);
		}];
~~~

@section analytics-appstore AppStore Submission Procedure
When releasing your application to the AppStore, Apple now asks that you **disclose your usage of the advertising identifier (IDFA)**.

@image html appstore-idfa.png "IDFA usage disclosure" width=80%

#### 1. Serve advertisements within the app.
Please check this box if any of the following points apply:
- You show ads anywhere in your app.
- You are using the **[discover](../discover-latest)** module of our SDK.

#### 2. Attribute this app installation to a previously served advertisement
Our SDK uses the IDFA for install attribution. Please select this check box.

#### 3. Attribute an action taken within this app to a previously served advertisement
Our SDK uses the IDFA for re-engagment ads attribution. Please select this check box.

#### 4. iOS Limited Ad Tracking
Our SDK fully complies with Apple requirement below:

> Check the value of this property before performing any advertising tracking. If the value is NO, use the advertising identifier only for the following purposes: frequency capping, conversion events, estimating the number of unique users, security and fraud detection, and debugging.

Our SDK uses the IDFA only for: `conversion events, estimating the number of unique users, security and fraud detection`.

@section analytics-changelog Changelog

@subsection analytics-2-6-0 2.6.0 (2016-07-18)
* Added the automatic tracking of the advertising identifier (IDFA) if not turned off explicitly by setting @ref RSDKAnalyticsManager::shouldTrackAdvertisingIdentifier to `NO`. It is sent as the `cka` standard RAT parameter.
* In addition to `ua` (user agent), the library now also sends the `app_name` and `app_ver` parameters to RAT. The information in those fields is essentially the same as in `ua`, but is split in order to optimize queries and aggregation of KPIs on the backend.
* [REM-12024](https://jira.rakuten-it.com/jira/browse/REM-12024): Added RSDKAnalyticsManager::shouldUseStagingEnvironment.
* Deprecated `locationTrackingEnabled` and `isLocationTrackingEnabled` (in RSDKAnalyticsManager). Please use RSDKAnalyticsManager::shouldTrackLastKnownLocation instead.
* Improved naming conventions for Swift 3.
* Added support for generics.
* [REMI-1105](https://jira.rakuten-it.com/jira/browse/REMI-1105): Fix background upload timer only firing once, due to being requested from a background queue.
* Added @ref analytics-appstore "AppStore Submission Procedure" section to the documentation.
* Improved documentation: added table of content, full changelog and better-detailed tutorial.

@subsection analytics-2-5-6 2.5.6 (2016-06-24)
* [REMI-1052](https://jira.rakuten-it.com/jira/browse/REM-1052) Fix wrong version number being sent.
* Fix Xcode 6 build.

@subsection analytics-2-5-5 2.5.5 (2016-06-06)
* Added all the system frameworks used by the module to both its `podspec` and its `modulemap`, so they get weakly-linked automatically.
* [REM-10217](https://jira.rakuten-it.com/jira/browse/REM-10217) Removed the dependency on `RakutenAPIs`.

@subsection analytics-2-5-4 2.5.4 (2016-04-04)
* [REM-11534](https://jira.rakuten-it.com/jira/browse/REM-11534) Wrong online status was reported.
* [REM-11533](https://jira.rakuten-it.com/jira/browse/REM-11533) Wrong battery usage was reported.
* [REM-3761](https://jira.rakuten-it.com/jira/browse/REM-3761) Documentation did not link to the RAT application form.
* Documentation improvement.

@subsection analytics-2-5-3 2.5.3 (2015-09-02)
* Moved to `gitpub.rakuten-it.com`.

@subsection analytics-2-5-1 2.5.1 (2015-08-24)
* Fixed the `modulemap`.

@subsection analytics-2-5-0 2.5.0 (2015-08-12)
* [REM-2378](https://jira.rakuten-it.com/jira/browse/REM-2378) Export version number using `NSUserDefaults` (internal SDK KPI tracking).

@subsection analytics-2-4-1 2.4.1 (2015-06-25)
* Better Swift support.

@subsection analytics-2-4-0 2.4.0 (2015-04-21)
* `SDK-2947` Fixes bugs and comply with new requirements.

@subsection analytics-2-3-4 2.3.4 (2015-04-01)
* `SDK-2901` Cocoapods 0.36 now requires `source`.

@subsection analytics-2-3-3 2.3.3 (2015-03-18)
* `SDK-2761` (sample app) Numeric fields accepted arbitrary text.
* `SDK-2729` Location was being sent to RAT even when tracking was disabled.

@subsection analytics-2-3-2 2.3.2 (2015-03-10)
* `SDK-2859` Handle device information exceptions.

@subsection analytics-2-3-1 2.3.1 (2015-03-08)
* Fix sample build error.

@subsection analytics-2-3-0 2.3.0 (2015-03-07)
* Fixed bad value for session cookie.
* Better validation of input.
* Better error reporting.
* Added HockeyApp SDK to sample app.

@subsection analytics-2-2-3 2.2.3 (2014-12-15)
* Updated dependency on `RSDKDeviceInformation`.

@subsection analytics-2-2-2 2.2.2 (2014-10-30)
* Added internal tracking (for SDK KPIs)

@subsection analytics-2-2-1 2.2.1 (2014-10-09)
* Fixes for iOS 8

@subsection analytics-2-2-0 2.2.0 (2014-09-22)
* Add `RSDKAnalyticsItem`.
* The `ts1` RAT field is now expressed in seconds (previously, it was milliseconds).

@subsection analytics-2-1-0 2.1.0 (2014-06-24)
* Remove dependency on [FXReachability](https://github.com/nicklockwood/FXReachability)
* Added `RSDKAnalyticsRecord.easyId` property.

@subsection analytics-2-0-0 2.0.0 (2014-06-13)
* Major rewrite

@subsection analytics-1-0-0 1.0.0 (2013-08-15)
* Initial release

[idfa]: https://developer.apple.com/reference/adsupport/asidentifiermanager
