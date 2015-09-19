#!/bin/bash
set -eu

cd dart

gem install compass
cat pubspec.yaml | awk ' {print $0}
	/- sass/ {
		"type -p sass" | getline path
		print "    executable: "path
	}
' > pubspec.yaml.tmp
mv -vf pubspec.yaml.tmp pubspec.yaml
echo "Using pubspec.yaml"
cat pubspec.yaml

pub get
pub build
