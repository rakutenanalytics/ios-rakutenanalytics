#!/bin/bash
set -ex

# This script uploads a snapshot to:
# https://github.com/rakutentech/ios-analytics-framework-snapshots

# Get the framework version
FRAMEWORK_NAME=RAnalytics
PODSPEC_FILE_PATH="$FRAMEWORK_NAME.podspec"
FRAMEWORK_VERSION=$(grep "s.version      =" $PODSPEC_FILE_PATH | sed "s/  s.version      = \"//;s/.$//" | tr -d [:space:])

# Get the last snapshot tag
git clone https://$SNAPSHOT_GITHUB_TOKEN@github.com/rakutentech/ios-analytics-framework-snapshots.git
cd ios-analytics-framework-snapshots
LAST_TAG=$(git describe --tags --abbrev=0)
cd ..

# Try to increment the version number
VERSION_NUMBER=1
if [[ $LAST_TAG == *"$FRAMEWORK_VERSION"* ]]; then
  TAG_NUMBER=$(echo $LAST_TAG | sed -n -e "s/^.*snapshot-//p")
  VERSION_NUMBER=$(($TAG_NUMBER + 1))
fi

# Upload the snapshot
git fetch origin
git checkout upload-snapshot
git rebase master
bundle install
bundle exec fastlane ios commit_sdk_ver_bump version:$FRAMEWORK_VERSION-$VERSION_NUMBER

if ! bundle exec fastlane ios deploy_framework version:$FRAMEWORK_VERSION-$VERSION_NUMBER; then
    echo "deploy_framework returned an error"
fi
