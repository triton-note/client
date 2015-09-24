#!/bin/bash
set -eu

cd $(dirname $0)

./android-prepare-update.sh
./android-prepare-keystore.sh
./android-prepare-supportjar.sh

cordova build android --release --stacktrace --buildConfig=platforms/android/build.json
