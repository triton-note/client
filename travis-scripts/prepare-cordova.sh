#!/bin/bash
set -eu

. $(dirname $0)/check-mode.sh

npm install cordova ionic

if [ "$RELEASE" == "true" ]
then
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_RELEASE"
else
	export FACEBOOK_APP_ID="$FACEBOOK_APP_ID_DEBUG"
fi
echo "$FACEBOOK_APP_ID"
./reinstall_plugins.sh
