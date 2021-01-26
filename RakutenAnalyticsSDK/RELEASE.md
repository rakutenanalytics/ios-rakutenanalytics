### Release Steps for Public Framework

1. Make a PR to update the public framework podspec `RakutenAnalyticsSDK/RAnalytics.podspec`:
    * Set `version` to release x.y.z semantic version
    * Set `source` to the to-be-released framework zip download url (this can be predicted based on version e.g. v8.0.0 will be at https://github.com/rakutentech/ios-analytics-public-framework/releases/download/8.0.0/RAnalyticsRelease-v8.0.0.zip)
1. Execute the release
    * For automated release, run the [Jenkins release job](http://jenkins-mtsd.rakuten-it.com/job/sdk/job/public-analytics/) by setting the version and branch build parameters
    * For manual release, run `bundle exec fastane ios release_framework version:"{release-version}"`

### release_framework fastlane lane

* Options that can be passed into `release_framework` lane are
    * `version` (string, mandatory) e.g. `bundle exec fastane ios release_framework version:"1.0.0"`
    * `testing` (boolean, optional, default: false) e.g. `bundle exec fastane ios release_framework version:"1.0.0" testing:true`. Setting testing to true will skip artifact upload and skip pushing podspec. 
    * `skip_artifact_upload` (boolean, optional, default: false) e.g. `bundle exec fastane ios release_framework version:"1.0.0" skip_artifact_upload:true`
    * `skip_pod_push` (boolean, optional, default: false) e.g. `bundle exec fastane ios release_framework version:"1.0.0" skip_pod_push:true`
* The `release_framework` fastlane lane
    1. Confirms the version parameter matches the podspec
    1. Builds the fat binary arm64 and x86_64 frameworks using xcodebuild
    1. Uploads all the build artifacts (libraries, debug symbols) to an internal private repo as a github release https://ghe.rakuten-it.com/ssed/ios-analytics-private-artifacts/releases
    1. Uploads the release framework as a github release to https://github.com/rakutentech/ios-analytics-public-framework/releases/
    1. Runs pod lib lint and pushes the podspec to CocoaPods trunk spec repo