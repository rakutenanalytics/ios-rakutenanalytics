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

# Fetch all changes from origin and target
echo "Fetching changes from origin and target..."
git fetch origin --prune
git fetch target --prune

# Ensure we are on the specified branch
echo "Checking out branch $BRANCH..."
git checkout $BRANCH || { echo "Branch $BRANCH does not exist locally. Exiting."; exit 1; }

# Pull the latest changes from origin to ensure the local branch is up-to-date
echo "Pulling latest changes from origin/$BRANCH..."
git pull origin $BRANCH --rebase || { echo "Failed to pull changes from origin/$BRANCH. Exiting."; exit 1; }

# Push the changes to the target branch
echo "Pushing changes to target/$BRANCH..."
git push target $BRANCH --force-with-lease || { echo "Failed to push changes to target/$BRANCH. Exiting."; exit 1; }
echo "$BRANCH branch sync complete."

# Sync tags
echo "Syncing tags..."
git fetch --tags origin
git push --tags target --force-with-lease || { echo "Failed to sync tags. Exiting."; exit 1; }
echo "Tags sync complete."
