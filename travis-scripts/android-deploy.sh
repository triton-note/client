#!/bin/bash
set -eu

cd $(dirname $0)
target_dir=$(cd ../platforms/android; pwd)

case "$BUILD_MODE" in
"release") track_name=production;;
"debug")   track_name=alpha;;
esac
if [ -z "$track_name" ]
then
	git clone https://github.com/sawatani/CI-STEP-Deploy-GooglePlay.git android-deploy
	./android-deploy/run.sh $track_name $(find $target_dir/build/ -name '*-release.apk')
fi
