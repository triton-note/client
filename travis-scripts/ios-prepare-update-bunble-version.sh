#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

echo "Updating BundleVersion [${BUILD_NUM}] on $(pwd)"

find ./ -name '*Info.plist' | grep -v 'Plugins' | while read file
do
  echo "Update BundleVersion: $file"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUM}" "$file"
done
