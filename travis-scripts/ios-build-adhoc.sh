#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

ipa build \
  --workspace "${IOS_APPNAME}.xcwordspace" \
  --scheme "${IOS_APPNAME}" \
  --configuration Release \
  --destination Distribution/AdHoc \
  --embed MobileProvisionings/${IOS_APPNAME}_AdHoc.mobileprovision \
  --identity "$IOS_DISTRIBUTION_CERTIFICATE_COMMON_NAME"
