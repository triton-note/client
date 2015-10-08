#!/bin/bash
set -eu

script_dir="$(cd $(dirname $0); pwd)"
cd "$script_dir/../platforms/ios"

echo "################################"
echo "#### Pod install"

pod install

echo "################################"
echo "#### Fix project.pbxproj"

proj="$(find . -maxdepth 1 -name '*.xcodeproj')"
echo "Fixing $proj"

cat <<EOF | ruby
require 'xcodeproj'

def build_settings(project, params)
	project.targets.each do |target|
		target.build_configurations.each do |conf|
			params.each do |key, value|
				conf.build_settings[key] = value
			end
		end
	end
end

project = Xcodeproj::Project.open "$proj"
project.recreate_user_schemes

build_settings(project,
	"OTHER_LDFLAGS" => "\$(inherited)",
	"ENABLE_BITCODE" => "NO",
	"PROVISIONING_PROFILE" => "\$(PROFILE_UDID)"
)

project.save
EOF
