#!/bin/bash
set -eu

brew tap dart-lang/dart
brew install dart

sudo gem install compass
type sass
type compass

cd dart
pub get
pub build
