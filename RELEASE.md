# RAnalytics iOS SDK

1. [Release Workflow](#release-workflow)
1. [Repositories](#repositories)

# Release Workflow

## Description

The release workflow of the RAnalytics SDK is defined by `release.yml` here:<br>
https://github.com/rakuten-mag/ios-analytics/blob/master/.github/workflows/release.yml

## How to create self-hosted runner

https://github.com/rakuten-mag/ios-analytics/settings/actions/runners/new

## Pre-requisites

- Confirm that QA build from appcenter was built from correct RAnalytics commit:
    - https://github.com/rakuten-mag/ios-analytics/commit/{commit-hash}
- All code has been merged and tested
- Confirm intended new release version tag is consistent with the public API changes since previous release:
    - Use the sdk-api-diff tool or git diff
- Create release branch then create PR to update:
    - READMEs
    - CHANGELOG (pending release notes for this version should go under the "## Unreleased" header)

## Operations

- Open this URL in a browser:
    - https://github.com/rakuten-mag/ios-analytics
- Click on the Actions tab
- Click on Release Module
- Click on Run workflow
- Select the release branch (example: release/9.6.0)
- Enter the corresponding version number (example: 9.6.0)

## Post Operations

- Confirm that the Release workflow passed:
    - https://github.com/rakuten-mag/ios-analytics/actions/workflows/release.yml

- Public release-mode framework zip is uploaded to public repo as release:
    - https://github.com/rakutentech/ios-analytics-framework

- Package.swift is updated on public repo:
    - https://github.com/rakutentech/ios-analytics-framework/blob/master/Package.swift

- Podspec is updated on public repo:
    - https://github.com/rakutentech/ios-analytics-framework/blob/master/RAnalytics/{tag}/RAnalytics.podspec

- Release tag was created on correct commit in public repo:
    - https://github.com/rakutentech/ios-analytics-framework/commits/{tag}

- Private artifacts (release & debug framework zips, release & debug dSYM zips) are uploaded to GHE internal repo as release:
    - https://ghe.rakuten-it.com/mag/ios-analytics-private-artifacts/releases/tag/{tag}

- Release tag is created on correct commit in private repo
    - https://github.com/rakuten-mag/ios-analytics/commits/{tag}

- Podspec and commit message are in core-ios-specs repo:
    - Staging:
        - https://gitpub.rakuten-it.com/projects/eco/repos/stg-core-ios-specs/browse/Specs/RAnalytics/{tag}/RAnalytics.podspec
        - https://gitpub.rakuten-it.com/projects/ECO/repos/stg-core-ios-specs/commits
    - Production:
        - https://gitpub.rakuten-it.com/projects/ECO/repos/core-ios-specs/browse/Specs/RAnalytics/{tag}/RAnalytics.podspec
        - https://gitpub.rakuten-it.com/projects/ECO/repos/core-ios-specs/commits

- Confirm docs for this version have been published to:
    - https://pages.ghe.rakuten-it.com/mag/ios-analytics-docs

- If release branch was used, merge to master - use merge-commit (do not squash) and **DO NOT DELETE THE RELEASE BRANCH**

- Confirm tag/branch mirrored back to gitpub:
    - https://gitpub.rakuten-it.com/projects/ECO/repos/core-ios-analytics/browse?at=refs%2Ftags%2F{tag}
    - https://gitpub.rakuten-it.com/projects/ECO/repos/core-ios-analytics/browse?at=refs%2Fheads%2Frelease%2F{tag}

- Confirm pod spec lint passes (will need to update repo first):
```
bundle exec pod spec lint --allow-warnings --sources=https://gitpub.rakuten-it.com/scm/eco/core-ios-specs.git,https://cdn.cocoapods.org/
```

- Confirm that pod install / build / running of sample app succeeds after:
    - executing `pod repo update`
    - setting the sample app Podfile RAnalytics dependency to the released GitHub version (pod 'RAnalytics', '9.6.0'):
        - https://github.com/rakuten-mag/ios-analytics/tree/master/Samples/RAnalyticsSample

- Confirm that build / running of SamplesSPM app succeeds after setting the Swift package dependency to the released github version:
    - Set the public framework in the Swift Package Manager section and set the exact version: https://github.com/rakutentech/ios-analytics-framework

- Inform any waiting customers that the release is available

- Post to discourse
    - Example: https://discourse.tech.rakuten-it.com/t/ios-analytics-v9-6-0-released/7383

# Repositories

This is the complete list of all the repositories used for the release of the RAnalytics SDK:

## Development repository

This repository is only used by developers to add features, improvements or fixes to the RAnalytics SDK:<br>
https://github.com/rakuten-mag/ios-analytics

## Mirror repository

This repository is a mirror of the Development repository and is used by Rakuten customers in theirs apps:<br>
https://gitpub.rakuten-it.com/projects/ECO/repos/core-ios-analytics/pull-requests

## Public repository of the RAnalytics Xcode Framework

This repository contains the public RAnalytics Xcode Framework and is available for any external customers:<br>
https://github.com/rakutentech/ios-analytics-framework

## Artifacts repository of the RAnalytics Xcode Framework

This is the storage of private artifacts from the public repository (https://github.com/rakutentech/ios-analytics-framework) build process:<br>
https://ghe.rakuten-it.com/mag/ios-analytics-private-artifacts

## Private snapshots repository of the RAnalytics Xcode Framework

This repository is only used fot testing the RAnalytics Xcode Framework in internal apps by QA:<br>
https://github.com/rakutentech/ios-analytics-framework-snapshots

## Documentation repository

This is the repository containing the documentation of RAnalytics for each released version:<br>
https://pages.ghe.rakuten-it.com/mag/ios-analytics-docs/9.6.0/index.html

## Codelab repository

- This is the repository containing the RAnalytics Codelab:
    - https://ghe.rakuten-it.com/mag/docs-codelabs

- The Codelab homepage is published here:
    - https://pages.ghe.rakuten-it.com/mag/docs-codelabs/
