#!/bin/bash
set -eu

cd $(dirname $0)/platforms/android

echo "$ANDROID_KEYSTORE_BASE64" | base64 -D > keystore

cat <<EOF > build.json
{ "android": { "release": {
"keystore": "$(pwd)/keystore",
"alias": "$ANDROID_KEYSTORE_ALIAS",
"storePassword": "$ANDROID_KEYSTORE_PASSWORD",
"password": "$ANDROID_KEYSTORE_ALIAS_PASSWORD"
}}}
EOF
