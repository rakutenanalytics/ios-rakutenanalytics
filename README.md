@tableofcontents{HTML:2}
@attention This module supports iOS 10.0 and above. It has been tested with iOS 10.0 and above.
@section analytics-module Introduction
The **analytics** module provides APIs for tracking events and automatically sends a subset of lifecycle events to the [Rakuten Analytics Tracker](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Home) (RAT) service.

@attention If a user has given their permission this module uses the [IDFA][idfa] to track installation and conversion rates. See the @ref analytics-appstore "AppStore Submission Procedure" section below for more information.

@section analytics-installing Installing
To use the module in its default configuration your `Podfile` should contain:

@code{.rb}
source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

pod 'RAnalytics'
@endcode

Run `pod install` to install the module and its dependencies.

@attention The analytics module since version 3.0.0 is separated into `Core` and `RAT` subspecs. The default subspec is `RAT` which depends on `Core`. If you do not want automatic user tracking sent to RAT you should use the `Core` subspec in your Podfile:

@code{.rb}
source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

pod 'RAnalytics/Core'
@endcode

@section analytics-support Getting support
For support (bug reports, feature requests, questions etc.) please check our [FAQ page](https://developers.rakuten.net/hc/en-us) or contact us by raising an `Analytics SDK (RAT-SDK)` inquiry from our [support page](https://developers.rakuten.com/intra/support).

@section analytics-tutorial Getting started
@subsection analytics-register RAT credentials
* You must have a RAT account ID and application ID to track events using the Rakuten Analytics Tracker. Apply for these credentials from this [form](https://confluence.rakuten-it.com/confluence/display/RAT/Application+for+RAT+Implementation) on the RAT site.

@subsection analytics-configure-rat Configuring RAT
@attention Applications **MUST** configure their RAT `accountId` and `applicationId` in their info.plist as follows:

##### Plist Configuration

Key         | Value (Number type)
-------------------|-------------------
`RATAccountIdentifier` | `YOUR_RAT_ACCOUNT_ID`
`RATAppIdentifier` | `YOUR_RAT_APPLICATION_ID`

@subsection analytics-keychain-setup Configuring the keychain
@attention This module requires keychain access to work properly. You must add a `jp.co.rakuten.ios.sdk.deviceinformation` keychain access group to your application's "Keychain Sharing" capabilities, as shown below.

@image html keychain-setup.png width=40%

@warning Note that `jp.co.rakuten.ios.sdk.deviceinformation` **must not** be the first entry in this list. The first entry must be your own application's bundle identifier.

@subsection analytics-rat-example-kibana Using Kibana to verify successful integration
RAT's [Kibana](https://confluence.rakuten-it.com/confluence/display/RAT/How+to+Check+Data+that+is+being+Sent+to+RAT#HowtoCheckDatathatisbeingSenttoRAT-Step2:[ServerSide]ChecktheeventonRATserver) STG and PROD sites can be used to check events sent by your app. 

To find all analytics data for your app, you can search for your Application Identifier `aid:999` or `app_name:<your bundle id>`.

To find data for a certain event type, such as one of the @ref analytics-standard-events "standard events", you can add the `etype` to your search query, for example `aid:999 AND etype:_rem_launch`.

@section analytics-configure Advanced configuration

@subsection analytics-configure-endpoint Configure a custom endpoint
To use a custom endpoint when talking to the analytics backend add a `RATEndpoint` key to the app's info.plist and set it to the custom endpoint. e.g. to use the RAT staging environment set `RATEndpoint` to `https://stg.rat.rakuten.co.jp/`.

A custom endpoint can also be configured at runtime as below:
##### Swift

@code{.swift}
    AnalyticsManager.shared().set(endpointURL: URL(string: "https://rat.rakuten.co.jp/"))
@endcode

##### Objective-C

@code{.m}
    [RAnalyticsManager.sharedInstance setEndpointURL:[NSURL URLWithString:@"https://rat.rakuten.co.jp/"]];
@endcode

@subsection analytics-configure-location Location tracking
@warning The SDK does not *actively* track the device's location even if the user has granted access to the app and the RAnalyticsManager::shouldTrackLastKnownLocation property is set to `YES`. Instead, it passively monitors location updates captured by your application.
@warning Your app must first request permission to use location services for a valid reason, as shown in Apple's [CoreLocation documentation](https://developer.apple.com/documentation/corelocation?language=objc). **Monitoring the device location for no other purpose than tracking will get your app rejected by Apple.**
@warning See the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html) for more information on how to request location updates.

Location tracking is enabled by default. If you want to prevent our SDK from tracking the last known location, you can set RAnalyticsManager::shouldTrackLastKnownLocation to `NO`:

##### Swift

@code{.swift}
    AnalyticsManager.shared().shouldTrackLastKnownLocation = false
@endcode

##### Objective C

@code{.m}
    RAnalyticsManager.sharedInstance.shouldTrackLastKnownLocation = NO;
@endcode

@subsection analytics-configure-idfa IDFA tracking
The SDK automatically tracks the [advertising identifier (IDFA)][idfa] by default but you can still disable it by setting RAnalyticsManager::shouldTrackAdvertisingIdentifier to `NO`:

##### Swift
@code{.swift}
    AnalyticsManager.shared().shouldTrackAdvertisingIdentifier = false
@endcode

##### Objective C
@code{.m}
    RAnalyticsManager.sharedInstance.shouldTrackAdvertisingIdentifier = NO;
@endcode

#### IDFA tracking on iOS 14.x and above
@attention If the available IDFA value is valid (non-zero'd) the RAnalytics SDK will use it. This change was implemented in response to Apple's [announcement](https://developer.apple.com/news/?id=hx9s63c5) that they have delayed the below requirement to obtain permission for user tracking until early 2021.

If the app is built with the iOS 14 SDK and embeds the [AppTrackingTransparency framework](https://developer.apple.com/documentation/apptrackingtransparency), the Analytics SDK uses IDFA on iOS 14.x and greater only when the user has authorized tracking.
Your app can display the IDFA tracking authorization popup by adding a `NSUserTrackingUsageDescription` key in your Info.plist and calling the [requestTrackingAuthorization function](https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/3547037-requesttrackingauthorization).

##### Swift
@code{.swift}
ATTrackingManager.requestTrackingAuthorization { status in
    switch status {
    case .authorized:
        // Now that tracking is authorized we can get the IDFA
        let idfa = ASIdentifierManager.shared().advertisingIdentifier
        
    default: () // IDFA is not authorized
    }
}
@endcode

##### Objective C
@code{.h}
[ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
    switch (status) {
        case ATTrackingManagerAuthorizationStatusAuthorized: {
            NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            }
            break;
            
      default: // IDFA is not authorized
        break;
    }
}];
@endcode

@subsection analytics-set-userid Manually set a user identifier
From version 5.2.0 there is a new `setUserIdentifier:` API available for your app to manually set the tracking user identifier. After calling the API the user identifier that you set will be used for subsequent tracked events.

##### Swift
@code{.swift}
RAnalyticsManager.sharedInstance.setUserIdentifier("a_user_identifier")
@endcode

##### Objective C
@code{.m}
[RAnalyticsManager.sharedInstance setUserIdentifier:@"a_user_identifier"];
@endcode

Use cases:
- App retrieves the encrypted easy ID using other SDKs or REST API then sets it using the `setUserIdentifier:` method.
- App can do this every time the app is launched/opened, or when new a user logs in.
- App should set the user identifier to nil when the user logs out.

@subsection analytics-logging Configure debug logging

To configure the module's internal debug logging use `AnalyticsManager#set(loggingLevel:)`.

To set logging to debug level (and above i.e. also print info/warning/error logs) use the following function call:
@code{.swift}
AnalyticsManager.shared().set(loggingLevel: .debug)
@endcode

@attention For user privacy and app security the module will *not* print **verbose** or **debug** logs in a release build.

By default the module will show error logs, even in a release build. To disable the module's logs completely call:
@code{.swift}
AnalyticsManager.shared().set(loggingLevel: .none)
@endcode

@attention The plist flag `RMSDKEnableDebugLogging` has been deprecated and has no effect now. You must use the above `AnalyticsManager` API function to configure logging levels.

@section analytics-tracking Tracking events
Events are created with RAnalyticsEvent::initWithName:parameters: and spooled by calling their @ref RAnalyticsEvent::track "track" method.

#### Tracking generic events
Tracking a generic event relies on a @ref RAnalyticsTracker "tracker" capable of processing the event currently being @ref RAnalyticsManager::addTracker: "registered".

##### Swift

@code{.swift}
    AnalyticsManager.Event(name: "my.event", parameters: ["foo": "bar"]).track()
@endcode

##### Objective C

@code{.m}
    [[RAnalyticsEvent.alloc initWithName:@"my.event" parameters:@{@"foo": @"bar"}] track];
@endcode

#### Tracking RAT-specific events
A concrete tracker, RAnalyticsRATTracker, is automatically registered and interacts with the **Rakuten Analytics Tracker (RAT)**. You can also use RAnalyticsRATTracker::eventWithEventType:parameters: for creating events that will only be processed by RAT. For more information about the various parameters accepted by that service, see the [RAT Parameter Spec](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Parameter+Specifications).

@note Our SDK automatically tracks a number of RAT parameters for you, so you don't have to include those when creating an event: `acc`, `aid`, `etype`, `powerstatus`, `mbat`, `dln`, `loc`, `mcn`, `model`, `mnetw`, `mori`, `mos`, `online`, `cka`, `ckp`, `cks`, `ua`, `app_name`, `app_ver`, `res`, `ltm`, `ts1`, `tzo`, `userid` and `ver`.

##### Swift

@code{.swift}
    RAnalyticsRATTracker.shared().event(eventType: "click", parameters:["pgn": "coupon page"]).track()
@endcode

##### Objective C

@code{.m}
    [[RAnalyticsRATTracker.sharedInstance eventWithEventType:@"click" parameters:@{@"pgn": @"coupon page"}] track];
@endcode

@note You can override the `acc` and `aid` default values by including those keys in the `parameters` dictionary when you create an event.

##### Swift

@code{.swift}
    RAnalyticsRATTracker.shared().event(eventType: "click", parameters:["acc": 123]).track()
@endcode

##### Objective C

@code{.m}
    [[RAnalyticsRATTracker.sharedInstance eventWithEventType:@"click" parameters:@{@"acc": @123}] track];
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
`_rem_visit`       | A new page is shown. Application developers can also emit this event manually if they wish so, for instance to track pages that are not view controllers (e.g. a table cell). In that case, they should set the event's parameter `page_id` to a string that uniquely identifies the visit they want to track.
`_rem_push_notify` | A push notification has been received while the app was active, or the app was opened from a push notification. A value that uniquely identifies the push notification is provided in the `tracking_id` parameter. See its definition below.

##### How page views are automatically tracked
We use method swizzling to automatically trigger a @ref RAnalyticsPageVisitEventName "visit event" every time a new view controller is presented, unless:
    * The view controller is one of the known "chromes" used to coordinate "content" view controllers, i.e. one of `UINavigationController`, `UISplitViewController`, `UIPageViewController` and `UITabBarController`.
    * The view controller is showing a system popup, i.e. `UIAlertView`, `UIActionSheet`, `UIAlertController` or `_UIPopoverView`.
    * Either the view controller, its view or the window it's attached to is an instance of an Apple-private class, i.e. a class whose name has a `_` prefix and which comes from a system framework. This prevents many on-screen system accessories from generating bogus page views.
    * The class of the window the view controller is attached to is a subclass of `UIWindow` coming from a system framework, i.e. the window is not a normal application window. Certain on-screen system accessories, such as the system keyboard's autocompletion word picker, would otherwise trigger events as well.

Those @ref RAnalyticsPageVisitEventName "visit events" are available to all @ref RAnalyticsTracker "trackers", and the view controller being the event's subject can be found in the @ref RAnalyticsState::currentPage "currentPage" property of the @ref RAnalyticsState "event state" passed to RAnalyticsTracker::processEvent:state:.

The @ref RAnalyticsRATTracker "RAT tracker" furthermore ignores view controllers that have no title, no navigation item title, and for which no URL was found on any webview part of their view hierarchy at the time `-viewDidLoad` was called, unless they have been subclassed by the application or one of the frameworks embedded in the application. This filters out events that would give no information about what page was visited in the application, such as events reporting a page named `UIViewController`. For view controllers with either a title, navigation item title or URL, the library also sets the `cp.title` and `cp.url` fields to the `pv` event it sends to RAT.

##### Push notification tracking identifier
The value for the `tracking_id` parameter of the `_rem_push_notify` event is computed like this:
* If the notification payload contains a value named `rid`, `tracking_id` takes the value `rid:<value>`.
* Else, if the notification payload contains a value named `notification_id`, `tracking_id` takes the value `nid:<value>`.
* Else, `tracking_id` uses the message or title of the push notification and takes the value `msg:<SHA256(message or title)>`.

#### Requirements
The below table shows the required components of each standard event which is tracked automatically by the **analytics** module.

Event name         | Required components
-------------------|-------------------
`_rem_login`       | **authentication** module (3.10.1 or later).
`_rem_logout`      | **authentication** module (3.10.1 or later).

#### Automatically Generated State Attributes
The SDK will automatically generate certain attributes about the @ref RAnalyticsState "state" of the device, and pass them to every registered @ref RAnalyticsTracker "tracker" when asked to process an event.

@section analytics-rat-examples RAT Examples
@note These examples all use @ref RAnalyticsRATTracker to send [RAT specific parameters](https://confluence.rakuten-it.com/confluence/display/RAT/RAT+Parameters+Definition). If you are using a custom tracker, @ref RAnalyticsEvent should be used instead.

@subsection analytics-rat-example-ui-interactions UI Interaction
The following code is an example that can be used to track button clicks. It uses RAT's standard `click` event and passes the page name, clicked element's id and goal id in the `pgn`, `target` and `gol` parameters, respectively.

##### Swift

@code{.swift}
    @IBAction func buttonTapped(sender: UIButton) {
        RAnalyticsRATTracker.shared().event(eventType: "click",
                                 parameters:["pgn": "Main",
                                             "target": "search_btn",
                                             "gol": "goal123456"]).track()
    }
@endcode

##### Objective C

@code{.m}
    // Objective-C
    - (IBAction)buttonTapped:(UIButton *)sender {
        [[RAnalyticsRATTracker.sharedInstance eventWithEventType:@"click"
                                            parameters:@{@"pgn": @"Main",
                                                         @"target": @"search_btn",
                                                         @"gol": @"goal123456"}] track];
    }
@endcode

@subsection analytics-rat-example-custom-events RAT events with Custom Parameters
The following is an example of tracking an event with custom parameters. It uses the standard `pv` RAT event used in the previous examples, and passes some custom `custom_param_##` parameters in the `cp` dictionary accepted by RAT for this purpose.

##### Swift

@code{.swift}
    RAnalyticsRATTracker.shared().event(eventType: "pv",
                             parameters:["pgn": "Main",
                                         "cp": ["custom_param_1": "value",
                                                "custom_param_2": 10,
                                                "custom_param_3": true]]).track()
@endcode

##### Objective C

@code{.m}
    [[RAnalyticsRATTracker.sharedInstance eventWithEventType:@"pv"
                                        parameters:@{@"pgn": @"Main",
                                                     @"cp": @{@"custom_param_1": @"value",
                                                              @"custom_param_2": @10,
                                                              @"custom_param_3": @YES}}] track];
@endcode

@section analytics-advanced Advanced Usage

@subsection analytics-app-to-web-tracking App to Web tracking
You can configure the SDK to inject a special tracking cookie which allows RAT to track events between the app and in-app webviews. The cookie is only injected on iOS 11.0 and later versions. This feaure is OFF by default. It can be enabled by setting RAnalyticsManager::enableAppToWebTracking to true.

@code{.swift}
    AnalyticsManager.shared().enableAppToWebTracking = true
@endcode

By default the cookie's domain will be set to the top-level Rakuten domain. Optionally, you can set a custom domain on the tracking cookie with RAnalyticsManager::setWebTrackingCookieDomainWithBlock:

@code{.swift}
    AnalyticsManager.shared().setWebTrackingCookieDomain { () -> String? in
        return ".my-domain.co.jp"
    }
@endcode

@subsection analytics-batching-delay Configure the Tracker Batching Delay
A @ref RAnalyticsTracker "Tracker" collects events and sends them to a backend in batches. 

The batching delay is a configurable value with default set to 1 second.

@attention In our [internal tests](https://jira.rakuten-it.com/jira/browse/SDKCF-1596) we noticed no significant impact on battery usage when the batching delay was reduced to 1 sec in our demo app. However you should perform your own developer testing and QA to determine the appropriate batching delay for your app.

You can configure a different delay with the RAnalyticsTracker::setBatchingDelay: and RAnalyticsTracker::setBatchingDelayWithBlock: methods.

### Example 1: Configure batching interval of 10 seconds

##### Swift

@code{.swift}

    RAnalyticsRATTracker.shared().set(batchingDelay: 10.0)
@endcode

##### Objective C

@code{.m}

    [RAnalyticsRATTracker.sharedInstance setBatchingDelay:10.0];
@endcode

### Example 2: Dynamic batching interval
#### - no batching for the first 10 seconds after app launch
#### - 10 second batching between 10 and 30 seconds after app launch
#### - 60 second batching after 30 seconds after app launch

##### Swift

@code{.swift}

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

@endcode

##### Objective C

@code{.m}

@interface CustomClass : NSObject
@property (nonatomic) NSTimeInterval startTime;
@end

@implementation CustomClass

- (instancetype)init
{
    if (self = [super init])
    {
        _startTime = [NSDate timeIntervalSinceReferenceDate];
    }
    return self;
}

- (void)setup
{
    [RAnalyticsRATTracker.sharedInstance setBatchingDelayWithBlock:^NSTimeInterval{
        NSTimeInterval secondsSinceStart = [NSDate timeIntervalSinceReferenceDate] - _startTime;

        if (secondsSinceStart < 10)
        {
            return 0;
        }
        else if (secondsSinceStart < 30)
        {
            return 10;
        }
        else
        {
            return 60;
        }
    }];
}

@endcode

@subsection analytics-appex Support for App Extensions
The SDK can be added as a dependency to an App Extension target (e.g. Today Widget) and will compile successfully. The SDK's APIs such as @ref RAnalyticsEvent::track "track" (to track a custom event) can be used from an App Extension. 

#### Requirements

App Extensions need to follow the requirements at @ref analytics-configure-rat "Configuring RAT".

* You MUST configure your RAT `accountId` and `applicationId` in the **App Extension** info.plist (in addition to your main app's info.plist)
* To send events to a different endpoint you can set a `RATEndpoint` key in the **App Extension** info.plist

#### Viewing App Extension events in Kibana

To search for App Extension events in [Kibana](https://confluence.rakuten-it.com/confluence/display/RAT/How+to+Check+Data+that+is+being+Sent+to+RAT#HowtoCheckDatathatisbeingSenttoRAT-Step2:[ServerSide]ChecktheeventonRATserver) use your **App Extension** name and not the application name e.g. use `app_name:jp.co.rakuten.sdk.ecosystemdemo.today` as the search term not `app_name:jp.co.rakuten.sdk.ecosystemdemo`.

#### Limitations

A known limitation due to app sandboxing is that the SDK cannot automatically fill the `userid` (normally contains a logged-in user's encrypted easy id) field in the payload of automatically tracked events such as `_rem_launch` when an event is sent by an App Extension.

#### Track encrypted easy id

To send the encrypted easy id in custom events you can add a Podfile dependency on [RAuthenticationCore](https://documents.developers.rakuten.com/ios-sdk/authentication-latest/#authentication-installing) to the App Extension target, load the user's account using RAuthenticationAccount::loadAccountWithName:service:error: and then manually set the `userid` key to the loaded account's RAuthenticationAccount::trackingIdentifier :

##### Swift

@code{.swift}
RAnalyticsRATTracker.shared().event(eventType: "custom_name", parameters: ["userid": account.trackingIdentifier]).track()
@endcode

##### Objective C

@code{.m}
[[RAnalyticsRATTracker.sharedInstance eventWithEventType: @"custom_name" parameters: @{@"userid": account.trackingIdentifier}] track];
@endcode

@subsection analytics-custom-tracker Creating a Custom Tracker
Custom @ref RAnalyticsTracker "trackers" can be @ref RAnalyticsManager::addTracker: "added" to the @ref RAnalyticsManager "manager".

Create a class and implement the RAnalyticsTracker protocol. Its [processEvent(event, state)](protocol_r_s_d_k_analytics_tracker_01-p.html#abd4a093a74d3445fe72916f16685f5a3)
method will receive an @ref RAnalyticsEvent "event" with a name and parameters, and a @ref RAnalyticsState "state" with attributes automatically
generated by the SDK.

The custom tracker in the code sample below only prints a few diagnostic messages. A real custom tracker would upload data to a server.

##### Swift

@code{.swift}
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

##### Objective C

@code{.m}
    @interface CustomTracker : NSObject<RAnalyticsTracker>
    @end

    NSString *const CustomTrackerMyEventName = @"customtracker.myeventname";

    @implementation CustomTracker
    - (BOOL)processEvent:(RAnalyticsEvent *)event state:(RAnalyticsState *)state {
        if ([event.name isEqualToString:RAnalyticsInitialLaunchEventName]) {
            NSLog(@"I've just been launched!");
            return YES;
        }
        else if ([event.name isEqualToString:RAnalyticsLoginEventName]) {
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

The custom tracker can then be added to the RAnalyticsManager:

##### Swift

@code{.swift}
    // Add CustomTracker to the manager
    RAnalyticsManager.shared().add(CustomTracker())

    // Tracking events can now be sent to the custom tracker
    AnalyticsManager.Event(name: CustomTrackerMyEventName, parameters: nil).track()
@endcode

##### Objective C

@code{.m}
    // Add CustomTracker to the manager
    // Initialize custom tracker
    [RAnalyticsManager.sharedInstance addTracker:CustomTracker.new];

    // Tracking events can now be sent to the custom tracker
    [[RAnalyticsEvent.alloc initWithName:CustomTrackerMyEventName parameters:nil] track];
@endcode

@section analytics-knowledge-base Knowledge Base
@subsection analytics-migratev2v3 Migrating from v2 to v3
- 2.13.0 is the final version of the RSDKAnalytics podspec. It has been renamed to RAnalytics podspec from version 3.0.0.
- Version 3.0.0 restructures the module and splits the functionality into `Core` and `RAT` subspecs.
- See @ref analytics-configure-rat "Configuring RAT" for the new plist approach for setting account ID and application ID. This replaces the deleted methods [configureWithAccountId:](https://documents.developers.rakuten.com/ios-sdk/analytics-2.13/#analytics-configure-rat) / [configureWithApplicationId:](https://documents.developers.rakuten.com/ios-sdk/analytics-2.13/#analytics-configure-rat)
- If you use the Analytics module directly in your app source (e.g. to track custom events) you will need to change all references (header imports, method calls etc.) from `RSDKAnalytics` to `RAnalytics`. Also, if you call `RATTracker` methods you will need to change those references to `RAnalyticsRATTracker`. This renaming was required so that module versions v2 and v3 can co-exist in an app binary.
- To depend on RAnalytics rather than RSDKAnalytics your Podfile should contain:

@code{.rb}
source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

pod 'RAnalytics'
@endcode

@subsection analytics-appstore AppStore Submission Procedure
Apple requests that you **disclose your usage of the advertising identifier (IDFA)** when releasing your application to the App Store.

@image html appstore-idfa.png "IDFA usage disclosure" width=80%

#### 1. Serve advertisements within the app.
Check this box if any of the following options apply to your app:
- Your app contains advertisements.
- You are using the **[discover](../discover-latest)** SDK module.

#### 2. Attribute this app installation to a previously served advertisement
Check this checkbox. The Rakuten SDK uses the IDFA for install attribution.

#### 3. Attribute an action taken within this app to a previously served advertisement
Check this checkbox. The Rakuten SDK uses the IDFA for re-engagment ads attribution.

#### 5. iOS Limited Ad Tracking
The Rakuten SDK fully complies with Apple requirement below:

> Check the value of this property before performing any advertising tracking. If the value is NO, use the advertising identifier only for the following purposes: frequency capping, conversion events, estimating the number of unique users, security and fraud detection, and debugging.

The Rakuten SDK only uses the IDFA for `conversion events, estimating the number of unique users, security and fraud detection`.

@subsection analytics-open-count-rate Push Notification Open Rate
From SDK version 5.2.0 open count tracking has been changed to only send an open event when an alert has been directly opened by the user. It is **highly recommended** to implement the **UNUserNotificationCenter** delegate method: [``userNotificationCenter(_:didReceive:withCompletionHandler:)``](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter) because it will more reliably track the push notification open count. If you only implement the **AppDelegate** methods [``application(_:didReceiveRemoteNotification:fetchCompletionHandler:)``](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623013-application) or [``application(_:didReceiveRemoteNotification:)``](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623117-application) your open rate will not be accurate.

@subsection analytics-rat-example-search-results Tracking search results with RAT
The code below shows an example of an event you could send to track which results get shown on a search page. It uses the standard `pv` RAT event used in the previous examples, and a number of standard RAT parameters. The parameters used are:

RAT param | Description
----------|---------------
`lang`    | The language used for the search.
`sq`      | The search terms.
`oa`      | `a` for requesting all search terms (AND), `o` for requesting one of them (OR).
`esq`     | Terms that should be excluded from the results.
`genre`   | Category for the results.
`tag`     | An array of tags.

##### Swift

@code{.swift}
RAnalyticsRATTracker.shared().event(eventType: "pv",
parameters:["pgn": "shop_search",
"pgt": "search",
"lang": "English",
"sq": "search query",
"oa": "a",
"esq": "excluded query",
"genre": "category",
"tag": ["tag 1", "tag 2"]]).track()
@endcode

##### Objective C

@code{.m}
[[RAnalyticsRATTracker.sharedInstance eventWithEventType:@"pv"
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
You can monitor the tracker network activity by listening
to the @ref RAnalyticsWillUploadNotification, @ref RAnalyticsUploadFailureNotification
and @ref RAnalyticsUploadSuccessNotification notifications. For example:

@code{.m}
- (void)viewDidLoad {
[super viewDidLoad];

[NSNotificationCenter.defaultCenter addObserver:self
selector:@selector(failedToUpload:)
name:RAnalyticsUploadFailureNotification
object:nil];
}

- (void)failedToUpload:(NSNotification *)notification {
NSArray *records = notification.object;
NSError *error = notification.userInfo[NSUnderlyingErrorKey];
NSLog(@"RAnalyticsRATTracker failed to upload: %@, reason = %@", records, error.localizedDescription);
}

- (void)dealloc {
[NSNotificationCenter.defaultCenter removeObserver:self];
}
@endcode

@section analytics-changelog Changelog
@subsection analytics-6-0-0 6.0.0 (2020-11-25)
* [SDKCF-2921](https://jira.rakuten-it.com/jira/browse/SDKCF-2921): Added tracking support for rich push notifications.
* [SDKCF-2938](https://jira.rakuten-it.com/jira/browse/SDKCF-2938): Fixed issue where push notification tracking event may not have been sent when UNUserNotification was disabled & app was in background on iOS 10.x.
* **Breaking API change**: Updated parameter type in `AnalyticsManager#set(loggingLevel:)` API due to the support added for building the module code as a framework.

@subsection analytics-5-3-0 5.3.0 (2020-10-30)
* [SDKCF-2843](https://jira.rakuten-it.com/jira/browse/SDKCF-2843): Added API to enable App to Web tracking. By default this feature is disabled. See @ref analytics-app-to-web-tracking.
* [SDKCF-2784](https://jira.rakuten-it.com/jira/browse/SDKCF-2784): Added API to configure logging level from app. The plist flag `RMSDKEnableDebugLogging` is now deprecated. See @ref analytics-logging for usage.

@subsection analytics-5-2-2 5.2.2 (2020-09-18)
* [SDKCF-2826](https://jira.rakuten-it.com/jira/browse/SDKCF-2826): Simplified the approach for handling IDFA. If the available IDFA value is valid (non-zero'd) the RAnalytics SDK will use it. This change was implemented in response to Apple's [announcement](https://developer.apple.com/news/?id=hx9s63c5) that they have delayed the requirement to obtain permission for user tracking until "early next year".
* [SDKCF-2749](https://jira.rakuten-it.com/jira/browse/SDKCF-2749): Fixed warning that status bar orientation UI methods are called from non-UI thread.

@subsection analytics-5-2-1 5.2.1 (2020-09-14)
* [SDKCF-2777](https://jira.rakuten-it.com/jira/browse/SDKCF-2777): Fixed a crash related to CTRadioAccessTechnologyDidChangeNotification.

@subsection analytics-5-2-0 5.2.0 (2020-09-02)
* [SDKCF-2659](https://jira.rakuten-it.com/jira/browse/SDKCF-2659): Implemented support for iOS 14 IDFA permission changes. See @ref analytics-configure-idfa.
* [SDKCF-2658](https://jira.rakuten-it.com/jira/browse/SDKCF-2658): Added `RAnalyticsManager.setUserIdentifier(userIdentifier:)` to allow apps to manually set a user identifier. See @ref analytics-set-userid.
* [SDKCF-2695](https://jira.rakuten-it.com/jira/browse/SDKCF-2695): Added value for user identifier in user logged out state.
* [SDKCF-2732](https://jira.rakuten-it.com/jira/browse/SDKCF-2732): Added support for the new Corelocation authorization delegate method on iOS 14.
* [SDKCF-2411](https://jira.rakuten-it.com/jira/browse/SDKCF-2411): Changed the approach of calculating push notification open count rate. See @ref analytics-open-count-rate.

@subsection analytics-5-1-0 5.1.0 (2020-07-17)
* [SDKCF-2606](https://jira.rakuten-it.com/jira/browse/SDKCF-2606): Changed the default batching delay to 1 second. See @ref analytics-batching-delay.
* [SDKCF-1654](https://jira.rakuten-it.com/jira/browse/SDKCF-1654): Fixed crash that can occur when Firebase SDK is also integrated.
* [SDKCF-2077](https://jira.rakuten-it.com/jira/browse/SDKCF-2077): Fixed bug where a device laying flat in landscape mode could set the wrong orientation mode in the event payload.

@subsection analytics-5-0-2 5.0.2 (2020-07-06)
* [SDKCF-2561](https://jira.rakuten-it.com/jira/browse/SDKCF-2561): Made storing of RAT cookies in shared cookie storage optional. The option was added to temporarily workaround a specific backend issue for a specific customer. **Warning**: You should not need to use this option, however if you choose do so it may impact your RAT tracking statistics.

@subsection analytics-5-0-1 5.0.1 (2020-04-30)
* [SDKCF-2291](https://jira.rakuten-it.com/jira/browse/SDKCF-2291): Fixed Swift naming macro build error in Xcode 11.4.
* [SDKCF-1561](https://jira.rakuten-it.com/jira/browse/SDKCF-1561): Send empty `mnetw` (network type - WiFi/4G/3G) field in the RAT event payload when device is offline.

@subsection analytics-5-0-0 5.0.0 (2020-02-27)
* [SDKCF-2017](https://jira.rakuten-it.com/jira/browse/SDKCF-2017): Removed all `UIWebView` references from code to comply with Apple [announcement](https://developer.apple.com/news/?id=12232019b)
* [SDKCF-1253](https://jira.rakuten-it.com/jira/browse/SDKCF-1253): Removed the deprecated `shouldUseStagingEnvironment` flag
* [SDKCF-1957](https://jira.rakuten-it.com/jira/browse/SDKCF-1957): Updated batching delay documentation to reference battery usage testing
* [SDKCF-1955](https://jira.rakuten-it.com/jira/browse/SDKCF-1955): Added missing module names to SDK Tracker's module map list
* [SDKCF-1562](https://jira.rakuten-it.com/jira/browse/SDKCF-1562): Added empty `mcn` (carrier name) field to the RAT event payload that will be sent when device is connected to WiFi

@subsection analytics-4-1-0 4.1.0 (2019-10-28)
* [SDKCF-1523](https://jira.rakuten-it.com/jira/browse/SDKCF-1523): Move RP cookie fetch functionality from RAT subspec to Core subspec so that it is available to modules that only have a dependency on Core

@subsection analytics-4-0-0 4.0.0 (2019-01-16)
* [SDKCF-740](https://jira.rakuten-it.com/jira/browse/SDKCF-740): Drop support for iOS versions below iOS 10.0

@subsection analytics-3-2-0 3.2.0 (2018-11-29)
* [SDKCF-16](https://jira.rakuten-it.com/jira/browse/SDKCF-16): Add an option to disable PageView (PV) tracking
* [SDKCF-759](https://jira.rakuten-it.com/jira/browse/SDKCF-759): Allow the SDK to send Performance Tracking info to RAT
* [SDKCF-801](https://jira.rakuten-it.com/jira/browse/SDKCF-801): Fix a bug where RAnalyticsIsAppleClass crash in Xcode 10.1

@subsection analytics-3-1-1 3.1.1 (2018-09-05)
* [SDKCF-619](https://jira.rakuten-it.com/jira/browse/SDKCF-619): Check object is valid before adding it to record array. Fixes crash observed in customer's Crashlytics report
* [SDKCF-612](https://jira.rakuten-it.com/jira/browse/SDKCF-612): Add README section about tracking events from App Extension targets

@subsection analytics-3-1-0 3.1.0 (2018-06-25)
* [SDKCF-158](https://jira.rakuten-it.com/jira/browse/SDKCF-158): Make RAT endpoint configurable in plist
* [SDKCF-149](https://jira.rakuten-it.com/jira/browse/SDKCF-149): Make keychain sharing optional
* [SDKCF-68](https://jira.rakuten-it.com/jira/browse/SDKCF-68): Support multiple app targets using different subspecs
* [SDKCF-18](https://jira.rakuten-it.com/jira/browse/SDKCF-18): Add type validation for acc and aid values
* [SDKCF-99](https://jira.rakuten-it.com/jira/browse/SDKCF-99): Fixed bug where "online":false status is shown in payload for some RAT events on iOS 8

@subsection analytics-3-0-0 3.0.0 (2018-04-13)
* [REM-25315](https://jira.rakuten-it.com/jira/browse/REM-25315): Read RAT Account ID and Application ID from app's info.plist.
* [REM-25524](https://jira.rakuten-it.com/jira/browse/REM-25524) / [REM-25547](https://jira.rakuten-it.com/jira/browse/REM-25547): Add Swift sample app and update Objective-C sample app to match latest analytics module API.
* [REM-25864](https://jira.rakuten-it.com/jira/browse/REM-25864): Redesign module and separate functionality into `Core` and `RAT` CocoaPods subspecs.
* [REM-25317](https://jira.rakuten-it.com/jira/browse/REM-25317): Add SDK @ref RAnalyticsTracker "Tracker" to track build information and non-Apple frameworks usage.

@subsection analytics-2-13-0 2.13.0 (2018-01-11)
* [REM-24194](https://jira.rakuten-it.com/jira/browse/REM-24194): Add support for App Extensions.
* [REM-24746](https://jira.rakuten-it.com/jira/browse/REM-24746): Send Rp cookie to RAT.

@subsection analytics-2-12-0 2.12.0 (2017-11-13)
* [REM-24171](https://jira.rakuten-it.com/jira/browse/REM-24171): Disable debug log for Analytics module.

@subsection analytics-2-11-0 2.11.0 (2017-10-10)
* [REM-23653](https://jira.rakuten-it.com/jira/browse/REM-23653): Track Shared Web Credentials usage.

@subsection analytics-2-10-1 2.10.1 (2017-09-06)
* [REM-21934](https://jira.rakuten-it.com/jira/browse/REM-21934): Fixed duplicate `_rem_push_notify` event sent to RAT.

@subsection analytics-2-10-0 2.10.0 (2017-06-21)
* [REM-21497](https://jira.rakuten-it.com/jira/browse/REM-21497): Added RATTracker::configureWithDeliveryStrategy: API so that applications can configure the batching delay for sending events. The default batching delay is 60 seconds which is unchanged from previous module versions.

@subsection analytics-2-9-0 2.9.0 (2017-03-30)
* [REM-19145](https://jira.rakuten-it.com/jira/browse/REM-19145): Reduced the memory footprint of automatic page view tracking by half by not keeping a strong reference to the previous view controller anymore. This comes with a minor change: RSDKAnalyticsState::lastVisitedPage is now deprecated, and always `nil`.

@subsection analytics-2-8-2 2.8.2 (2017-02-06)
* [REM-18839](https://jira.rakuten-it.com/jira/browse/REM-18839): The `RSDKAnalyticsSessionStartEventName` "launch event" was not being triggered for most launches.
* [REM-18565](https://jira.rakuten-it.com/jira/browse/REM-18565): The `page_id` parameter was completely ignored by the @ref RATTracker "RAT tracker" when processing a `RSDKAnalyticsPageVisitEventName` "visit event".
* [REM-18384](https://jira.rakuten-it.com/jira/browse/REM-18384): The library was blocking calls to `-[UNNotificationCenterDelegate userNotificationCenter:willPresentNotification:withCompletionHandler]`, effectively disabling the proper handling of user notifications on iOS 10+ in apps that relied on the new `UserNotifications` framework.
* [REM-18438](https://jira.rakuten-it.com/jira/browse/REM-18438), [REM-18437](https://jira.rakuten-it.com/jira/browse/REM-18437) & [REM-18436](https://jira.rakuten-it.com/jira/browse/REM-18436): The library is now smarter as to what should trigger a `RSDKAnalyticsPageVisitEventName` "visit event".
    * Won't trigger the event anymore:
        * Common chromes: `UINavigationController`, `UISplitViewController`, `UIPageViewController` and `UITabBarController` view controllers.
        * System popups: `UIAlertView`, `UIActionSheet`, `UIAlertController` & `_UIPopoverView`.
        * Apple-private views, windows and view controllers.
        * Subclasses of `UIWindow` that are not provided by the app.
    * Furthermore, the @ref RATTracker "RAT tracker" additionally ignores view controllers that have no title, no navigation item title, and for which no URL was found on any webview part of their view hierarchy at the time `-viewDidLoad` was called, unless they have been subclassed by the application.
        * For view controllers with either a title, navigation item title or URL, the library now adds the `cp.title` and `cp.url` fields to the `pv` event sent to RAT.
* Fixed missing automatic import of the `UserNotifications` framework on iOS 10+.
* Fixed bogus imports in a few header files.

@subsection analytics-2-8-1 2.8.1 (2016-11-29)
* [REM-17889](https://jira.rakuten-it.com/jira/browse/REM-17889): Fixed potential security issue where full push notification message was sent to RAT.
* [REM-17890](https://jira.rakuten-it.com/jira/browse/REM-17890): Fixed missing event after a push notification while app is active.
* [REM-17927](https://jira.rakuten-it.com/jira/browse/REM-17927): Fixed missing `ref_type` attribute on `pv` RAT event after a push notification.

@subsection analytics-2-8-0 2.8.0 (2016-11-11)
* [REM-16656](https://jira.rakuten-it.com/jira/browse/REM-16656): Added collection and tracking of Discover events to Analytics module.
* [REM-14422](https://jira.rakuten-it.com/jira/browse/REM-14422): Added tracking of push notifications to standard event tracking.
* [REM-17621](https://jira.rakuten-it.com/jira/browse/REM-17621): Fixed initial launch events being fired twice.
* [REM-17862](https://jira.rakuten-it.com/jira/browse/REM-17862): Fixed issue where AppDelegate swizzling disabled deep linking.
* Added the missing endpointAddress property to RATTracker.
* Fixed issue where Easy ID was being sent even though user was logged out.
* Fixed the case where a device has no SIM and the carrier name always displayed the wrong carrier name, and the module sent that wrong name to the server.
* Fixed an incorrect debug message in Xcode console stating that no tracker processed a RAT event, when the RAT tracker did in fact process the event successfully.

@subsection analytics-2-7-1 2.7.1 (2016-10-11)
* [REM-17208](https://jira.rakuten-it.com/jira/browse/REM-17208): Fixed a crash happening for some Ichiba users when the RAT tracker cannot properly create its backing store because SQLite is in a corrupt state. Instead of a runtime assertion, we're now silently ignoring the error and disabling tracking through RAT for the session instead.
* [REM-16279](https://jira.rakuten-it.com/jira/browse/REM-16279) & [REM-16280](https://jira.rakuten-it.com/jira/browse/REM-16280) Add cp.sdk_info and cp.app_info parameters to _rem_install event.
* [REM-14062](https://jira.rakuten-it.com/jira/browse/REM-14062) Track _rem_visit event.

@subsection analytics-2-7-0 2.7.0 (2016-09-28)
* Major rewrite.
* Support for custom event trackers.
* Automatic KPI tracking from other parts of our SDK: login/logout, sessions, application lifecycles.
* Deprecated RSDKAnalyticsManager::spoolRecord:, RSDKAnalyticsItem and RSDKAnalyticsRecord.

@subsection analytics-2-6-0 2.6.0 (2016-07-27)
* Added the automatic tracking of the advertising identifier (IDFA) if not turned off explicitly by setting RSDKAnalyticsManager::shouldTrackAdvertisingIdentifier to `NO`. It is sent as the `cka` standard RAT parameter.
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
* Fixed Xcode 6 build.

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
* `SDK-2947` Fixed bugs and comply with new requirements.

@subsection analytics-2-3-4 2.3.4 (2015-04-01)
* `SDK-2901` Cocoapods 0.36 now requires `source`.

@subsection analytics-2-3-3 2.3.3 (2015-03-18)
* `SDK-2761` (sample app) Numeric fields accepted arbitrary text.
* `SDK-2729` Location was being sent to RAT even when tracking was disabled.

@subsection analytics-2-3-2 2.3.2 (2015-03-10)
* `SDK-2859` Handle device information exceptions.

@subsection analytics-2-3-1 2.3.1 (2015-03-08)
* Fixed sample build error.

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
* Fixed bugs on iOS 8

@subsection analytics-2-2-0 2.2.0 (2014-09-22)
* Added `RSDKAnalyticsItem`.
* The `ts1` RAT field is now expressed in seconds (previously in milliseconds).

@subsection analytics-2-1-0 2.1.0 (2014-06-24)
* Removed dependency on [FXReachability](https://github.com/nicklockwood/FXReachability)
* Added `RSDKAnalyticsRecord.easyId` property.

@subsection analytics-2-0-0 2.0.0 (2014-06-13)
* Major rewrite

@subsection analytics-1-0-0 1.0.0 (2013-08-15)
* Initial release

[idfa]: https://developer.apple.com/reference/adsupport/asidentifiermanager
