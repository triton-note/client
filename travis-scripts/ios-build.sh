#!/bin/bash
set -eu

cd "$(dirname $0)"

./ios-prepare-import-keychain.sh

if [ "$BUILD_MODE" == "release" ]
then
	echo "Building iOS (release mode)..."
	./ios-build-release.sh
else
	echo "Building iOS (test mode)..."
	if [ "$BUILD_MODE" == "debug" ]
	then
		echo "Deploying iOS (debug mode)..."
		./ios-build-adhoc.sh
	fi
fi

