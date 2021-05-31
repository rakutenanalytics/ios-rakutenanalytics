#!/bin/bash
set -e

JAZZY=`VISUAL=echo gem open jazzy`
if [ -z "$JAZZY" ]
then
  echo "ERROR: Jazzy binary not found"
  exit 1
fi

SOURCEKITTEN="${JAZZY}/bin/sourcekitten"

echo "📄 Installing Pods"
bundle install && bundle exec pod install

echo "📄 Generating Swift docs"
$SOURCEKITTEN doc --module-name RAnalytics -- clean build-for-testing -workspace CI.xcworkspace -scheme Tests -destination 'platform=iOS Simulator,name=iPhone 8' > swiftDoc.json

echo "📄 Generating Objective-C docs"
mkdir ./docs-tmp
find RAnalytics \( -name "*.h" -or -name "*.m" \) -exec cp {} ./docs-tmp \;
mv ./docs-tmp ./RAnalytics/RAnalytics
$SOURCEKITTEN doc --objc ./RAnalytics/RAnalytics/RAnalytics.h -- -x objective-c  -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -I ./RAnalytics -fmodules > objcDoc.json

echo "📄 Merging"
jazzy --sourcekitten-sourcefile swiftDoc.json,objcDoc.json

echo "📄 Copying images"
cp -r ./doc ./docs/doc 

echo "📄 Cleaning up"
rm -rf ./RAnalytics/RAnalytics
rm objcDoc.json
rm swiftDoc.json
echo "📄 Done"
