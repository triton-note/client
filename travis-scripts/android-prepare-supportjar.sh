#!/bin/bash
set -eu

cd $(dirname $0)/../platforms/android

SUPPORT_JAR=$(find $ANDROID_HOME/extras/ -name 'android-support-v13.jar' | head -n1)
echo "SUPPORT_JAR=$SUPPORT_JAR"

find ./ -name 'android-support*.jar' | while read file
do
        cp -vf "$SUPPORT_JAR" "$file"
done

find ./ -name 'build.gradle' | while read file
do
	cat <<EOF > $(dirname $file)/build-extras.gradle
configurations {
    all*.exclude group: 'com.android.support', module: 'support-v4'
    all*.exclude group: 'com.android.support', module: 'support-v13'
}
EOF
done
