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

echo "$ANDROID_KEYSTORE_BASE64" | base64 -D > platforms/android/keystore

echo <<EOF > platforms/android/ant.properties
key.store=keystore
key.alias=$ANDROID_KEYSTORE_ALIAS
key.store.password=$ANDROID_KEYSTORE_PASSWORD
key.alias.password=$ANDROID_KEYSTORE_ALIAS_PASSWORD
EOF

echo "Building Android..."
cordova build android --release --stacktrace

track_name() {
	case "$BUILD_MODE" in
	"release") echo production;;
	"debug")   echo alpha;;
	esac
}
name=$(track_name)
if [ ! -z "$name" ]
then
	cd $(dirname $0)
	git clone https://github.com/sawatani/CI-STEP-Deploy-GooglePlay.git android-deploy
	cd android-deploy
	./run.sh $name
fi
