@tableofcontents
@section analytics-module Introduction
The **analytics** module provides APIs for tracking user activity and automatically sends reports to the Rakuten Analytics servers.

@attention This module tracks the [IDFA][idfa] by default to track installation and conversion rates. See the @ref analytics-appstore "AppStore Submission Procedure" section below for more information.

@section analytics-installing Installing
See the [Ecosystem SDK documentation](https://www.raksdtd.com/ios/) guide for a detailed step-by-step guide on installing the SDK.

Alternatively, you can also use this SDK module as a standalone library. To use the SDK module as a standalone library, your `Podfile` should contain:

    source 'https://github.com/CocoaPods/Specs.git'
    source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

    pod 'RSDKAnalytics'

Run `pod install` to install the module and its dependencies.

@section analytics-tutorial Getting started
@attention This module depends on the [deviceinformation](../deviceinformation-latest) module to retrieve the device's unique identifier. The deviceinformation module also requires keychain access for proper configuration. See @ref device-information-keychain-setup "Setting up the keychain" for more information.

@attention Without the deviceinformation module, RSDKAnalyticsManager::spoolRecord: raises a `NSObjectInaccessibleException`.

@subsection analytics-register Registering a new application
* [Registration Form](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Introduction+Application+Form) (from `r-intra`)
* Support email for administrative tasks: dev-rat@mail.rakuten.com

@subsection analytics-configuration Configuration
No configuration is required to start recording user activity, but you can change settings like staging environment options and last known location tracking to best suit your app.

#### Using the staging environment
The analytics module can be configured to use the staging environment when talking to the backend by setting RSDKAnalyticsManager::shouldUseStagingEnvironment to `YES`:

    // Swift:
    RSDKAnalyticsManager.shared().shouldUseStagingEnvironment = true
    
    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldUseStagingEnvironment = YES;

@note Currently, the RAT staging server requires an ATS exception. See [RATQ-329](https://jira.rakuten-it.com/jira/browse/RATQ-329) for more information and tracking progress.

#### Last known location tracking (opt-in)
If your app uses location tracking, you can have the SDK automatically send location information by setting RSDKAnalyticsManager::shouldTrackLastKnownLocation
to `YES`. This setting is optional.

    // Swift:
    RSDKAnalyticsManager.shared().shouldTrackLastKnownLocation = true
    
    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldTrackLastKnownLocation = YES;

@warning The analytics module does not track the device's location if the user has not granted device location access to the app, even if this property set to `YES`. See the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html) for more information on how to request location updates.
@warning Apps usually add a code snippet similiar to the one below to their `UIApplicationDelegate`:
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
The Rakuten SDK automatically tracks the [advertising identifier (IDFA)][idfa] by default. It is not recommended to disable this feature, but you can still disable it by setting RSDKAnalyticsManager::shouldTrackAdvertisingIdentifier to `NO`:

    // Swift
    RSDKAnalyticsManager.shared().shouldTrackAdvertisingIdentifier = false

    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldTrackAdvertisingIdentifier = NO;

@subsection analytics-recording Recording activity
Records are created with RSDKAnalyticsRecord::recordWithAccountId:serviceId:
and spooled by calling RSDKAnalyticsManager::spoolRecord:.

The properties of RSDKAnalyticsRecord closely match the fields described in the
[Rakuten Analytics Generic IDL](https://git.rakuten-it.com/projects/RG/repos/rg/browse/ratGeneric.idl)
JSON file. There are some exceptions, due to the corresponding field's name
being too obscure, but each property's documentation mentions both the short and long
names of the field used for mapping.

@note See the [RAT Specification](https://rakuten.atlassian.net/wiki/display/SDK/RAT+Specification) guide for more information about each property.

Calling RSDKAnalyticsManager::spoolRecord: gathers extra values from the system, such as the current time, information about the device, and the type of network it is using to connect to the internet, and returns them immediately. The insertion into the local database and the upload of records to the Rakuten Analytics servers both occur on background queues.

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

See the [Services and accounts](https://git.rakuten-it.com/projects/RG/repos/rg/browse/aid_acc_Map.json)
JSON file for a list of valid `accountId` and `serviceId` values.


@note See @ref analytics-register to learn how to register new applications.

@subsection analytics-network-monitoring Monitoring network activity
You can monitor the module's network activity by listening
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
Apple requests that you **disclose your usage of the advertising identifier (IDFA)** when releasing your application to the App Store.

@image html appstore-idfa.png "IDFA usage disclosure" width=80%

#### 1. Serve advertisements within the app.
Check this box if any of the following options apply to your app:
- You app contains advertisements.
- You are using the **[discover](../discover-latest)** SDK module.

#### 2. Attribute this app installation to a previously served advertisement
Check this checkbox. The Rakuten SDK uses the IDFA for install attribution. 

#### 3. Attribute an action taken within this app to a previously served advertisement
Check this checkbox. The Rakuten SDK uses the IDFA for re-engagment ads attribution. 

#### 4. iOS Limited Ad Tracking
The Rakuten SDK fully complies with Apple requirement below:

> Check the value of this property before performing any advertising tracking. If the value is NO, use the advertising identifier only for the following purposes: frequency capping, conversion events, estimating the number of unique users, security and fraud detection, and debugging.

The Rakuten SDK only uses the IDFA for `conversion events, estimating the number of unique users, security and fraud detection`.

@section analytics-changelog Changelog

@subsection analytics-2-6-0 2.6.0 (2016-07-27)
* Added the automatic tracking of the advertising identifier (IDFA) if not turned off explicitly by setting @ref RSDKAnalyticsManager::shouldTrackAdvertisingIdentifier to `NO`. It is sent as the `cka` standard RAT parameter.
* In addition to `ua` (user agent), the library now also sends the `app_name` and `app_ver` parameters to RAT. The information in those fields is essentially the same as in `ua`, but is split in order to optimize queries and aggregation of KPIs on the backend.
* [REM-12024](https://jira.rakuten-it.com/jira/browse/REM-12024): Added RSDKAnalyticsManager::shouldUseStagingEnvironment.
* Deprecated `locationTrackingEnabled` and `isLocationTrackingEnabled` (in RSDKAnalyticsManager). Please use RSDKAnalyticsManager::shouldTrackLastKnownLocation instead.
* Improved naming conventions for Swift 3.
* Added support for generics.
* [REMI-1105](https://jira.rakuten-it.com/jira/browse/REMI-1105): Fix background upload timer only firing once, due to being requested from a background queue.
* Added @ref analytics-appstore "AppStore Submission Procedure" section to the documentation.
* Improved documentation: added table of contents, full changelog and more detailed tutorial.

@subsection analytics-2-5-6 2.5.6 (2016-06-24)
* [REMI-1052](https://jira.rakuten-it.com/jira/browse/REM-1052) Fixed wrong version number being sent.
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
* The `ts1` RAT field is now expressed in seconds (previously in milliseconds).

@subsection analytics-2-1-0 2.1.0 (2014-06-24)
* Remove dependency on [FXReachability](https://github.com/nicklockwood/FXReachability)
* Added `RSDKAnalyticsRecord.easyId` property.

@subsection analytics-2-0-0 2.0.0 (2014-06-13)
* Major rewrite

@subsection analytics-1-0-0 1.0.0 (2013-08-15)
* Initial release

[idfa]: https://developer.apple.com/reference/adsupport/asidentifiermanager
