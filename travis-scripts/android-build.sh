#!/bin/bash
set -eu

update() {
	echo "Updating $1..."
	echo y | android update sdk --no-ui --all --filter $1 | awk '
BEGIN { go = 0 }
/Do you accept the license/ { go = 1 }
/Warning/ { go = 1 }
{ if (go == 1) print $0 }
'
}

cat <<EOF | while read name; do update "$name"; done
platform-tools
tools
android-21
android-22
extra-google-m2repository
extra-android-support
extra-android-m2repository
build-tools-21.1.2
build-tools-22.0.1
EOF

SUPPORT_JAR=$(find $ANDROID_HOME/extras/ -name 'android-support-v13.jar' | head -n1)
echo "SUPPORT_JAR=$SUPPORT_JAR"

find platforms/android/ -name 'android-support*.jar' | while read file
do
        cp -vf "$SUPPORT_JAR" "$file"
done

$(dirname $0)/android-keystore.sh

echo "Building Android..."
cordova build android --release --stacktrace --buildConfig=platforms/android/build.json
apk=$(find ./ -name '*-x86-release.apk')

case "$BUILD_MODE" in
"release") track_name=production;;
"debug")   track_name=alpha;;
esac
if [ ! -z "$apk" -a ! -z "$track_name" ]
then
	cd $(dirname $0)
	git clone https://github.com/sawatani/CI-STEP-Deploy-GooglePlay.git android-deploy
	./android-deploy/run.sh $apk $track_name
fi
