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
	echo y | android update sdk --no-ui --filter $1 || exit 1
}

echo <<EOF | while read name; do update $name; done
tools
platform-tools
android-22
addon-google_apis-google-22
extra-google-m2repository
extra-android-support
EOF

echo "Building Android..."
cordova build android --release

$(dirname $0)/android-deploy/run.sh

