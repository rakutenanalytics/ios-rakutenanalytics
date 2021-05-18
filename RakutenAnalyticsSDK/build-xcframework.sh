#!/bin/sh
set -e

FRAMEWORK_NAME=RAnalytics
FRAMEWORK_DSYM=RAnalytics.framework.dSYM
BUILD_FOLDER=build
OUTPUT_FOLDER=output

RAKUTEN_ANALYTICS_SDK_PROJECT_PATH="RAnalytics.xcodeproj/project.pbxproj"
PODSPEC_FILE_PATH="$FRAMEWORK_NAME.podspec"

dSymDWARFFilePath="$FRAMEWORK_DSYM/Contents/Resources/DWARF/$FRAMEWORK_NAME"
frameworkBinaryPath="$FRAMEWORK_NAME.xcframework/ios-arm64/$FRAMEWORK_NAME.framework/RAnalytics"
currentDerivedDataPathSimulator=""
currentDerivedDataPathDevice=""

updateDerivedDataPathsWithScheme()
{
    currentDerivedDataPathSimulator="$BUILD_FOLDER/Build/Products/$1-iphonesimulator"
    currentDerivedDataPathDevice="$BUILD_FOLDER/Build/Products/$1-iphoneos"
}

# clean previous builds
rm -rf $BUILD_FOLDER
rm -rf $OUTPUT_FOLDER/Debug
rm -rf $OUTPUT_FOLDER/Release

# create folder where we place built frameworks
mkdir $BUILD_FOLDER

# install RakutenAnalyticsSDK workspace and pods
bundle install
bundle exec pod deintegrate
bundle exec pod install

RANALYTICS_FRAMEWORK_VERSION=$(grep "s.version      =" $PODSPEC_FILE_PATH | sed "s/  s.version      = \"//;s/.$//" | tr -d [:space:])

# update the project file with the new version number
sed -i '' -E "s/MARKETING_VERSION = [0-9]+.[0-9]+.[0-9]+/MARKETING_VERSION = $RANALYTICS_FRAMEWORK_VERSION/g" $RAKUTEN_ANALYTICS_SDK_PROJECT_PATH

# check if the new version number is updated
PROJECT_VERSION_NUMBER=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -showBuildSettings -sdk iphonesimulator | grep -m 1 "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //')

if [ "$RANALYTICS_FRAMEWORK_VERSION" = "$PROJECT_VERSION_NUMBER" ]; then
    echo "SUCCESS: the project version number is updated to $RANALYTICS_FRAMEWORK_VERSION"
else
    echo "ERROR: the project version number $PROJECT_VERSION_NUMBER is not updated to $RANALYTICS_FRAMEWORK_VERSION"
    exit 1
fi

# clean derived data
xcodebuild clean -workspace RakutenAnalyticsSDK.xcworkspace -scheme $FRAMEWORK_NAME-Framework -derivedDataPath $BUILD_FOLDER

shemes=("Debug" "Release")
for scheme in ${shemes[@]}; do

    updateDerivedDataPathsWithScheme $scheme

    # build simulator framework
    xcodebuild archive \
        -workspace RakutenAnalyticsSDK.xcworkspace \
        -scheme $FRAMEWORK_NAME-Framework \
        -destination="iOS Simulator" \
        -sdk iphonesimulator \
        -configuration $scheme SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" BITCODE_GENERATION_MODE=bitcode \
        -derivedDataPath $BUILD_FOLDER \
        build | xcpretty

    # build device framework
    xcodebuild archive \
        -workspace RakutenAnalyticsSDK.xcworkspace \
        -scheme $FRAMEWORK_NAME-Framework \
        -destination="iOS" \
        -sdk iphoneos \
        -configuration $scheme SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" BITCODE_GENERATION_MODE=bitcode \
        -derivedDataPath $BUILD_FOLDER \
        build | xcpretty

    # create xcframework
    xcodebuild -create-xcframework \
        -framework $currentDerivedDataPathSimulator/$FRAMEWORK_NAME.framework \
        -framework $currentDerivedDataPathDevice/$FRAMEWORK_NAME.framework \
        -output $OUTPUT_FOLDER/$scheme/$FRAMEWORK_NAME.xcframework

    UUIDs=$(dwarfdump --uuid "$currentDerivedDataPathDevice/$FRAMEWORK_DSYM" | cut -d ' ' -f2)
    echo "dwarfdump UUIDs: $UUIDs"

    outputDSYM=$OUTPUT_FOLDER/$scheme/$FRAMEWORK_NAME.framework.dSYM
    cp -r $currentDerivedDataPathDevice/$FRAMEWORK_DSYM $outputDSYM

    # find and copy bitcode symbols
    # see https://instabug.com/blog/ios-binary-framework/
    # (we don't want to distribute xcframework with embedded dSYMs and bitcode symbols using `-debug-symbols` parameter)
    for file in `find "$currentDerivedDataPathDevice" -name "*.bcsymbolmap" -type f`; do
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
