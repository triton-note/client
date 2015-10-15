#!/bin/bash
set -eu

########
#### Install dependencies

[ -z "$(type fastlane 2> /dev/null)" ] && sudo gem install fastlane
[ -z "$(type pod 2> /dev/null)" ] && sudo gem install cocoapods

########
#### Set environment variables

export DELIVER_USER="$IOS_DELIVER_USER"
export DELIVER_PASSWORD="$IOS_DELIVER_PASSWORD"
if [ "$BUILD_MODE" != "release" ]
then
	export SIGH_AD_HOC=true
	export GYM_USE_LEGACY_BUILD_API=true
fi

########
#### Preparing

(cd $(dirname $0)
time ./ios-prepare-cocoapod.sh
time ./ios-prepare-modify_project.sh
time ./ios-prepare-fastlane.sh
)

########
#### Build

cd "$(dirname $0)/../platforms/ios"
fastlane $BUILD_MODE

