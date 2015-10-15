#!/bin/bash
set -eu

script_dir="$(cd $(dirname $0); pwd)"
cd "$script_dir/../platforms/ios"

echo "################################"
echo "#### Pod install"

[ -f Podfile ] || echo "platform :ios,'8.0'" > Podfile

pod install
