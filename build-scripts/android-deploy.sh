#!/bin/bash
set -eu

cd $(dirname $0)
target_dir=$(cd ../platforms/android; pwd)

case "$BUILD_MODE" in
"beta")    track_name=beta;;
"release") track_name=production;;
*)   track_name="";;
esac

if [ -z "$track_name" ]
then
	cd "$target_dir"
	./gradlew crashlyticsUploadDistributionRelease
else
	git clone https://github.com/sawatani/CI-STEP-Deploy-GooglePlay.git android-deploy
	./android-deploy/run.sh $track_name $(find $target_dir/build/ -name '*-release.apk')
fi
