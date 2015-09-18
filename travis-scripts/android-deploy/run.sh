#!/bin/bash
set -eu

cd $(dirname $0)

if [ "$BUILD_MODE" != "test" ]
then
	[ "$BUILD_MODE" == "release" ] && export ANDROID_GOOGLEPLAY_TRACK_NAME=production
	[ "$BUILD_MODE" == "debug" ] && export ANDROID_GOOGLEPLAY_TRACK_NAME=alpha
	echo "Deploying Android for ${ANDROID_GOOGLEPLAY_TRACK_NAME}..."

	export ANDROID_GOOGLEPLAY_SERVICE_ACCOUNT_KEY_FILE_PATH="key.p12"
	export ANDROID_GOOGLEPLAY_APK_FILE_PATH="${TRAVIS_BUILD_DIR}/platforms/android/ant-build/CordovaApp-release.apk"
	
	echo $ANDROID_GOOGLEPLAY_SERVICE_ACCOUNT_KEY_BASE64 | base64 -D > "$ANDROID_GOOGLEPLAY_SERVICE_ACCOUNT_KEY_FILE_PATH"
	
	java -version
	brew install sbt
	export SBT_OPTS="-XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=256M"
	sbt run
fi
