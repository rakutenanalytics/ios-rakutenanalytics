@tableofcontents
@section analytics-module Introduction
The **analytics** module provides APIs for tracking user activity and automatically sends reports to the Rakuten Analytics servers.

@attention This module tracks the [IDFA][idfa] by default to track installation and conversion rates. See the @ref analytics-appstore "AppStore Submission Procedure" section below for more information.

@section analytics-installing Installing
See the [Ecosystem SDK documentation](https://www.raksdtd.com/ios/) guide for a detailed step-by-step guide on installing the SDK.

Alternatively, you can also use this SDK module as a standalone library. To use the SDK module as a standalone library, your `Podfile` should contain:

@code{.rb}
source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

pod 'RSDKAnalytics'
@endcode

Run `pod install` to install the module and its dependencies.

@section analytics-tutorial Getting started
@attention This module depends on the [deviceinformation](../deviceinformation-latest) module to retrieve the device's unique identifier. The deviceinformation module also requires keychain access for proper configuration. See @ref device-information-keychain-setup "Setting up the keychain" for more information.

@attention Without the deviceinformation module, RSDKAnalyticsManager::spoolRecord: raises a `NSObjectInaccessibleException`.

@subsection analytics-register Registering a new application
* [Registration Form](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Introduction+Application+Form) (from `r-intra`)
* Support email for administrative tasks: dev-rat@mail.rakuten.com

@subsection analytics-configure-rat Configuring RAT
@attention Applications **MUST** configure their RAT `accountId` and `applicationId` with the methods presented below, or automatic KPI tracking for a number of SDK features (SSO, installs, conversions, etc) will be disabled.

@code{.swift}
    // Swift
    let rat = RATTracker.shared()
    rat.configure(withAccountId:     YOUR_RAT_ACCOUNT_ID)
    rat.configure(withApplicationId: YOUR_RAT_APPLICATION_ID)
@endcode
@code{.m}
    // Obj-C
    RATTracker *rat = RATTracker.sharedInstance;
    [rat configureWithAccountId:     YOUR_RAT_ACCOUNT_ID];
    [rat configureWithApplicationId: YOUR_RAT_APPLICATION_ID];
@endcode

@subsection analytics-configure-staging Using the staging environment
The analytics module can be configured to use the staging environment when talking to the backend by setting RSDKAnalyticsManager::shouldUseStagingEnvironment to `YES`:

@code{.swift}
    // Swift:
    AnalyticsManager.shared().shouldUseStagingEnvironment = true
@endcode

@code{.m}
    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldUseStagingEnvironment = YES;
@endcode

@note Currently, the RAT staging server requires an ATS exception. See [RATQ-329](https://jira.rakuten-it.com/jira/browse/RATQ-329) for more information and tracking progress.

@subsection analytics-configure-location Location Tracking

@warning The SDK does not *actively* track the device's location even if the user has granted access to the app and the RSDKAnalyticsManager::shouldTrackLastKnownLocation property is set to `YES`. Instead, it passively monitors location updates captured by your application. 
@warning Your app must first request permission to use location services for a valid reason, as shown at [Requesting Permission to Use Location Services](https://developer.apple.com/reference/corelocation/cllocationmanager?language=objc#1669513). **Note that monitoring the device location for no other purpose than tracking will get your app rejected by Apple.**
@warning See the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html) for more information on how to request location updates. 

If you want to prevent our SDK from tracking the last known location, you can set RSDKAnalyticsManager::shouldTrackLastKnownLocation to `NO`. Location tracking is enabled by default.

@code{.swift}
    // Swift:
    AnalyticsManager.shared().shouldTrackLastKnownLocation = false
@endcode

@code{.m}
    // Obj-C:
    RSDKAnalyticsManager.sharedInstance.shouldTrackLastKnownLocation = NO;
@endcode

@subsection analytics-recording Recording activity
Events are created with RSDKAnalyticsEvent::initWithName:parameters: and spooled by calling their @ref RSDKAnalyticsEvent::track "track" method.

#### Tracking generic events
Tracking a generic event relies on a @ref RSDKAnalyticsTracker "tracker" capable of processing the event currently being @ref RSDKAnalyticsManager::addTracker: "registered".

@code{.swift}
    // Swift
    AnalyticsManager.Event(name: "my.event", parameters: ["foo": "bar"]).track()
@endcode

@code{.m}
    // Obj-C
    [[RSDKAnalyticsEvent.alloc initWithName:@"my.event" parameters:@{@"foo": @"bar"}] track];
@endcode

#### Tracking RAT-specific events
A concrete tracker, RATTracker, is automatically registered and interacts with the **Rakuten Analytics Tracker (RAT)**. You can also use RATTracker::eventWithEventType:parameters: for creating events that will only be processed by RAT. For more information about the various parameters accepted by that service, refer to the [RAT Specification](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Parameter+Spec).

@note Our SDK automatically tracks a number of RAT parameters for you, so you don't have to include those when creating an event: `acc`, `aid`, `etype`, `powerstatus`, `mbat`, `dln`, `loc`, `mcn`, `model`, `mnetw`, `mori`, `mos`, `online`, `cka`, `ckp`, `cks`, `ua`, `app_name`, `app_ver`, `res`, `ltm`, `ts1`, `tzo`, `userid` and `ver`.

@code{.swift}
    // Swift
    RATTracker.shared().event(eventType: "click", parameters:["pgn": "coupon page"]).track()
@endcode

@code{.m}
    // Obj-C
    [[RATTracker.sharedInstance eventWithEventType:@"click" parameters:@{@"pgn": @"coupon page"}] track];
@endcode

@subsection analytics-standard-events Standard Events
The SDK will automatically send events to the Rakuten Analytics Tracker for certain actions. The event type parameter for all of these events are prefixed with `_rem_`. We also provide @ref AnalyticsEvents "named constants" for all of those.

Event name         | Description
-------------------|-------------------
`_rem_init_launch` | Application is launched for the first time ever.
`_rem_launch`      | Application is launched.
`_rem_end_session` | Application goes into background.
`_rem_update`      | Application is launched and its version number does not match the version number of the previous launch.
`_rem_login`       | User logged in successfully.
`_rem_logout`      | User logged out.
`_rem_install`     | Application version is launched for the first time.

#### Automatically Generated State Attributes
The SDK will automatically generate certain attributes about the @ref RSDKAnalyticsState "state" of the device, and pass them to every registered @ref RSDKAnalyticsTracker "tracker" when asked to process an event.

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

@section analytics-rat-examples RAT Examples
@note These examples are all using @ref RATTracker to send [RAT specific parameters](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Parameters+Definition). If using a custom tracker, @ref RSDKAnalyticsEvent should be used instead.

@subsection analytics-rat-example-kibana Using Kibana to Test and Visualize Analytics
[Kibana](http://grp01.kibana.geap.intra.rakuten-it.com/) can be used to test your analytics or to visualize your data in real time. To find all analytics data for your app, you can search for your Application ID by using a search query similar to `aid:999`.

To find data for a certain event type, such as one of the @ref analytics-standard-events "standard events", you can add the `etype` to your search query, for example `aid:999 AND etype:_rem_launch`.

@subsection analytics-rat-example-screen-tracking Screen Tracking
The following code is an example that can be used to track when a view controller loads.

@note Our next version will automatically track screen transitions for you. Stay tuned!

@code{.swift}
    /* Track view controller launch
     * "pgn"    Page Name
     * "pgt"    Page Type ("top", "search", "shop_item", "cart_modify", or "cart_checkout")
     */
         
    // Swift
    class ViewController: UIViewController {
        override func viewDidLoad() {
            RATTracker.shared().event(eventType: "pv", 
                                     parameters:["pgn": "Main", 
                                                 "pgt": "top"
                                                ]).track()
        }
    }
@endcode

@code{.m}
    // Objective-C
    - (void)viewDidLoad {
        [[RATTracker.sharedInstance eventWithEventType:@"pv" 
                                            parameters:@{@"pgn": @"Main",
                                                         @"pgt": @"top"
                                                        }] track];
    }
@endcode

@subsection analytics-rat-example-ui-interactions UI Interaction
The following code is an example that can be used to track button clicks.

@code{.swift}
    /* Track Button Clicks
     * "pgn"    Page Name
     * "target" Element clicked
     * "gol"    Goal Id - Goals are specific strategies you'll leverage to accomplish your business objectives.
     */

    // Swift
    @IBAction func buttonTapped(sender: UIButton) {
        RATTracker.shared().event(eventType: "click", 
                                 parameters:["pgn": "Main", 
                                             "target": "search_btn",
                                             "gol": "Improve marketing effectiveness"
                                            ]).track()
    }
@endcode

@code{.m}
    // Objective-C
    - (IBAction)buttonTapped:(UIButton *)sender {
        [[RATTracker.sharedInstance eventWithEventType:@"click" 
                                            parameters:@{@"pgn": @"Main", 
                                                         @"target": @"search_btn",
                                                         @"gol": @"Improve marketing effectiveness"
                                                        }] track];
    }
@endcode

@subsection analytics-rat-example-custom-events RAT events with Custom Parameters
The following code is an example of a tracking event with `cp` (custom parameters) defined. The custom parameters are passed as a dictionary.

@code{.swift}
    /* Tracking event with custom parameters
     * "pgn"    Page Name
     * "cp"     Custom Parameters - passed in as a dictionary
     */

    // Swift
    RATTracker.shared().event(eventType: "pv", 
                             parameters:["pgn": "Main", 
                                         "cp": ["custom_param_1": "value",
                                                "custom_param_2": 10,
                                                "custom_param_3": true]]).track()
@endcode

@code{.m}
    // Objective-C
    [[RATTracker.sharedInstance eventWithEventType:@"pv" 
                                        parameters:@{@"pgn": @"Main", 
                                                     @"cp": @{@"custom_param_1": @"value",
                                                              @"custom_param_2": @10,
                                                              @"custom_param_3": @YES}}] track];
@endcode

@subsection analytics-rat-example-search-results Tracking search results with RAT
The following code is an example of a tracking event that could be sent to track search results.

@code{.swift}
    /* Track search results
     * "pgn"    Page Name
     * "pgt"    Page Type
     * "lang"   Search selected language
     * "sq"     Search Query
     * "oa"     Search method - "a" for AND - "o" for OR
     * "esq"    Excluded search query
     * "genre"  Genre or category
     * "tag"    An array of tags
     */

    // Swift
    RATTracker.shared().event(eventType: "pv", 
                             parameters:["pgn": "shop_search",
                                         "pgt": "search",
                                         "lang": "English", 
                                         "sq": "search query",
                                         "oa": "a", 
                                         "esq": "excluded query", 
                                         "genre": "category", 
                                         "tag": ["tag 1", "tag 2"]]).track()
@endcode

@code{.m}
    // Objective-C
    [[RATTracker.sharedInstance eventWithEventType:@"pv" 
                                        parameters:@{@"pgn": @"shop_search",
                                                     @"pgt": @"search",
                                                     @"lang": @"English", 
                                                     @"sq": @"search query",
                                                     @"oa": @"a", 
                                                     @"esq": @"excluded query", 
                                                     @"genre": @"category", 
                                                     @"tag": @[@"tag 1", @"tag 2"]}] track];
@endcode

@subsection analytics-rat-example-network-monitoring Monitoring RAT traffic
You can monitor RATTracker's network activity by listening
to the @ref RATWillUploadNotification, @ref RATUploadFailureNotification
and @ref RATUploadSuccessNotification notifications. For example:

@code{.m}
- (void)viewDidLoad {
    [super viewDidLoad];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(failedToUpload:)
                                               name:RATUploadFailureNotification
                                             object:nil];
}

- (void)failedToUpload:(NSNotification *)notification {
    NSArray *records = notification.object;
    NSError *error = notification.userInfo[NSUnderlyingErrorKey];
    NSLog(@"RATTracker failed to upload: %@, reason = %@", records, error.localizedDescription);
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}
@endcode

@section analytics-advanced Advanced Usage
@subsection analytics-configure-idfa IDFA tracking
The SDK automatically tracks the [advertising identifier (IDFA)][idfa] by default. **It is not recommended to disable this feature**, but you can still disable it by setting RSDKAnalyticsManager::shouldTrackAdvertisingIdentifier to `NO`:

@code{.swift}
    // Swift
    AnalyticsManager.shared().shouldTrackAdvertisingIdentifier = false
@endcode

@code{.m}
    // Obj-C
    RSDKAnalyticsManager.sharedInstance.shouldTrackAdvertisingIdentifier = NO;
@endcode

@subsection analytics-custom-tracker Creating a Custom Tracker
Custom @ref RSDKAnalyticsTracker "trackers" can be @ref RSDKAnalyticsManager::addTracker: "added" to
the @ref RSDKAnalyticsManager "manager".

Create a class and implement the RSDKAnalyticsTracker protocol. Its [processEvent(event, state)](protocol_r_s_d_k_analytics_tracker_01-p.html#abd4a093a74d3445fe72916f16685f5a3)
method will receive an @ref RSDKAnalyticsEvent "event" with a name and parameters, as well as a @ref RSDKAnalyticsState "state" with attributes automatically
generated by the SDK.

The custom tracker below just prints a few diagnostic messages. A real one would upload some data to a server.

@code{.swift}
    // Swift
    public class CustomTracker: NSObject, Tracker {
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

            // Unknown event!?
            return false
        }
    }
@endcode

@code{.m}
    // Objective-C
    @interface CustomTracker : NSObject<RSDKAnalyticsTracker>
    @end
    
    NSString *const CustomTrackerMyEventName = @"customtracker.myeventname";
    
    @implementation CustomTracker
    - (BOOL)processEvent:(RSDKAnalyticsEvent *)event state:(RSDKAnalyticsState *)state {
        if ([event.name isEqualToString:RSDKAnalyticsInitialLaunchEventName]) {
            NSLog(@"I've just been launched!");
            return YES;
        }
        else if ([event.name isEqualToString:RSDKAnalyticsLoginEventName]) {
            NSLog(@"User with tracking id '%@' just logged in!", state.userid);
            return YES;
        }
        else if ([event.name isEqualToString:CustomTrackerMyEventName]) {
            NSLog(@"Received my event!");
            return YES;
        }
        // ...
        
        // Unknown event!?
        return NO
    }
    @end
@endcode

The custom tracker can then be added to the RSDKAnalyticsManager:

@code{.swift}
    // Swift

    // Add CustomTracker to the manager
    RSDKAnalyticsManager.shared().add(CustomTracker())

    // Tracking events can now be sent to the custom tracker
    AnalyticsManager.Event(name: CustomTrackerMyEventName, parameters: nil).track()
@endcode
@code{.m}
    // Objective-C

    // Add CustomTracker to the manager
    // Initialize custom tracker
    [RSDKAnalyticsManager.sharedInstance addTracker:CustomTracker.new];

    // Tracking events can now be sent to the custom tracker
    [[RSDKAnalyticsEvent.alloc initWithName:CustomTrackerMyEventName parameters:nil] track];
@endcode

@section analytics-changelog Changelog

@subsection analytics-2-7-0 2.7.0 (2016-09-26)
* Major rewrite.
* Support for custom event trackers.
* Automatic KPI tracking from other parts of our SDK: login/logout, sessions, application lifecycles.
* Deprecated RSDKAnalyticsManager::spoolRecord:, RSDKAnalyticsItem and RSDKAnalyticsRecord.

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
