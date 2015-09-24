#!/bin/bash
set -eu

echo "$ANDROID_KEYSTORE_BASE64" | base64 -D > platforms/android/keystore

echo <<EOF > platforms/android/ant.properties
key.store=keystore
key.alias=$ANDROID_KEYSTORE_ALIAS
key.store.password=$ANDROID_KEYSTORE_PASSWORD
key.alias.password=$ANDROID_KEYSTORE_ALIAS_PASSWORD
EOF

update() {
	echo y | android update sdk --no-ui --all --filter $1 || exit 1
}

cat <<EOF | while read name; do update "$name"; done
tools
platform-tools
android-21
android-22
extra-google-m2repository
extra-android-support
extra-android-m2repository
build-tools-21.1.2
build-tools-22.0.1
EOF

echo "Building Android..."
cordova build android --release --stacktrace

case "$BUILD_MODE" in
"release") export ANDROID_GOOGLEPLAY_TRACK_NAME=production;;
"debug")   export ANDROID_GOOGLEPLAY_TRACK_NAME=alpha;;
esac
$(dirname $0)/android-deploy/run.sh
