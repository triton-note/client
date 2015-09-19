#!/bin/bash
set -eu

npm install
export PATH=$PATH:~/node_modules/cordova/bin:~/node_modules/ionic/bin

type cordova
type ionic

if [ "$BUILD_MODE" == "release" ]
then
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_RELEASE"
else
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_DEBUG"
fi
./reinstall_plugins.sh
