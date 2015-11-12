require 'xcodeproj'

fastlane_version "1.32.1"

default_platform :ios

platform :ios do
  before_all do
    if is_ci?
      keychainName = Fastlane::Actions.sh("security default-keychain", log: false).match(/.*\/([^\/]+)\"/)[1]
      puts "Using keychain: #{keychainName}"
      import_certificate keychain_name: keychainName, certificate_path: "certs/Distribution.cer"
      import_certificate keychain_name: keychainName, certificate_path: "certs/Distribution.p12", certificate_password: ENV["IOS_DISTRIBUTION_KEY_PASSWORD"]
    end

    if ENV["BUILD_NUM"] != nil then
      increment_build_number(
        build_number: ENV["BUILD_NUM"]
      )
    end

    sigh

    update_project_provisioning(
      xcodeproj: "#{ENV["APPLICATION_NAME"]}.xcodeproj",
      target_filter: ".*",
      build_configuration: "Release"
    )

    gym(
      scheme: ENV["APPLICATION_NAME"],
      configuration: "Release",
      include_bitcode: false,
      silent: true
    )

    # xctool # run the tests of your app
    # snapshot
  end

  desc "Runs all the tests"
  lane :test do
    # sh "your_script.sh"
    submit_crashlytics
  end

  desc "Submit a new build to Crashlytics"
  lane :debug do
    submit_crashlytics
  end

  def submit_crashlytics
    if is_ci?
      crashlytics(
        crashlytics_path: "./Pods/Crashlytics/Crashlytics.framework",
        api_token: ENV["FABRIC_API_KEY"],
        build_secret: ENV["FABRIC_BUILD_SECRET"],
        notes_path: ENV["RELEASE_NOTE_PATH"],
        groups: ENV["CRASHLYTICS_GROUPS"],
        ipa_path: "#{ENV["APPLICATION_NAME"]}.ipa"
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
