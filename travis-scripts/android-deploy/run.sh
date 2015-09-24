#!/bin/bash
set -eu

cd $(dirname $0)

ANDROID_GOOGLEPLAY_TRACK_NAME=$1
echo "Deploying Android for ${ANDROID_GOOGLEPLAY_TRACK_NAME}..."

export ANDROID_GOOGLEPLAY_SERVICE_ACCOUNT_KEY_FILE_PATH="key.p12"
export ANDROID_GOOGLEPLAY_APK_FILE_PATH="${TRAVIS_BUILD_DIR}/platforms/android/ant-build/CordovaApp-release.apk"

echo $ANDROID_GOOGLEPLAY_SERVICE_ACCOUNT_KEY_BASE64 | base64 -D > "$ANDROID_GOOGLEPLAY_SERVICE_ACCOUNT_KEY_FILE_PATH"

export SBT_OPTS="-XX:+CMSClassUnloadingEnabled"
sbt run
