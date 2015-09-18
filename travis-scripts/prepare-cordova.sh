#!/bin/bash
set -eu

npm install -g cordova ionic

./reinstall_plugins.sh

cordova prepare
