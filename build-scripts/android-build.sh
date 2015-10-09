#!/bin/bash
set -eu

########
#### Install dependencies

brew install sbt android
export ANDROID_HOME=$(brew --prefix android) && echo $ANDROID_HOME

########
#### Preparing

[ -z "${IS_CI:-}" ] || (cd $(dirname $0)
time ./android-prepare-update.sh
time ./android-prepare-keystore.sh
time ./android-prepare-build_num.sh
)

########
#### Build

if [ -z "${IS_CI:-}" ]
then
	cordova build android
else
	[ "$BUILD_MODE" == "debug" ] && echo "cdvBuildMultipleApks=false" >> platforms/android/gradle.properties
	cordova build android --release --buildConfig=platforms/android/build.json
fi

########
#### Deploy

[ -z "${IS_CI:-}" ] || $(dirname $0)/android-deploy.sh
