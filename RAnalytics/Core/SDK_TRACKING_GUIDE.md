# Analytics Core
The `RAnalytics/Core` module subspec provides basic analytics tracking infrastructure and includes SDK tracking capabilities. **This module is meant to be used by SDKs/libraries not applications**.

The SDK tracking is designed to not contain any data that can be linked to a user or device (in other words no PII), so it is out of scope for GDPR.

## Integration
To use the SDK tracking in your SDK/library add a dependency on `RAnalytics/Core` to your `Podfile`.

```ruby
source 'https://cdn.cocoapods.org/'
source 'https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git'

pod 'RAnalytics/Core'
```

## SDK tracking
The SDK will bootstrap automatically and send events to RAT to the account id `477` and app id `1`. The supported events are listed below:

### `_rem_internal_install`
Once per version the SDK will send this event containing:

* basic info about the app
* `cp.sdk_info`: info about SDKs integrated in the app
* `cp.app_info`: info about the runtime environment

To get your library/SDK listed in `cp.sdk_info` you need to add its bundle identifier as `key` and its display name as `value` to the [REMModulesMap plist file](https://gitpub.rakuten-it.com/projects/ECO/repos/core-ios-analytics/browse/RAnalytics/Core/Assets/REMModulesMap.plist#5-6) in the RAnalytics module and raise a Pull Request.

### Custom Events
To be implemented
