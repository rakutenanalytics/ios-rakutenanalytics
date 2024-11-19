#!/bin/bash

# Predefined target repository URL
TARGET_REPO="git@ghe.rakuten-it.com:rakutenanalytics/ios-analytics.git"

# Get the branch to mirror, default to 'main' if not provided
BRANCH=${1:-main}

# Check if the target remote is already set
target=$(git remote -v | grep "target")
if [ -z "$target" ]; then
    echo "Setting target repo URL to $TARGET_REPO"
    git remote add target $TARGET_REPO
else
    echo "Target repo URL is already set."
fi

# Fetch changes from origin and target
git fetch origin
git fetch target

# Ensure we are on the specified branch
git checkout $BRANCH

# Reset the local branch to match the origin branch
git reset --hard origin/$BRANCH

# Push the changes to the target branch
git push target $BRANCH --force-with-lease
echo "$BRANCH branch sync complete"

# Sync tags
git fetch --tags target
git push --tags target --force-with-lease
echo "tags sync complete"