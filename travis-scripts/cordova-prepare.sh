#!/bin/bash
set -eu

if [ "$BUILD_MODE" == "release" ]
then
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_RELEASE"
else
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_DEBUG"
fi
./reinstall_plugins.sh

cordova prepare
