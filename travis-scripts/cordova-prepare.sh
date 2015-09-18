#!/bin/bash
set -eu

pwd
. $(dirname $0)/check-mode

npm install cordova ionic

if [ "$BUILD_MODE" == "release" ]
then
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_RELEASE"
else
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_DEBUG"
fi
./reinstall_plugins.sh
