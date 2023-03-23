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
