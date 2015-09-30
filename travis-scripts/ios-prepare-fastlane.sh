#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

mkdir -vp fastlane

(mkdir -vp certs && cd certs
echo $IOS_DISTRIBUTION_CERTIFICATE_BASE64 | base64 -D > Distribution.cer
echo $IOS_DISTRIBUTION_KEY_BASE64 | base64 -D > Distribution.p12
)

cat <<EOF > fastlane/Appfile
app_identifier "$IOS_BUNDLE_ID"
EOF

cat <<EOF > fastlane/Fastfile
fastlane_version "1.29.2"

default_platform :ios

platform :ios do
  before_all do
    if is_ci?
      keychainName = Fastlane::Actions.sh("security default-keychain", log: false).match(/.*\/([^\/]+)\"/)[1]
      puts "Using keychain: #{keychainName}"
      import_certificate keychain_name: keychainName, certificate_path: "certs/Distribution.cer"
      import_certificate keychain_name: keychainName, certificate_path: "certs/Distribution.p12", certificate_password: "$IOS_DISTRIBUTION_KEY_PASSWORD"
    else
      puts "On human pc"
    end

    sigh
    ENV["PROFILE_UDID"] = lane_context[SharedValues::SIGH_UDID]

    increment_build_number(
      build_number: "$BUILD_NUM"
    )

    gym(
      scheme: "$IOS_APPNAME",
      configuration: "Release"
    )

    # xctool # run the tests of your app
    # snapshot
  end

  desc "Runs all the tests"
  lane :debug do
    if is_ci?
      crashlytics(
        crashlytics_path: "./Pods/Crashlytics/Crashlytics.framework",
        api_token: "$FABRIC_API_KEY",
        build_secret: "$FABRIC_BUILD_SECRET",
        groups: "$CRASHLYTICS_GROUPS",
        ipa_path: "./${IOS_APPNAME}.ipa"
      )
    end
  end

  desc "Submit a new Beta Build to Apple TestFlight"
  desc "This will also make sure the profile is up to date"
  lane :beta do
    # sh "your_script.sh"
  end

  desc "Deploy a new version to the App Store"
  lane :release do
    # deliver(skip_deploy: true, force: true)
    # frameit
  end
end
EOF

