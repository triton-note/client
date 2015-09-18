#!/bin/bash
set -eu

echo "$ANDROID_KEYSTORE_BASE64" | base64 -D > platforms/android/keystore

echo <<EOF > platforms/android/ant.properties
key.store=keystore
key.alias=$ANDROID_KEYSTORE_ALIAS
key.store.password=$ANDROID_KEYSTORE_PASSWORD
key.alias.password=$ANDROID_KEYSTORE_ALIAS_PASSWORD
EOF

echo "Building Android..."
cordova build android --release

$(dirname $0)/android-deploy/run.sh

