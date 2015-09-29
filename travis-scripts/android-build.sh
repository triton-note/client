#!/bin/bash
set -eu

########
#### Install dependencies

brew install sbt android
export ANDROID_HOME=$(brew --prefix android) && echo $ANDROID_HOME

########
#### Preparing

(cd $(dirname $0)
./android-prepare-update.sh
./android-prepare-keystore.sh
./android-prepare-supportjar.sh
./android-prepare-fabric.sh
)

########
#### Build

cordova build android --release --stacktrace --buildConfig=platforms/android/build.json

########
#### Deploy

$(dirname $0)/android-deploy.sh
