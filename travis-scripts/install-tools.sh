#!/bin/bash
set -eu

####
# Install Dart

brew update
brew tap dart-lang/dart
brew install dart

####
# Install cordova, ionic
npm install -g cordova ionic
