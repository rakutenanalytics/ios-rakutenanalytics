## Introduction
This Rakuten SDK module allows applications to record user activity and
automatically send reports to the Rakuten Analytics servers.

 <div class="warning">**Important:** RSDKAnalytics depends on the **RSDKDeviceInformation**
module for retrieving the unique identifier for the device the application is running on.
RSDKDeviceInformation requires the `jp.co.rakuten.ios.sdk.deviceinformation` keychain
access group to be added to your application's **capabilities**, as shown below.

->![](docs/StaticDocs/KeychainSharingSettings.png)<-

Without this, RSDKAnalytics will still work but will not assign the `PERSISTENT_COOKIE` RAT
field with the device's unique identifier, when sending records to RAT servers.
</div>

## Usage
### Configuration
No configuration is required to start recording user activity. However,
if the developer wants to record the device's location, location tracking has
to be enabled by setting [RSDKAnalyticsManager locationTrackingEnabled]
to `YES`:

```
RSDKAnalyticsManager.sharedInstance.locationTrackingEnabled = YES;
```

 <div class="warning">**Warning:** Even with this property set to `YES`, the module will not track the device's location if your application is not also doing so, i.e. the application requested access to the device's location and the user granted it. Please refer to the [Location and Maps Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html)
for more information on how to request location updates.</div>

### Recording activity
Records are created with [RSDKAnalyticsRecord recordWithAccountId:serviceId:]
and spooled by calling [RSDKAnalyticsManager spoolRecord:].

The properties of RSDKAnalyticsRecord closely match the fields described in the
[Rakuten Analytics Generic IDL](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/ratGeneric.idl)
JSON file. There are a few exceptions, mainly due to their corresponding field's name
being too obscure, but each property's documentation mentions both the short and long
names of the field it eventually maps to.

 <div class="warning">For more information about each property, please read
the [RAT Specification](https://rakuten.atlassian.net/wiki/display/SDK/RAT+Specification).</div>

Calling [RSDKAnalyticsManager spoolRecord:] gathers extra values from the system
(such as the current time, information about the device the application is
running on and the type of network it is using to connect to the internet) and
returns immediately. The insertion into the local database and the upload of the
records to the Rakuten Analytics servers both happen on background queues.

```
// Create a new record
RSDKAnalyticsRecord *record = [RSDKAnalyticsRecord recordWithAccountId:123 serviceId:456];
record.itemId        = @[@"shopId/itemId1", @"shopId/itemId2"];
record.numberOfItems = @[               @3,                @2];
record.itemPrice     = @[          @158.75,               @10];
record.currencyCode  = @"USD";
// …and so on

// Spool it!
[RSDKAnalyticsManager spoolRecord:record];
```

For a list of valid `accountId` and `serviceId` values, please refer to the
[Services and accounts](https://git.dev.rakuten.com/projects/RG/repos/rg/browse/aid_acc_Map.json)
JSON file.

 <div class="warning">Developers with no access to the above file should request new account and
service identifiers by email, using the address <dev-rat@mail.rakuten.com>.
</div>

### Monitoring network activity
Developers who want to monitor the module's network activity can do so by listening
to the `RSDKAnalyticsWillUploadNotification`, `RSDKAnalyticsUploadFailureNotification`
and `RSDKAnalyticsUploadSuccessNotification` notifications.

