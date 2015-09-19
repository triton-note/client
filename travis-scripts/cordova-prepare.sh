#!/bin/bash
set -eu

pwd
ls -la

npm install cordova ionic

type cordova
type ionic

if [ "$BUILD_MODE" == "release" ]
then
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_RELEASE"
else
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_DEBUG"
fi
./reinstall_plugins.sh
