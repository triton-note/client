#!/bin/bash
set -eu

brew tap dart-lang/dart
brew install dart
gem install sass

cd dart
pub get
pub build
