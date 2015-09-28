#!/bin/bash
set -eu

########
#### Install dependencies

gem install fastlane

########
#### Set environment variables

case "$BUILD_MODE" in
"debug") TARGET="AdHoc";;
"beta") TARGET="Release";;
"release") TARGET="Release";;
esac

export DELIVER_USER="$IOS_DELIVER_USER"
export DELIVER_PASSWORD="$IOS_DELIVER_PASSWORD"

########
#### Preparing

$(dirname $0)/ios-prepare-fastlane.sh

########
#### Build

cd "$(dirname $0)/../platforms/ios"
echo "Building iOS for ${TARGET} on $(pwd)"
fastlane $TARGET

