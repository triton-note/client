#!/bin/bash
set -eu

update() {
	echo "Installing $1..."
	echo y | android update sdk --no-ui --all --filter $1 | awk '
BEGIN { go = 0 }
/Do you accept the license/ { go = 1 }
/Warning/ { go = 1 }
go == 1 { print $0 }
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
