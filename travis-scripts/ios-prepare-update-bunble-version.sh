#!/bin/bash
set -eu

BUILD_NUM="$1"

cd "$(dirname $0)/../platforms/ios"

ls **/*/Info.plist | while read file
do
  echo "Update BundleVersion: $file"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUM}" "$file"
done
