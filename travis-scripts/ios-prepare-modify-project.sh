#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

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

project = Xcodeproj::Project.open "${IOS_APPNAME}.xcodeproj"
project.recreate_user_schemes
build_settings(project,
	"ENABLE_BITCODE" => "NO",
	"PROVISIONING_PROFILE" => "\$(PROFILE_UDID)"
)
project.save
EOF

