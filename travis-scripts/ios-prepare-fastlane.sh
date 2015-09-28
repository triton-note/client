#!/bin/bash
set -eu

cd "$(dirname $0)/../platforms/ios"

cat <<EOF > Podfile
pod 'Fabric'
pod 'Crashlytics'
EOF

mkdir -vp fastlane
cat <<EOF > fastlane/Fastfile
fastlane_version "1.29.2"

default_platform :ios

platform :ios do
  before_all do
    cocoapods

    # increment_build_number

    sigh(
      app_identifier: "$IOS_BUNDLE_ID",
      provisioning_name: "${IO_APPANME} Release",
      username: "$DELIVER_USER"
    )
    gym(
      clean: true,
      scheme: "$IOS_APPNAME",
      codesigning_identity: "$IOS_DISTRIBUTION_CERTIFICATE_COMMON_NAME",
      provisioning_profile_path: "AppStore_${IOS_BUNDLE_ID}.mobileprovision",
      configuration: "Release",
      include_bitcode: false
    )

    # xctool # run the tests of your app
    # snapshot
  end

  desc "Runs all the tests"
  lane :debug do
    crashlytics(
      crashlytics_path: "./Pods/Crashlytics/Crashlytics.framework",
      api_token: "$FABRIC_API_KEY",
      build_secret: "$FABRIC_BUILD_SECRET",
      ipa_path: "./app.ipa"
    )
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

