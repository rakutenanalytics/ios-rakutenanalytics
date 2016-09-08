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

@subsection analytics-configure-rat Configuring RAT
@attention Applications **MUST** configure their RAT `accountId` and `applicationId` with the methods presented below, or automatic KPI tracking for a number of SDK features (SSO, installs, conversions, etc) will be disabled.

    // Swift
    let rat = RATTracker.shared()
    rat.configure(accountId:     YOUR_RAT_ACCOUNT_ID)
    rat.configure(applicationId: YOUR_RAT_APPLICATION_ID)
    
    // Obj-C
    RATTracker *rat = RSDKAnalyticsRATTracker.sharedInstance;
    [rat configureWithAccountId:     YOUR_RAT_ACCOUNT_ID];
    [rat configureWithApplicationId: YOUR_RAT_APPLICATION_ID];

@subsection analytics-configure-staging Using the staging environment
The analytics module can be configured to use the staging environment when talking to the backend by setting RSDKAnalyticsManager::shouldUseStagingEnvironment to `YES`:

    // Swift:
    RSDKAnalyticsManager.shared().shouldUseStagingEnvironment = true

    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldUseStagingEnvironment = YES;

@note Currently, the RAT staging server requires an ATS exception. See [RATQ-329](https://jira.rakuten-it.com/jira/browse/RATQ-329) for more information and tracking progress.

@subsection analytics-configure-location Location Tracking

@warning The SDK does not *actively* track the device's location even if the user has granted access to the app and the RSDKAnalyticsManager::shouldTrackLastKnownLocation property is set to `YES`. Instead, it passively monitors location updates captured by your application. See the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html) for more information on how to request location updates. Note that monitoring the device location for no other purpose than tracking will get your app rejected by Apple.
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

If you want to disable location tracking, you can set RSDKAnalyticsManager::shouldTrackLastKnownLocation to `NO`. Tracking is enabled by default.

~~~{.m}
    // Swift:
    RSDKAnalyticsManager.shared().shouldTrackLastKnownLocation = false

    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldTrackLastKnownLocation = NO;
~~~

@subsection analytics-recording Recording activity
Events are created with RSDKAnalyticsEvent::initWithName:parameters: and spooled by calling their @ref RSDKAnalyticsEvent::track "track" method.

#### Tracking generic events
Tracking a generic event relies on a @ref RSDKAnalyticsTracker "tracker" capable of processing the event currently being @ref RSDKAnalyticsManager::addTracker: "registered".

~~~{.m}
    // Swift
    AnalyticsManager.Event(name: "my.event", parameters: ["foo": "bar"]).track()

    // Obj-C
    [[RSDKAnalyticsEvent.alloc initWithName:@"my.event" parameters:@{@"foo": @"bar"}] track];
~~~

#### Tracking RAT-specific events
A concrete tracker, RSDKAnalyticsRATTracker, is automatically registered and interacts with the **Rakuten Analytics Tracker (RAT)**. You can also use RSDKAnalyticsRATTracker::eventWithEventType:parameters: for creating events that will only be processed by RAT. For more information about the various parameters accepted by that service, refer to the [RAT Specification](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Parameter+Spec).

@note Our SDK automatically tracks a number of RAT parameters for you, so you don't have to include those when creating an event: `acc`, `aid`, `etype`, `powerstatus`, `mbat`, `dln`, `loc`, `mcn`, `model`, `mnetw`, `mori`, `mos`, `online`, `cka`, `ckp`, `cks`, `ua`, `app_name`, `app_ver`, `res`, `ltm`, `ts1`, `tzo`, `userid` and `ver`.

~~~{.m}
    // Swift
    RATTracker.shared().event(eventType: "tapPage", parameters:["pgn": "coupon page"]).track()

    // Obj-C
    [[RSDKAnalyticsRATTracker.sharedInstance eventWithEventType:@"tapPage" parameters:@{@"pgn": @"coupon page"}] track];
~~~

@subsection analytics-standard-events Standard Events
The SDK will automatically send events to the Rakuten Analytics Tracker for certain actions. The event type parameter for all of these events are prefixed with `_rem_`.

@note These events will send all of the automatic parameters that are normally sent with a RAT event. Some events also send additional parameters specific to the event, as listed below.

#### _rem_init_launch
Application is launched for the first time ever.

#### _rem_launch
Application is launched.
- `cp.days_since_first_use` - Number of calendar days passed since first run of the current version.
- `cp.days_since_last_use` - Number of calendar days passed since the previous run.

#### _rem_end_session
Application goes into background.

#### _rem_update
Application is launched and its version number does not match the version number of the previous launch.
- `cp.previous_version` - Version of the app at the time of the previous launch.
- `cp.launches_since_last_upgrade` - Number of launches for the previous version.
- `cp.days_since_last_upgrade` - Number of calendar days passed since the previous version was first run.

#### _rem_login
User logged in successfully.
- `cp.login_method` - String representing method the used to login.
    - `password` - User entered their credentials manually.
    - `one_tap_login` - User used SSO's one-tap Login button.

#### _rem_logout
User logged out.
- `cp.logout_method` - String representing the method used to logout.
    - `single` - User logged out from the current app only.
    - `all` - User logged out from all apps.

#### _rem_install
Application version is launched for the first time.
- `cp.sdk_info` - Information about the REM SDK the application is built against, following a user agent-like grammar.
- `cp.app_info` - Information report about the build and runtime environment for the app in a serialized JSON object format.
    - `xcode` - Version of Xcode used to build the app.
    - `sdk` - iOS SDK built against.
    - `frameworks` - Name and versions of all the bundles returned by NSBundle.allFrameworks, excluding those with the prefix `com.apple.`.
    - `pods` - Name and versions of all the CocoaPods in the application.

@section analytics-appstore AppStore Submission Procedure
@attention This section only applies if you are submitting your App to the AppStore yourself. Apps should normally be submitted to the App Management Group who will assist you with submitting to the AppStore.

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

@section analytics-rat-examples RAT Examples
@note These examples are all using @ref RSDKAnalyticsRATTracker to send [RAT specific parameters](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Parameters+Definition). If using a custom tracker, @ref RSDKAnalyticsEvent should be used instead.

@subsection analytics-kibana Using Kibana to Test and Visualize Analytics
[Kibana](http://grp01.kibana.geap.intra.rakuten-it.com/) can be used to test your analytics or to visualize your data in real time. To find all analytics data for your app, you can search for your Application ID by using a search query similar to `aid:999`.

To find data for a certain event type, such as one of the @ref analytics-standard-events "standard events" or one of the examples below, you can add the `etype` to your search query, for example `aid:999 AND etype:_rem_launch`. 

@subsection analytics-screen-tracking Screen Tracking
Some @ref analytics-standard-events "standard events" are sent by the SDK for screen tracking. However, events can also be sent manually if custom parameters are needed.

@code{.m}
    /* Track view controller launch
     * "pgn"    Page Name
     * "pgt"    Page Type ("top", "search", "shop_item", "cart_modify", or "cart_checkout")
     * "ref"    Referrer - previous page name or previous page URL
     */
    - (void)viewDidLoad
    {
        [[RSDKAnalyticsRATTracker.sharedInstance eventWithEventType:@"launch" 
                        parameters:@{
                            @"pgn": @"Main", 
                            @"pgt": @"top", 
                            @"ref": @"http://www.google.com"
                        }] track];
    }
@endcode

@subsection analytics-ui-interactions UI Interactions
[Action connections](https://developer.apple.com/library/ios/recipes/xcode_help-IB_connections/chapters/CreatingAction.html) can be setup on controls such as buttons in order to track clicks on a control. Interactions with views such as tapping, pinching, swiping, etc. can also be tracked by setting up a [Gesture Recognizer](https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/GestureRecognizer_basics/GestureRecognizer_basics.html)

@code{.m}
    /* Track Button Clicks
     * "pgn"    Page Name
     * "gol"    Goal Id - Goals are specific strategies you'll leverage to accomplish your business objectives.
     */
    - (IBAction)buttonTapped:(UIButton *)sender
    {
        [[RSDKAnalyticsRATTracker.sharedInstance eventWithEventType:@"buttonClick" 
                        parameters:@{
                            @"pgn": @"Main", 
                            @"gol": @"Improve marketing effectiveness"
                        }] track];
    }
@endcode

@subsection analytics-purchase-data-tracking Purchase Data Tracking
There are a number of RAT parameters specific to tracking purchase and shopping cart data. If you wish to track shopping cart items using the `itemid`, `genre`, `ino`, and `price` parameters, the data for these must be passed as arrays. The data for the `variation` parameter should be passed as a dictionary. An example is given below:

@code{.m}
    // Generate arrays for item data
    id arrayOfItemIds = @[@"shopid/item_1_id", @"shopid/item_2_id"];
    id arrayOfItemGenres = @[@"item 1 genre", @"item 2 genre"];
    id arrayOfItemQuantities = @[@"1", @"3"];
    id arrayOfItemPrices = @[@50.9, @3.3];
    id dictionaryOfVariations = @{@"color": @"red", @"size": @"M"};
@endcode

If you wish to use the `chkout` parameter, there are only five integer values that it can be set to.

@code{.m}
    // Checkout stages
    const NSNumber *CHECKOUT_STAGE1_LOGIN = @10;
    const NSNumber *CHECKOUT_STAGE2_SHIPPING_DETAILS = @20;
    const NSNumber *CHECKOUT_STAGE3_SUMMARY = @30;  
    const NSNumber *CHECKOUT_STAGE4_PAYMENT = @40;
    const NSNumber *CHECKOUT_STAGE5_VERIFICATION = @50;
@endcode

A tracking event can now be sent for each corresponding stage of checkout.

@code{.m}
    /* Send checkout tracking event
     * "cycode"     Currency Code - must be three characters
     * "chkout"     Checkout Stage - must be the value 10, 20, 30, 40, or 50
     * "cntln"      Content Language
     * "itemid"     Item IDs in the form "shopid/itemID"
     * "genre"      Genre for each item
     * "ino"        Quanitity of Items for each item
     * "price"      Price for each item
     * "variation"  Variations of the items
     */
    [[RSDKAnalyticsRATTracker.sharedInstance eventWithEventType:@"checkout" 
                    parameters:@{
                        @"cycode": @"JPY", 
                        @"chkout": CHECKOUT_STAGE4_PAYMENT,
                        @"cntln": @"fr_CA",
                        @"itemid": arrayOfItemIds,
                        @"genre": arrayOfItemGenres, 
                        @"ino": arrayOfItemQuantities, 
                        @"price": arrayOfItemPrices, 
                        @"variation": dictionaryOfVariations
                    }] track];
@endcode

@subsection analytics-custom-events Custom Events
The following code is an example of a tracking event with `cp` (custom parameters) defined. The custom parameters are passed as a dictionary.

@code{.m}
    /* Tracking event with custom parameters
     * "cp" Custom Parameters - passed in as a dictionary
     */
    [[RSDKAnalyticsRATTracker.sharedInstance eventWithEventType:@"customEventName" 
                    parameters:@{
                        @"cp": @{
                            @"custom_param_1": @"value",
                            @"custom_param_2": @"value"
                        }                    
                    }] track];
@endcode

@subsection search-results Search Results
The following code is an example of a tracking event that could be sent to track search results.

@code{.m}
    /* Track search results
     * "lang"   Search selected language
     * "sq"     Search Query
     * "oa"     Search method - "a" for AND - "o" for OR
     * "esq"    Excluded search query
     * "genre"  Genre or category
     * "tag"    An array of tags
     */
    [[RSDKAnalyticsRATTracker.sharedInstance eventWithEventType:@"customEventName" 
                    parameters:@{
                        @"lang": @"English", 
                        @"sq": @"search query",
                        @"oa": @"a", 
                        @"esq": @"excluded query", 
                        @"genre": @"category", 
                        @"tag": @[@"tag 1", @"tag 2"]
                    }] track];
@endcode

@section analytics-advanced Advanced Usage

@subsection analytics-network-monitoring Notifications for Upload Success and Failure
You can monitor the module's network activity by listening
to the @ref RSDKAnalyticsWillUploadNotification, @ref RSDKAnalyticsUploadFailureNotification
and @ref RSDKAnalyticsUploadSuccessNotification notifications. For example:

@code{.m}
	[[NSNotificationCenter defaultCenter]
		addObserverForName:RSDKAnalyticsUploadSuccessNotification
		object:nil
		queue:[NSOperationQueue currentQueue]
		usingBlock:^(NSNotification *note) {
			NSLog(@"Successfully sent these records: %@", note.object);
		}];
@endcode

@subsection analytics-configure-idfa IDFA tracking
The SDK automatically tracks the [advertising identifier (IDFA)][idfa] by default. **It is not recommended to disable this feature**, but you can still disable it by setting RSDKAnalyticsManager::shouldTrackAdvertisingIdentifier to `NO`:

~~~{.m}
    // Swift
    RSDKAnalyticsManager.shared().shouldTrackAdvertisingIdentifier = false

    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldTrackAdvertisingIdentifier = NO;
~~~

@subsection analytics-custom-tracker Creating a Custom Tracker
A custom @ref RSDKAnalyticsTracker "tracker" can be @ref RSDKAnalyticsManager::addTracker: "registered" to the @ref RSDKAnalyticsManager "manager". First, a @ref RSDKAnalyticsTracker "tracker" interface and implementation must be defined. RSDKAnalyticsTracker::processEvent will pass a @ref RSDKAnalyticsEvent object which contains the event name and parameters and a @ref RSDKAnalyticsState object which contains attributes automatically generated by the SDK.

@code{.m}
    @interface CustomTrackerName : NSObject<RSDKAnalyticsTracker>

    @end

    @implementation CustomTrackerName

    - (instancetype)init
    {
        if (self = [super init])
        {
            //Code to initialize custom tracker
            //...
        }
        return self;
    }

    - (BOOL)processEvent:(RSDKAnalyticsEvent *)event state:(RSDKAnalyticsState *)state
    {
        // RSDKAnalyticsEvent contains the event name and parameters
        NSString *eventName = event.name;
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        [json addEntriesFromDictionary:event.parameters];

        // RSDKAnalyticsState will contain the following data
        NSString *sessionIdentifier = state.sessionIdentifier;
        NSString *deviceIdentifier = state.deviceIdentifier;
        NSString *currentVersion = state.currentVersion;
        NSString *advertisingIdentifier = state.advertisingIdentifier;
        CLLocation *lastKnownLocation = state.lastKnownLocation;
        NSDate *sessionStartDate = state.sessionStartDate;
        BOOL *loggedIn = state.loggedIn;
        NSString *userIdentifier = state.userIdentifier;
        NSString *loginMethod = state.loginMethod;
        NSString *linkIdentifier = state.linkIdentifier;
        RSDKAnalyticsOrigin *origin = state.origin;
        UIViewController *lastVisitedPage = state.lastVisitedPage;
        UIViewController *currentPage = state.currentPage;
        NSString *lastVersion = state.lastVersion;
        NSInteger lastVersionLaunches = state.lastVersionLaunches;
        NSDate *initialLaunchDate = state.initialLaunchDate;
        NSDate *installLaunchDate = state.installLaunchDate;
        NSDate *lastLaunchDate = state.lastLaunchDate;
        NSDate *lastUpdateDate = state.lastUpdateDate;

        // Process and send data to custom tracker
        //...

        return YES;
    }

    @end
@endcode

The custom tracker can then be initialized and added to the @ref RSDKAnalyticsManager "manager".

@code{.m}
    // Initialize custom tracker
    RSDKAnalyticsManager *_manager = RSDKAnalyticsManager.sharedInstance;
    NSError *error;
    CustomTrackerName *tracker = [CustomTrackerName.alloc init];

    // Add custom tracker to manager
    BOOL success = [_manager addTracker:tracker error:&error];
    if (success) {
        //Custom tracker added successfully
    } else {
        //Handle errors
    }

    // Tracking events can now be sent to the custom tracker
    [[RSDKAnalyticsEvent.alloc initWithName:@"my.event" parameters:@{@"foo": @"bar"}] track];
@endcode

@section analytics-changelog Changelog

@subsection analytics-2-7-0 2.7.0 (2016-08-xx)
* Major rewrite.
* Support for custom event trackers.
* Automatic KPI tracking from other parts of our SDK.
* Deprecated RSDKAnalyticsManager::spoolRecords:, RSDKAnalyticsItem and RSDKAnalyticsRecord.

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
