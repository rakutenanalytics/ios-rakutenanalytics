#!/bin/sh
set -e

usage="Uploads content of RAnalytics.xcframework archive to the snapshot repository.
Arguments:
   - version: Required. Version of the framework that was archived.
   - token: Required. A Github personal access token.
   - target_branch: Optional. A branch to upload the framework to."

if [ -z ${1+x} ] || [ -z ${2+x} ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $usage"
    exit 1
fi

VERSION=$1
GITHUB_TOKEN=$2
TARGET_BRANCH=$3 || "master"
FRAMEWORK_ZIP_FILE=RAnalyticsRelease-v$1.zip
CLONED_REPO_PATH=ios-analytics-framework-snapshots

if [ ! -f $FRAMEWORK_ZIP_FILE ]; then
    echo "Cannot find framework archive $FRAMEWORK_ZIP_FILE"
    exit 1
fi

# delete current local repo if exists
rm -rf $CLONED_REPO_PATH

# clone snapshot repo
git clone "https://$GITHUB_TOKEN@github.com/rakutentech/ios-analytics-framework-snapshots.git"
git --git-dir=$CLONED_REPO_PATH/.git --work-tree=$CLONED_REPO_PATH/ checkout $TARGET_BRANCH

# delete old framework
rm -rf $CLONED_REPO_PATH/RAnalytics.xcframework

# add new framework
unzip $FRAMEWORK_ZIP_FILE -d $CLONED_REPO_PATH/
git --git-dir=$CLONED_REPO_PATH/.git --work-tree=$CLONED_REPO_PATH/ add .
git --git-dir=$CLONED_REPO_PATH/.git --work-tree=$CLONED_REPO_PATH/ commit --allow-empty -m "update RAnalytics.xcframework for version $1"

# push changes to repo
git --git-dir=$CLONED_REPO_PATH/.git --work-tree=$CLONED_REPO_PATH/ push origin $TARGET_BRANCH

# clean up
rm -rf $CLONED_REPO_PATH

echo "RAnalytics.xcframework version $VERSION pushed successfuly"
