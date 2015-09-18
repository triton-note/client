#!/bin/bash
set -eu

brew tap dart-lang/dart
brew install dart
gem install compass

cd dart
pub get
pub build
