#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

cat <<EOF > Podfile
pod 'Fabric'
pod 'Crashlytics'
EOF

pod install
