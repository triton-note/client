#!/bin/bash
set -eu

cd $(dirname $0)

brew install sbt android
export ANDROID_HOME=$(brew --prefix android) && echo $ANDROID_HOME

./android-prepare-update.sh
./android-prepare-keystore.sh
./android-prepare-supportjar.sh

cordova build android --release --stacktrace --buildConfig=platforms/android/build.json
