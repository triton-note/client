#!/bin/bash
set -eu

case "$BUILD_MODE" in
"release") export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_RELEASE";;
"beta" | "debug") export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_DEBUG";;
esac
./reinstall_plugins.sh
