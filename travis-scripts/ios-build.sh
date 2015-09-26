#!/bin/bash
set -eu

cd "$(dirname $0)"

./ios-prepare-import-keychain.sh

case "$BUILD_MODE" in
"release") ./ios-build-release.sh;;
"debug") ./ios-build-adhoc.sh;;
esac

