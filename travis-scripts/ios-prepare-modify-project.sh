#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

cat <<EOF | ruby
require 'xcodeproj'

def append_script(project, script)
	project.targets.each do |target|
		phase = target.new_shell_script_build_phase "Fabric"
		phase.shell_script = script
		target.shell_script_build_phases.push phase
	end
end

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
	"OTHER_LDFLAGS" => "\$(inherited)",
	"ENABLE_BITCODE" => "NO",
	"PROVISIONING_PROFILE" => "\$(PROFILE_UDID)"
)
append_script(project, "./Pods/Fabric/Fabric.framework/run $FABRIC_API_KEY $FABRIC_BUILD_SECRET")
project.save
EOF

file=$(find . -name 'AppDelegate.m')
cat "$file" | awk '
	/didFinishLaunchingWithOptions/ { did=1 }
	/return/ {
		if (did == 1) {
			print "    [Fabric with:@[CrashlyticsKit]];"
			did=0
		}
	}
	{ print $0 }
	/#import </ {
		print "#import <Fabric/Fabric.h>"
		print "#import <Crashlytics/Crashlytics.h>"
	}
' > "${file}.tmp"
mv -vf "${file}.tmp" "$file"

