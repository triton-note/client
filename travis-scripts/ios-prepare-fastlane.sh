#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

cat <<EOF > Podfile
platform :ios, '9.0'
pod 'Fabric'
pod 'Crashlytics'
EOF

pod install
