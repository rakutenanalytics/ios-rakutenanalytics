
#################################################################################################################
# Copyright: Copyright (C) 2012 Rakuten, Inc.  All Rights Reserved.
# Author: Sumanta Rout
# Created: 06-Aug-2012 
# 
# Script to build Rakuten Analytics project into an iPhone framework
# 
##################################################################################################################


#################################################################################################################
# Variables and Functions
# Variables are used to specify file names and paths. Those who are not defined here are environment variables.
#################################################################################################################

# The project target name that builds project into a static library (.a). By convention it is the same as project name.
STATIC_LIBRARY_NAME=$PROJECT_NAME

# Static library file name and paths for architectures of iPhone device and iPhone simulator.
STATIC_LIBRARY_FILE_NAME=lib$STATIC_LIBRARY_NAME.a
STATIC_LIBRARY_FILE_PATH_DEVICE="$SYMROOT/$CONFIGURATION-iphoneos/$STATIC_LIBRARY_FILE_NAME"
STATIC_LIBRARY_FILE_PATH_SIMULATOR="$SYMROOT/$CONFIGURATION-iphonesimulator/$STATIC_LIBRARY_FILE_NAME"

# Plist file path
#PLIST_FILE_PATH=$SRCROOT/Info.plist

# Root directory to look for .h files
HEADER_FILES_ROOT_DIR=RakutenAnalytic #if required, you can replace RakutenAnalytic/Analytics with "." It will copy all the headers files expect headers defined in excluded folders
HEADER_FILES_EXCLUDED_DIR=build

# FILES LIST TO BE COPIED
RTRACKINGLIBRARY_HEADER="$HEADER_FILES_ROOT_DIR/Analytics/RATrackingLib.h"

# The desired framework name and output directory.
FRAMEWORK_NAME=$PROJECT_NAME
FRAMEWORK_ROOT_DIR="$SYMROOT/$FRAMEWORK_NAME.framework" 

# Function to print fatal error message and terminate the script
function error_exit
{
	echo "${1:-"Unknown Error"}. Aborting..." 1>&2
	exit 1
}


##################################################################################################################
# Cleaning existing framework files
##################################################################################################################

# Clean any existing framework that might be there already  
echo "Framework: Cleaning framework..."  
[ -d $FRAMEWORK_ROOT_DIR ] && rm -rf $FRAMEWORK_ROOT_DIR


##################################################################################################################
# Construct framework directories
##################################################################################################################

echo "Framework: Setting up directories..."  
mkdir -p $FRAMEWORK_ROOT_DIR/Headers || error_exit "Line$LINENO: Failed to create directory $FRAMEWORK_ROOT_DIR/Headers"
echo "    +$FRAMEWORK_ROOT_DIR"
echo "    +$FRAMEWORK_ROOT_DIR/Headers"
mkdir -p $FRAMEWORK_ROOT_DIR/Resources || error_exit "Line$LINENO: Failed to create directory $FRAMEWORK_ROOT_DIR/Resources"
echo "    +$FRAMEWORK_ROOT_DIR/Resources"


##################################################################################################################
# Create universal binary with static libraries of all supported architectures
##################################################################################################################

echo "Framework: Creating universal binary"
echo "    Generating static library for iPhone device by project target '$STATIC_LIBRARY_NAME' "
xcodebuild -configuration $CONFIGURATION -workspace RakutenAnalytic.xcworkspace -scheme $STATIC_LIBRARY_NAME -sdk iphoneos || error_exit "Line$LINENO: Failed to build target $STATIC_LIBRARY_NAME for iphoneos4.2."
echo "    Generating static library for iPhone simulator by project target '$STATIC_LIBRARY_NAME' "  
xcodebuild -configuration $CONFIGURATION -workspace RakutenAnalytic.xcworkspace -scheme $STATIC_LIBRARY_NAME -sdk iphonesimulator || error_exit "Line$LINENO: Failed to build target $STATIC_LIBRARY_NAME for iphonesimulator4.2."
echo "    Assembling universal binary with $STATIC_LIBRARY_FILE_PATH_DEVICE and $STATIC_LIBRARY_FILE_PATH_SIMULATOR"
lipo  -create "$STATIC_LIBRARY_FILE_PATH_DEVICE" "$STATIC_LIBRARY_FILE_PATH_SIMULATOR" -o "$FRAMEWORK_ROOT_DIR/$FRAMEWORK_NAME" || error_exit "Line$LINENO: Failed to create universal binary."


##################################################################################################################
# Copy headers and resources
##################################################################################################################
 
echo "Framework: Copying assets..." 
echo "    Copying all .h file found in $HEADER_FILES_ROOT_DIR (including sub folders)"
################################ Copying Required Header Files #############################################
cp "$RTRACKINGLIBRARY_HEADER" "$FRAMEWORK_ROOT_DIR/Headers/" || error_exit "Line$LINENO: Failed to copy $RTRACKINGLIBRARY_HEADER header files."

exit 0
