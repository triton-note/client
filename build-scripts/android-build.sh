#!/bin/bash
set -eu

########
#### Install dependencies

brew install sbt android
export ANDROID_HOME=$(brew --prefix android) && echo $ANDROID_HOME

########
#### Preparing

(cd $(dirname $0)
[ -z "${IS_CI:-}" ] || ./android-prepare-update.sh
./android-prepare-keystore.sh
./android-prepare-fabric.sh
./android-prepare-build_num.sh
)

########
#### Build

[ "$BUILD_MODE" == "debug" ] && echo "cdvBuildMultipleApks=false" >> platforms/android/gradle.properties
cordova build android --release --buildConfig=platforms/android/build.json

########
#### Deploy

[ -z "${IS_CI:-}" ] || $(dirname $0)/android-deploy.sh
