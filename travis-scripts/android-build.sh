#!/bin/bash
set -eu

echo

java -version
brew install sbt

if [ "$BUILD_MODE" == "release" ]
then
	echo "Building Android (release mode)..."
else
	echo "Building Android (test mode)..."
	if [ "$BUILD_MODE" == "debug" ]
	then
		echo "Deploying Android (debug mode)..."
	fi
fi

