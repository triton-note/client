#!/bin/bash
set -eu

brew tap dart-lang/dart
brew install dart

gem install compass
cat pubspec.yaml | awk '
	{print $0}
	/- sass/ { print "    executable: "$(type sass | awk '{print $NF}') }
' > pubspec.yaml.tmp
mv -vf pubspec.yaml.tmp pubspec.yaml

cd dart
pub get
pub build
