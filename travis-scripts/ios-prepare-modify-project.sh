#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

pbxproj="${IOS_APPNAME}.xcodeproj/project.pbxproj"
cat "$pbxproj" | sed 's/\(PROVISIONING_PROFILE = \"\).*\(\".*\)/\1$(PROFILE_UDID)\2/' > ${pbxproj}.tmp
mv -vf "${pbxproj}.tmp" "$pbxproj"
