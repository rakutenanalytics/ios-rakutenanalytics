#!/bin/sh

# clean previous builds
rm -rf build

# create folder where we place built frameworks
mkdir build

BUILD_DEBUG_SIMULATOR=build/debug/simulator
BUILD_DEBUG_SIMULATOR_i386=build/debug/simulator_i386
BUILD_DEBUG_DEVICE=build/debug/devices
BUILD_DEBUG_UNIVERSAL=build/debug/universal

BUILD_RELEASE_SIMULATOR=build/release/simulator
BUILD_RELEASE_DEVICE=build/release/devices
BUILD_RELEASE_UNIVERSAL=build/release/universal

mkdir build/debug
mkdir build/release

frameworkBinaryPath="RAnalytics.framework/RAnalytics"
dSymFilePath="RAnalytics.framework.dSYM/Contents/Resources/DWARF/RAnalytics"

# install RakutenAnalyticsSDK workspace and pods
pod install

# get marketing version number
RANALYTICS_FRAMEWORK_VERSION=$(grep "s.version      =" ../RAnalytics.podspec | sed "s/  s.version      = \"//;s/.$//")
echo "Version number: $RANALYTICS_FRAMEWORK_VERSION"

###
### 1.1. build DEBUG framework for simulators - x86_64
###
### Note: xcodebuild doesn't build the i386 architecture for simulator with or without this option: ARCHS="i386 x86_64"
###
xcodebuild -UseModernBuildSystem=YES BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" clean build -workspace RakutenAnalyticsSDK.xcworkspace -scheme RAnalytics-Framework -configuration Debug -sdk iphonesimulator ARCHS="x86_64"

# create folder to store compiled framework for simulator - Debug
mkdir $BUILD_DEBUG_SIMULATOR

# get derived data path
DERIVED_DATA_SIMULATOR=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -configuration Debug -showBuildSettings -sdk iphonesimulator | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

# copy compiled framework for DEBUG simulator into our build folder
cp -r $DERIVED_DATA_SIMULATOR/RAnalytics.framework $BUILD_DEBUG_SIMULATOR
cp -r $DERIVED_DATA_SIMULATOR/RAnalytics.framework.dSYM $BUILD_DEBUG_SIMULATOR


###
### 1.2. build DEBUG framework for simulators - i386
###
xcodebuild -UseModernBuildSystem=YES BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" clean build -workspace RakutenAnalyticsSDK.xcworkspace -scheme RAnalytics-Framework -configuration Debug -sdk iphonesimulator ARCHS="i386"

# create folder to store compiled framework for simulator - Debug
mkdir $BUILD_DEBUG_SIMULATOR_i386

# get derived data path
DERIVED_DATA_SIMULATOR_i386=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -configuration Debug -showBuildSettings -sdk iphonesimulator | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

# copy compiled framework for DEBUG simulator into our build folder
cp -r $DERIVED_DATA_SIMULATOR_i386/RAnalytics.framework $BUILD_DEBUG_SIMULATOR_i386
cp -r $DERIVED_DATA_SIMULATOR_i386/RAnalytics.framework.dSYM $BUILD_DEBUG_SIMULATOR_i386


### 2. build RELEASE framework for simulators
xcodebuild -UseModernBuildSystem=YES BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" clean build -workspace RakutenAnalyticsSDK.xcworkspace -scheme RAnalytics-Framework -configuration Release -sdk iphonesimulator

# create folder to store compiled framework for simulator - Release
mkdir $BUILD_RELEASE_SIMULATOR

# get derived data path
DERIVED_DATA_SIMULATOR=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -configuration Release -showBuildSettings -sdk iphonesimulator | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

# copy compiled framework for RELEASE simulator into our build folder
cp -r $DERIVED_DATA_SIMULATOR/RAnalytics.framework $BUILD_RELEASE_SIMULATOR
cp -r $DERIVED_DATA_SIMULATOR/RAnalytics.framework.dSYM $BUILD_RELEASE_SIMULATOR


###
### 3. build DEBUG framework for devices
###
xcodebuild -UseModernBuildSystem=YES BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" clean build -workspace RakutenAnalyticsSDK.xcworkspace -scheme RAnalytics-Framework -configuration Debug -sdk iphoneos

# create folder to store compiled framework for device - Debug
mkdir $BUILD_DEBUG_DEVICE

# get derived data path
DERIVED_DATA_DEVICE=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -configuration Debug -showBuildSettings -sdk iphoneos | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

# copy compiled framework for devices into our build folder - Debug
cp -r $DERIVED_DATA_DEVICE/RAnalytics.framework $BUILD_DEBUG_DEVICE
cp -r $DERIVED_DATA_DEVICE/RAnalytics.framework.dSYM $BUILD_DEBUG_DEVICE


###
### 4. build RELEASE framework for devices
###
xcodebuild -UseModernBuildSystem=YES BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode -DRMSDK_ANALYTICS_VERSION=$RANALYTICS_FRAMEWORK_VERSION -DPUBLIC_ANALYTICS_IOS_SDK=1" clean build -workspace RakutenAnalyticsSDK.xcworkspace -scheme RAnalytics-Framework -configuration Release -sdk iphoneos
  
# create folder to store compiled framework for device - Release
mkdir $BUILD_RELEASE_DEVICE

# get derived data path
DERIVED_DATA_DEVICE=$(xcodebuild -workspace RakutenAnalyticsSDK.xcworkspace -UseModernBuildSystem=YES -scheme RAnalytics-Framework -configuration Release -showBuildSettings -sdk iphoneos | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\/.*")

# copy compiled framework for devices into our build folder - Release
cp -r $DERIVED_DATA_DEVICE/RAnalytics.framework $BUILD_RELEASE_DEVICE
cp -r $DERIVED_DATA_DEVICE/RAnalytics.framework.dSYM $BUILD_RELEASE_DEVICE

# create folders to store compiled universal framework for Debug and Release configurations
mkdir $BUILD_DEBUG_UNIVERSAL
mkdir $BUILD_RELEASE_UNIVERSAL


####################### Create universal framework #############################
# copy device framework into universal folder
cp -r $BUILD_DEBUG_DEVICE/RAnalytics.framework $BUILD_DEBUG_UNIVERSAL
cp -r $BUILD_RELEASE_DEVICE/RAnalytics.framework $BUILD_RELEASE_UNIVERSAL

cp -r $BUILD_DEBUG_DEVICE/RAnalytics.framework.dSYM $BUILD_DEBUG_UNIVERSAL
cp -r $BUILD_RELEASE_DEVICE/RAnalytics.framework.dSYM $BUILD_RELEASE_UNIVERSAL

# Xcode 12 patch: remove arm64 architecture from simulator release framework binary and dSym files
lipo -remove "arm64" $BUILD_RELEASE_SIMULATOR/$frameworkBinaryPath -o $BUILD_RELEASE_SIMULATOR/$frameworkBinaryPath
lipo -remove "arm64" $BUILD_RELEASE_SIMULATOR/$dSymFilePath -o $BUILD_RELEASE_SIMULATOR/$dSymFilePath

# create framework binary compatible with simulators and devices, and replace binary in universal framework
lipo -create \
$BUILD_DEBUG_SIMULATOR/$frameworkBinaryPath \
$BUILD_DEBUG_SIMULATOR_i386/$frameworkBinaryPath \
$BUILD_DEBUG_DEVICE/$frameworkBinaryPath \
-output $BUILD_DEBUG_UNIVERSAL/$frameworkBinaryPath

lipo -create \
  $BUILD_RELEASE_SIMULATOR/$frameworkBinaryPath \
  $BUILD_RELEASE_DEVICE/$frameworkBinaryPath \
  -output $BUILD_RELEASE_UNIVERSAL/$frameworkBinaryPath

# create universal dSYM for debug and release
lipo -create \
    $BUILD_DEBUG_SIMULATOR/$dSymFilePath \
    $BUILD_DEBUG_SIMULATOR_i386/$dSymFilePath \
    $BUILD_DEBUG_DEVICE/$dSymFilePath \
    -output $BUILD_DEBUG_UNIVERSAL/$dSymFilePath

lipo -create \
    $BUILD_RELEASE_SIMULATOR/$dSymFilePath \
    $BUILD_RELEASE_DEVICE/$dSymFilePath \
    -output $BUILD_RELEASE_UNIVERSAL/$dSymFilePath

# copy simulator Swift public interface to universal framework
#cp $$BUILD_DEBUG_SIMULATOR/RAnalytics.framework/Modules/RAnalytics.swiftmodule/* $BUILD_DEBUG_UNIVERSAL/RAnalytics.framework/Modules/RAnalytics.swiftmodule
#cp $$BUILD_RELEASE_SIMULATOR/RAnalytics.framework/Modules/RAnalytics.swiftmodule/* $BUILD_RELEASE_UNIVERSAL/RAnalytics.framework/Modules/RAnalytics.swiftmodule

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
allArchitectures=("arm64" "armv7")

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

# check if RATEndpoint warning exists or not
DEBUG_INFO="Your application's Info.plist must contain a key 'RATEndpoint' set to your endpoint URL"
DEBUG_VALIDATION=$(strings $BUILD_DEBUG_UNIVERSAL/$frameworkBinaryPath | grep "$DEBUG_INFO")
RELEASE_VALIDATION=$(strings $BUILD_RELEASE_UNIVERSAL/$frameworkBinaryPath | grep "$DEBUG_INFO")

if [ "$DEBUG_VALIDATION" = "$DEBUG_INFO" ]; then
    echo "OK: $BUILD_DEBUG_UNIVERSAL/$frameworkBinaryPath contains RATEndpoint warning message"
else
    echo "ERROR: $BUILD_DEBUG_UNIVERSAL/$frameworkBinaryPath doesn't contain RATEndpoint warning message"
    exit 1
fi

if [ "$RELEASE_VALIDATION" = "$DEBUG_INFO" ]; then
    echo "ERROR: $BUILD_RELEASE_UNIVERSAL/$frameworkBinaryPath contains RATEndpoint warning message"
    exit 1
else
    echo "OK: $BUILD_RELEASE_UNIVERSAL/$frameworkBinaryPath doesn't contain RATEndpoint warning message"
fi
