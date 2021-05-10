#!/bin/sh
set -e

# clean previous builds
rm -rf build

# create folder where we place built frameworks
mkdir build

BUILD_DEBUG_SIMULATOR=build/debug/simulator
BUILD_DEBUG_DEVICE=build/debug/devices
BUILD_DEBUG_UNIVERSAL=build/debug/universal

BUILD_RELEASE_SIMULATOR=build/release/simulator
BUILD_RELEASE_DEVICE=build/release/devices
BUILD_RELEASE_UNIVERSAL=build/release/universal

mkdir build/debug
mkdir build/release

FRAMEWORK_NAME="RAnalytics"
FRAMEWORK_DSYM="RAnalytics.framework.dSYM"

frameworkBinaryPath="RAnalytics.framework/RAnalytics"
dSymFilePath="$FRAMEWORK_DSYM/Contents/Resources/DWARF/RAnalytics"

RAKUTEN_ANALYTICS_SDK_PROJECT_PATH="RAnalytics.xcodeproj/project.pbxproj"

PODSPEC_FILE_PATH="RAnalytics.podspec"

# install RakutenAnalyticsSDK workspace and pods
bundle install
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

###
### 1. build DEBUG framework for simulators - x86_64
###
xcodebuild BUILD_LIBRARY_FOR_DISTRIBUTION=YES -UseModernBuildSystem=YES BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" clean build -workspace RakutenAnalyticsSDK.xcworkspace -scheme RAnalytics-Framework -configuration Debug -sdk iphonesimulator -arch x86_64

# create folder to store compiled framework for simulator - Debug
mkdir $BUILD_DEBUG_SIMULATOR

# get derived data path
DERIVED_DATA_SIMULATOR=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -configuration Debug -showBuildSettings -sdk iphonesimulator | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

# copy compiled framework for DEBUG simulator into our build folder
cp -r $DERIVED_DATA_SIMULATOR/RAnalytics.framework $BUILD_DEBUG_SIMULATOR
cp -r $DERIVED_DATA_SIMULATOR/$FRAMEWORK_DSYM $BUILD_DEBUG_SIMULATOR


### 2. build RELEASE framework for simulators
xcodebuild BUILD_LIBRARY_FOR_DISTRIBUTION=YES -UseModernBuildSystem=YES BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" clean build -workspace RakutenAnalyticsSDK.xcworkspace -scheme RAnalytics-Framework -configuration Release -sdk iphonesimulator -arch x86_64

# create folder to store compiled framework for simulator - Release
mkdir $BUILD_RELEASE_SIMULATOR

# get derived data path
DERIVED_DATA_SIMULATOR=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -configuration Release -showBuildSettings -sdk iphonesimulator | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

# copy compiled framework for RELEASE simulator into our build folder
cp -r $DERIVED_DATA_SIMULATOR/RAnalytics.framework $BUILD_RELEASE_SIMULATOR
cp -r $DERIVED_DATA_SIMULATOR/$FRAMEWORK_DSYM $BUILD_RELEASE_SIMULATOR


###
### 3. build DEBUG framework for devices
###
xcodebuild BUILD_LIBRARY_FOR_DISTRIBUTION=YES -UseModernBuildSystem=YES BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" clean build -workspace RakutenAnalyticsSDK.xcworkspace -scheme RAnalytics-Framework -configuration Debug -sdk iphoneos -arch arm64

# create folder to store compiled framework for device - Debug
mkdir $BUILD_DEBUG_DEVICE

# get derived data path
DERIVED_DATA_DEVICE=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -configuration Debug -showBuildSettings -sdk iphoneos | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

# copy compiled framework for devices into our build folder - Debug
cp -r $DERIVED_DATA_DEVICE/RAnalytics.framework $BUILD_DEBUG_DEVICE
cp -r $DERIVED_DATA_DEVICE/$FRAMEWORK_DSYM $BUILD_DEBUG_DEVICE


###
### 4. build RELEASE framework for devices
###
xcodebuild BUILD_LIBRARY_FOR_DISTRIBUTION=YES -UseModernBuildSystem=YES BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" clean build -workspace RakutenAnalyticsSDK.xcworkspace -scheme RAnalytics-Framework -configuration Release -sdk iphoneos -arch arm64
  
# create folder to store compiled framework for device - Release
mkdir $BUILD_RELEASE_DEVICE

# get derived data path
DERIVED_DATA_DEVICE=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -configuration Release -showBuildSettings -sdk iphoneos | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

# copy compiled framework for devices into our build folder - Release
cp -r $DERIVED_DATA_DEVICE/RAnalytics.framework $BUILD_RELEASE_DEVICE
cp -r $DERIVED_DATA_DEVICE/$FRAMEWORK_DSYM $BUILD_RELEASE_DEVICE

# create folders to store compiled universal framework for Debug and Release configurations
mkdir $BUILD_DEBUG_UNIVERSAL
mkdir $BUILD_RELEASE_UNIVERSAL


####################### Create universal framework #############################
# copy device framework into universal folder
cp -r $BUILD_DEBUG_DEVICE/RAnalytics.framework $BUILD_DEBUG_UNIVERSAL
cp -r $BUILD_RELEASE_DEVICE/RAnalytics.framework $BUILD_RELEASE_UNIVERSAL

cp -r $BUILD_DEBUG_DEVICE/$FRAMEWORK_DSYM $BUILD_DEBUG_UNIVERSAL
cp -r $BUILD_RELEASE_DEVICE/$FRAMEWORK_DSYM $BUILD_RELEASE_UNIVERSAL

UUIDs=$(dwarfdump --uuid "$BUILD_RELEASE_DEVICE/$FRAMEWORK_DSYM" | cut -d ' ' -f2)
echo "dwarfdump UUIDs: $UUIDs"

# find and copy bitcode symbols
# see https://instabug.com/blog/ios-binary-framework/
for file in `find "$DERIVED_DATA_DEVICE" -name "*.bcsymbolmap" -type f`; do
    fileName=$(basename "$file" ".bcsymbolmap")
    for UUID in $UUIDs; do
        if [[ "$UUID" = "$fileName" ]]; then
            cp -R "$file" "$BUILD_RELEASE_DEVICE"

            # Updates the dSYM inplace using bitcode symbol map
            # see "Restore Hidden Symbols" https://developer.apple.com/documentation/xcode/diagnosing_issues_using_crash_reports_and_device_logs/adding_identifiable_symbol_names_to_a_crash_report
            dsymutil --symbol-map "$BUILD_RELEASE_DEVICE"/"$fileName".bcsymbolmap "$BUILD_RELEASE_DEVICE/$FRAMEWORK_DSYM"
            echo "Mapped bitcode symbols from ${fileName} to $FRAMEWORK_DSYM"
        fi
    done
done 

# create framework binary compatible with simulators and devices, and replace binary in universal framework
lipo -create \
$BUILD_DEBUG_SIMULATOR/$frameworkBinaryPath \
$BUILD_DEBUG_DEVICE/$frameworkBinaryPath \
-output $BUILD_DEBUG_UNIVERSAL/$frameworkBinaryPath

lipo -create \
  $BUILD_RELEASE_SIMULATOR/$frameworkBinaryPath \
  $BUILD_RELEASE_DEVICE/$frameworkBinaryPath \
  -output $BUILD_RELEASE_UNIVERSAL/$frameworkBinaryPath

# create universal dSYM for debug and release
lipo -create \
    $BUILD_DEBUG_SIMULATOR/$dSymFilePath \
    $BUILD_DEBUG_DEVICE/$dSymFilePath \
    -output $BUILD_DEBUG_UNIVERSAL/$dSymFilePath

lipo -create \
    $BUILD_RELEASE_SIMULATOR/$dSymFilePath \
    $BUILD_RELEASE_DEVICE/$dSymFilePath \
    -output $BUILD_RELEASE_UNIVERSAL/$dSymFilePath   

# copy simulator Swift public interface to universal framework
cp -r $BUILD_DEBUG_SIMULATOR/$FRAMEWORK_NAME.framework/Modules/$FRAMEWORK_NAME.swiftmodule/* $BUILD_DEBUG_UNIVERSAL/$FRAMEWORK_NAME.framework/Modules/$FRAMEWORK_NAME.swiftmodule
cp -r $BUILD_RELEASE_SIMULATOR/$FRAMEWORK_NAME.framework/Modules/$FRAMEWORK_NAME.swiftmodule/* $BUILD_RELEASE_UNIVERSAL/$FRAMEWORK_NAME.framework/Modules/$FRAMEWORK_NAME.swiftmodule

cp -r $BUILD_DEBUG_SIMULATOR/$FRAMEWORK_NAME.framework/Modules/$FRAMEWORK_NAME.swiftmodule/Project/* $BUILD_DEBUG_UNIVERSAL/$FRAMEWORK_NAME.framework/Modules/$FRAMEWORK_NAME.swiftmodule/Project
cp -r $BUILD_RELEASE_SIMULATOR/$FRAMEWORK_NAME.framework/Modules/$FRAMEWORK_NAME.swiftmodule/Project/* $BUILD_RELEASE_UNIVERSAL/$FRAMEWORK_NAME.framework/Modules/$FRAMEWORK_NAME.swiftmodule/Project

# check architectures
echo "Framework - Debug mode:"
file $BUILD_DEBUG_UNIVERSAL/$frameworkBinaryPath
echo "Framework - Release mode:"
file $BUILD_RELEASE_UNIVERSAL/$frameworkBinaryPath
echo "dSym - Debug mode:"
file $BUILD_DEBUG_UNIVERSAL/$dSymFilePath
echo "dSym - Release mode:"
file $BUILD_RELEASE_UNIVERSAL/$dSymFilePath

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

for item in ${allArchitectures[*]}
do
    echo "Framework - Debug mode - architecture $item:"
    bitcode $item $BUILD_DEBUG_UNIVERSAL/$frameworkBinaryPath

    echo "Framework - Release mode - architecture $item:"
    bitcode $item $BUILD_RELEASE_UNIVERSAL/$frameworkBinaryPath
done
