#!/bin/bash
set -eu

cd "$(dirname "$0")/../dart"

web/styles/fonts/retriever.sh
web/js/retriever.sh

pub get
pub build
