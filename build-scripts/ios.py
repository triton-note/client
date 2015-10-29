#!/usr/bin/env python

import os
import shutil
import sys

from config import Config
import shell


def platform_dir(*paths):
    return os.path.join('platforms', 'ios', *paths)

def profile():
    key = 'PROVISIONING_PROFILE'
    target = platform_dir('cordova', 'build.xcconfig')
    def read_lines():
        if os.path.exists(target):
            with open(target, mode='r') as file:
                lines = file.readlines()
                lines = filter(lambda a: not key in a, lines)
                return map(lambda a: a.rstrip(), lines)
    lines = list(read_lines())
    lines.append('%s = \$(PROFILE_UDID)' % key)
    with open(target, mode='w') as file:
        file.write('\n'.join(lines) + '\n')

def certs():
    dir = platform_dir('certs')
    shell.mkdirs(dir)
    for ext in ['cer', 'p12']:
        shutil.copy(Config.file('ios', 'Distribution.%s' % ext), dir)

def fastfiles():
    dir = platform_dir('fastlane')
    shell.mkdirs(dir)
    with open(os.path.join(dir, 'Appfile'), mode='w') as file:
        file.write('app_identifier "%s"\n' % Config.get('platforms.ios.BUNDLE_ID'))
    with open(os.path.join(dir, 'Fastfile'), mode='w') as file:
        file.write("""fastlane_version "1.32.1"

default_platform :ios

platform :ios do
  before_all do
    if is_ci?
      keychainName = Fastlane::Actions.sh("security default-keychain", log: false).match(/.*\/([^\/]+)\"/)[1]
      puts "Using keychain: #{keychainName}"
      import_certificate keychain_name: keychainName, certificate_path: "certs/Distribution.cer"
      import_certificate keychain_name: keychainName, certificate_path: "certs/Distribution.p12", certificate_password: ENV["IOS_DISTRIBUTION_KEY_PASSWORD"]
    else
      puts "On human pc"
    end

    increment_build_number(
      build_number: ENV["BUILD_NUM"]
    )

    sigh
    ENV["PROFILE_UDID"] = lane_context[SharedValues::SIGH_UDID]

    gym(
      scheme: ENV["APPLICATION_NAME"],
      configuration: "Release",
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
        ipa_path: "./#{ENV["APPLICATION_NAME"]}.ipa"
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
""")

def fastlane():
    def environment_variables():
        print('Setting environment variables')
        os.environ['IOS_DISTRIBUTION_KEY_PASSWORD'] = Config.get('platforms.ios.DISTRIBUTION_KEY_PASSWORD')
        os.environ['APPLICATION_NAME'] = Config.get('APPLICATION_NAME')
        os.environ['FABRIC_API_KEY'] = Config.get('fabric.API_KEY')
        os.environ['FABRIC_BUILD_SECRET'] = Config.get('fabric.BUILD_SECRET')
        os.environ['CRASHLYTICS_GROUPS'] = Config.get('fabric.CRASHLYTICS_GROUPS')
        os.environ['DELIVER_USER'] = Config.get('platforms.ios.DELIVER_USER')
        os.environ['DELIVER_PASSWORD'] = Config.get('platforms.ios.DELIVER_PASSWORD')
        if os.environ['BUILD_MODE'] != 'release':
            os.environ['SIGH_AD_HOC'] = 'true'
            os.environ['GYM_USE_LEGACY_BUILD_API'] = 'true'

    here = os.getcwd()
    os.chdir(platform_dir())
    try:
        environment_variables()
        shell.cmd('fastlane %s' % os.environ['BUILD_MODE'])
    finally:
        os.chdir(here)

def all():
    print('Building iOS')
    profile()
    certs()
    fastfiles()
    fastlane()

if __name__ == "__main__":
    shell.on_root(sys.argv[0])
    Config.load()

    action = sys.argv[1]
    if action == "profile":
        profile()
    elif action == "certs":
        certs()
    elif action == "fastfiles":
        fastfiles()
    elif action == "fastlane":
        fastlane()
