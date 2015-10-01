#!/bin/bash
set -eu

cd $(dirname $0)/../

file="config.xml"
cat "$file" | sed "s/\(widget \)\(.*\)/\1android-versionCode=\"${BUILD_NUM}00\" \2/" > "${file}.tmp"
mv -vf "${file}.tmp" "$file"
