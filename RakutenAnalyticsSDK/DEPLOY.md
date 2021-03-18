# Deploy Analytics Framework

Framework builds are deployed using the Fastlane lane `deploy_framework`. 

Parameters that can be passed into the lane are:

* `version` (string, mandatory) e.g. `bundle exec fastlane ios deploy_framework version:"1.0.0"`
* `release` (boolean, defaults false) - sets whether to deploy snapshot (false) or proper release (true)
* `skip_build` (boolean, optional, default: false)
* `skip_upload` (boolean, optional, default: false)
* `skip_pod_push` (boolean, optional, default: false)

## Deploy Snapshot

1. To deploy a **snapshot** you must set the environment variable `SNAPSHOT_GITHUB_TOKEN` - this value can be found on the internal accounts [page](https://confluence.rakuten-it.com/confluence/display/MTSD/Internal+accounts+for+SDK+Team) under "Github CI Publishing Account".
1. From a clean checkout, update the public framework podspec `RakutenAnalyticsSDK/RAnalytics.podspec` `version` attribute e.g. set `version` to `8.0.0-snapshot-1`
1. Update the public framework podspec `source` attribute to point at the `ios-analytics-framework-snapshot` repo
1. Run `bundle exec fastlane ios deploy_framework version:"{snapshot-version}"`
1. Revert to clean state. Do not commit the changes.

* The `deploy_framework` fastlane lane in **snapshot** mode:
    1. Confirms the version parameter matches the podspec
    1. Builds the fat binary arm64 and x86_64 frameworks using xcodebuild
    1. Uploads all the build artifacts (zipped frameworks, debug symbols) as a github release to https://github.com/rakutentech/ios-analytics-framework-snapshots/releases

## Deploy Release

1. To deploy a **release** you must set the environment variables `RELEASE_GITHUB_TOKEN` and `RELEASE_GHE_TOKEN`. These token values can be found on the internal accounts [page](https://confluence.rakuten-it.com/confluence/display/MTSD/Internal+accounts+for+SDK+Team).
1. Make a PR to update the public framework podspec `RakutenAnalyticsSDK/RAnalytics.podspec` `version` e.g. set `version` to `8.0.0` and get it merged.
1. Execute the release from the latest commit that includes the podspec version update
    * For automated release, run the [Jenkins release job](http://jenkins-mtsd.rakuten-it.com/job/sdk/job/public-analytics/) by setting the version and branch build parameters
    * For manual release, run `bundle exec fastlane ios deploy_framework release:true version:"{release-version}"`

* The `deploy_framework` fastlane lane in **release** (i.e. with snapshot:false parameter set) mode:
    1. Confirms the version parameter matches the podspec
    1. Builds the fat binary arm64 and x86_64 frameworks using xcodebuild
    1. Uploads all the build artifacts (zipped frameworks, debug symbols) to an internal private repo as a github release https://ghe.rakuten-it.com/ssed/ios-analytics-private-artifacts/releases
    1. Uploads the zipped release framework as a github release to https://github.com/rakutentech/ios-analytics-framework/releases/
    1. Runs pod lib lint and pushes the podspec to spec repo