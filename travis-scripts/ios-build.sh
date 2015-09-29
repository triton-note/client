#!/bin/bash
set -eu

########
#### Install dependencies

[ -z "$(type fastlane)" ] && sudo gem install fastlane
[ -z "$(type pod)" ] && sudo gem install cocoapods

########
#### Set environment variables

export DELIVER_USER="$IOS_DELIVER_USER"
export DELIVER_PASSWORD="$IOS_DELIVER_PASSWORD"

########
#### Preparing

(cd $(dirname $0)
./ios-prepare-modify-project.sh
./ios-prepare-fastlane.sh
)

########
#### Build

cd "$(dirname $0)/../platforms/ios"
fastlane $BUILD_MODE

