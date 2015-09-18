#!/bin/bash
set -eu

brew tap dart-lang/dart
brew install dart

cd dart
pub get
pub build
