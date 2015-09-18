#!/bin/bash
set -eu

echo

if [ "$BUILD_MODE" == "release" ]
then
	echo "Building iOS (release mode)..."
else
	echo "Building iOS (test mode)..."
	if [ "$BUILD_MODE" == "debug" ]
	then
		echo "Deploying iOS (debug mode)..."
	fi
fi

