## Introduction
This Rakuten SDK module allows applications to record user activity and
automatically send reports to the Rakuten Analytics servers.

@attention RSDKAnalytics depends on the RSDKDeviceInformation module for
 retrieving the device's unique identifier, and that module requires keychain
 access to be properly configured. Please refer to @ref device-information-keychain-setup "Setting up the keychain"
 for the right way to do so.

@attention Without this, RSDKAnalyticsManager::spoolRecord: will raise a `NSObjectInaccessibleException`.


## Usage
### Configuration
No configuration is required to start recording user activity. However,
if the developer wants to record the device's location, location tracking has
to be enabled by setting RSDKAnalyticsManager::locationTrackingEnabled
to `YES`:

~~~{.m}
	RSDKAnalyticsManager *manager = RSDKAnalyticsManager.sharedInstance;
	manager.locationTrackingEnabled = YES;
~~~

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

### Recording activity
Records are created with RSDKAnalyticsRecord::recordWithAccountId:serviceId:
and spooled by calling RSDKAnalyticsManager::spoolRecord:.

The properties of RSDKAnalyticsRecord closely match the fields described in the
[Rakuten Analytics Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
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
[Services and accounts](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/aid_acc_Map.json)
JSON file.

@note Please see @ref analytics-register to learn how to register new applications.

### Monitoring network activity
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

@page analytics-register Registering a new application

### Quick links

* [Registration Form](https://confluence.rakuten-it.com/confluence/display/GEAP/01_RAT+New+Use+Application) (internal)
* Support email for administrative tasks: dev-rat@mail.rakuten.com

