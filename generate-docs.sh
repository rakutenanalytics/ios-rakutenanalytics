#!/bin/bash
set -e

JAZZY=`VISUAL=echo gem open jazzy`
if [ -z "$JAZZY" ]
then
  echo 'ERROR: Jazzy binary not found. Add it to your Gemfile and run `bundle install`'
  exit 1
fi
if [ -z "$1" ] || [ -z "$2" ]
then
    echo "Missing arguments: You must pass module name and module version (ex. sh generate-docs.sh RAnalytics 10.0.0)"
fi

module_name=$1
module_version=$2

output_dir="./artifacts/docs"
# This directory is expected by `generate_docs` lane

echo "📄 Installing Pods"
bundle exec pod install --project-directory=./RakutenAnalyticsSDK

echo "📄 Running generate_docs lane with default script"
bundle exec fastlane generate_docs module_name:$module_name module_version:$module_version

echo "📄 Copying images"
cp -r ./doc "$output_dir/$module_version/doc"

echo "📄 Done"
