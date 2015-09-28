#!/bin/bash
set -eu

########
#### Install dependencies

sudo gem install fastlane
sudo gem install cocoapods
sudo gem install psych -v 2.0.0
sudo gem list psych | tail -n1 | sed 's/.*(\(.*\)).*/\1/' | tr -d , | awk '{for (i=1; i<=NF; i++) print $i}' | while read version
do
	[ $version == '2.0.0' ] || sudo gem uninstall psych -v $version
done

########
#### Set environment variables

case "$BUILD_MODE" in
"debug") TARGET="AdHoc";;
"beta") TARGET="Release";;
"release") TARGET="Release";;
esac

export DELIVER_USER="$IOS_DELIVER_USER"
export DELIVER_PASSWORD="$IOS_DELIVER_PASSWORD"

########
#### Preparing

$(dirname $0)/ios-prepare-fastlane.sh

########
#### Build

cd "$(dirname $0)/../platforms/ios"
echo "Building iOS for ${TARGET} on $(pwd)"
fastlane $BUILD_MODE

