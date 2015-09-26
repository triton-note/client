#!/bin/bash
set -eu

gem install cupertino gym

cd "$(dirname $0)"

./ios-prepare-import-keychain.sh
./ios-prepare-update-bunble-version.sh

case "$BUILD_MODE" in
"release") TARGET="Release";;
"debug") TARGET="AdHoc";;
esac

cd "../platforms/ios"
echo "Building iOS for ${TARGET} on $(pwd)"

export GYM_CLEAN=true
export GYM_SDK="9.0"
export GYM_SCHEME="$IOS_APPNAME"
export GYM_INCLUDE_BITCODE=false
export GYM_CONFIGURATION="Release"
export GYM_CODE_SIGNING_IDENTITY="$IOS_DISTRIBUTION_CERTIFICATE_COMMON_NAME"
export GYM_OUTPUT_DIRECTORY="./build"
export GYM_DESTINATION="Distribution/${TARGET}"
export GYM_PROVISIONING_PROFILE_PATH="MobileProvisionings/${IOS_APPNAME}_${TARGET}.mobileprovision"

gym
