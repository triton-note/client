#!/bin/bash
set -eu

script_dir="$(cd $(dirname $0); pwd)"
cd "$script_dir/../platforms/ios"

echo "################################"
echo "#### Fix project.pbxproj"

proj="$(find . -maxdepth 1 -name '*.xcodeproj')"
echo "Fixing $proj"

cat <<EOF | ruby
require 'xcodeproj'

def append_script(project, name, script)
	project.targets.each do |target|
		phase = target.new_shell_script_build_phase name
		phase.shell_script = script
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

project = Xcodeproj::Project.open "$proj"
project.recreate_user_schemes

build_settings(project,
	"OTHER_LDFLAGS" => "\$(inherited)",
	"ENABLE_BITCODE" => "NO",
	"PROVISIONING_PROFILE" => "\$(PROFILE_UDID)"
)
append_script(project, "Fabric", "./Pods/Fabric/Fabric.framework/run $FABRIC_API_KEY $FABRIC_BUILD_SECRET")

project.save
EOF

echo "################################"
echo "#### Fabric initialization"

file="$(find . -name 'AppDelegate.m')"
echo "Edit $file"

cat "$file" | awk '
	/didFinishLaunchingWithOptions/ { did=1 }
	/return/ && (did == 1) {
		print "    [Fabric with:@[CrashlyticsKit]];"
		did=0
	}
	{ print $0 }
	/#import </ {
		print "#import <Fabric/Fabric.h>"
		print "#import <Crashlytics/Crashlytics.h>"
	}
' > "${file}.tmp"
mv -vf "${file}.tmp" "$file"

echo "################################"
echo "#### Fabric API_KEY"

file="$(find . -name '*-Info.plist')"
echo "Edit $file"

cat "$file" | awk '{print $0}' > "${file}.tmp"
mv -vf "${file}.tmp" "$file"

head -n$(($(wc -l "$file" | awk '{print $1}') - 2)) "$file" > "${file}.tmp"
cat <<EOF >> "${file}.tmp"
<key>Fabric</key>
<dict>
    <key>APIKey</key>
    <string>$FABRIC_API_KEY</string>
    <key>Kits</key>
    <array>
        <dict>
            <key>KitInfo</key>
            <dict/>
            <key>KitName</key>
            <string>Crashlytics</string>
        </dict>
    </array>
</dict>
EOF
tail -n2 "$file" >> "${file}.tmp"
mv -vf "${file}.tmp" "$file"

