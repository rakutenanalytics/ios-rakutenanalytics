#!/bin/sh
set -e

FRAMEWORK_NAME=RAnalytics
FRAMEWORK_DSYM=RAnalytics.framework.dSYM
SIMULATOR_ARCHIVE_FOLDER=simulator.xcarchive
DEVICE_ARCHIVE_FOLDER=device.xcarchive
OUTPUT_FOLDER=output

RAKUTEN_ANALYTICS_SDK_PROJECT_PATH="RAnalytics.xcodeproj/project.pbxproj"
PODSPEC_FILE_PATH="$FRAMEWORK_NAME.podspec"

dSymDWARFFilePath="$FRAMEWORK_DSYM/Contents/Resources/DWARF/$FRAMEWORK_NAME"
frameworkBinaryPath="$FRAMEWORK_NAME.xcframework/ios-arm64/$FRAMEWORK_NAME.framework/RAnalytics"

# clean previous builds
rm -rf $SIMULATOR_ARCHIVE_FOLDER
rm -rf $DEVICE_ARCHIVE_FOLDER
rm -rf $OUTPUT_FOLDER/Debug
rm -rf $OUTPUT_FOLDER/Release

# create folder where we place built frameworks
mkdir $SIMULATOR_ARCHIVE_FOLDER
mkdir $DEVICE_ARCHIVE_FOLDER

# install RakutenAnalyticsSDK workspace and pods
bundle install
bundle exec pod deintegrate
bundle exec pod install

RANALYTICS_FRAMEWORK_VERSION=$(grep "s.version      =" $PODSPEC_FILE_PATH | sed "s/  s.version      = \"//;s/.$//" | tr -d [:space:])

# update the project file with the new version number
sed -i '' -E "s/MARKETING_VERSION = [0-9]+.[0-9]+.[0-9]+/MARKETING_VERSION = $RANALYTICS_FRAMEWORK_VERSION/g" $RAKUTEN_ANALYTICS_SDK_PROJECT_PATH

# check if the new version number is updated
# see agv marketing version ref QA1827: https://developer.apple.com/library/archive/qa/qa1827/_index.html
PROJECT_VERSION_NUMBER=$(xcrun agvtool what-marketing-version -terse1)

if [ "$RANALYTICS_FRAMEWORK_VERSION" = "$PROJECT_VERSION_NUMBER" ]; then
    echo "SUCCESS: the project version number is updated to $RANALYTICS_FRAMEWORK_VERSION"
else
    echo "ERROR: the project version number $PROJECT_VERSION_NUMBER is not updated to $RANALYTICS_FRAMEWORK_VERSION"
    exit 1
fi

# clean derived data
xcodebuild clean -workspace RakutenAnalyticsSDK.xcworkspace -scheme $FRAMEWORK_NAME-Framework

shemes=("Debug" "Release")
for scheme in ${shemes[@]}; do

    # build simulator framework
    xcodebuild archive \
        -workspace RakutenAnalyticsSDK.xcworkspace \
        -scheme $FRAMEWORK_NAME-Framework \
        -sdk iphonesimulator \
        -configuration $scheme SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" BITCODE_GENERATION_MODE=bitcode \
        -archivePath $SIMULATOR_ARCHIVE_FOLDER | xcpretty

    # build device framework
    xcodebuild archive \
        -workspace RakutenAnalyticsSDK.xcworkspace \
        -scheme $FRAMEWORK_NAME-Framework \
        -sdk iphoneos \
        -configuration $scheme SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" BITCODE_GENERATION_MODE=bitcode \
        -archivePath $DEVICE_ARCHIVE_FOLDER | xcpretty

    # create xcframework
    xcodebuild -create-xcframework \
        -framework $SIMULATOR_ARCHIVE_FOLDER/Products/Library/Frameworks/$FRAMEWORK_NAME.framework \
        -framework $DEVICE_ARCHIVE_FOLDER/Products/Library/Frameworks/$FRAMEWORK_NAME.framework \
        -output $OUTPUT_FOLDER/$scheme/$FRAMEWORK_NAME.xcframework

    UUIDs=$(dwarfdump --uuid "$DEVICE_ARCHIVE_FOLDER/dSYMs/$FRAMEWORK_DSYM" | cut -d ' ' -f2)
    echo "dwarfdump UUIDs: $UUIDs"

    outputDSYM=$OUTPUT_FOLDER/$scheme/$FRAMEWORK_NAME.framework.dSYM
    cp -r "$DEVICE_ARCHIVE_FOLDER/dSYMs/$FRAMEWORK_DSYM" $outputDSYM

    # find and copy bitcode symbols
    # see https://instabug.com/blog/ios-binary-framework/
    # (we don't want to distribute xcframework with embedded dSYMs and bitcode symbols using `-debug-symbols` parameter)
    for file in `find "$DEVICE_ARCHIVE_FOLDER/Products/Library/Frameworks" -name "*.bcsymbolmap" -type f`; do
        fileName=$(basename "$file" ".bcsymbolmap")
        for UUID in $UUIDs; do
            if [[ "$UUID" = "$fileName" ]]; then
                cp "$file" "$outputDSYM"

                # Updates the dSYM inplace using bitcode symbol map
                # see "Restore Hidden Symbols" https://developer.apple.com/documentation/xcode/diagnosing_issues_using_crash_reports_and_device_logs/adding_identifiable_symbol_names_to_a_crash_report
                dsymutil --symbol-map $file $outputDSYM
                echo "Mapped bitcode symbols from ${fileName} to $FRAMEWORK_DSYM"
            fi
        done
    done
done

# check bitcode for each mobile architecture
allArchitectures=("arm64")

bitcode()
{
    otoolResult=$(otool -arch $1 -l $2 | grep __LLVM)
    size=${#otoolResult}
    if (( $size > 0 )); then
        echo "Has bitcode"
    else
        echo "Doesn't have bitcode"
        exit 1
    fi
}

for item in ${allArchitectures[@]}; do
    for scheme in ${shemes[@]}; do
        echo "Framework - $scheme mode - architecture $item:"
        bitcode $item $OUTPUT_FOLDER/$scheme/$frameworkBinaryPath
    done
done
