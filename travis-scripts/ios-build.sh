#!/bin/bash
set -eu

########
#### Install dependencies

sudo gem install fastlane cocoapods

########
#### Set environment variables

export DELIVER_USER="$IOS_DELIVER_USER"
export DELIVER_PASSWORD="$IOS_DELIVER_PASSWORD"

########
#### Preparing

$(dirname $0)/ios-prepare-fastlane.sh

########
#### Build

cd "$(dirname $0)/../platforms/ios"
fastlane $BUILD_MODE

