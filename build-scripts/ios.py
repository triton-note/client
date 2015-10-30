#!/usr/bin/env python

from optparse import OptionParser
import os
import shutil
import sys

from config import Config
import shell


def platform_dir(*paths):
    return os.path.join('platforms', 'ios', *paths)

def install():
    shell.cmd('sudo gem install fastlane cocoapods')
    shell.cmd('cordova prepare ios')

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
    keychainName = Fastlane::Actions.sh("security default-keychain", log: false).match(/.*\/([^\/]+)\"/)[1]
    puts "Using keychain: #{keychainName}"
    import_certificate keychain_name: keychainName, certificate_path: "certs/Distribution.cer"
    import_certificate keychain_name: keychainName, certificate_path: "certs/Distribution.p12", certificate_password: ENV["IOS_DISTRIBUTION_KEY_PASSWORD"]

    increment_build_number(
      build_number: ENV["BUILD_NUM"]
    )

    sigh

    update_project_provisioning(
      xcodeproj: "#{ENV["APPLICATION_NAME"]}.xcodeproj",
      target_filter: ".*",
      build_configuration: "Release"
    )

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

def fastlane(build_mode, build_num, overwrite_environ=True):
    def environment_variables():
        def set_value(name, value):
            if not (os.environ.get(name) and not overwrite_environ):
                print('Setting environment variable:', name)
                os.environ[name] = value
        map = {
               'IOS_DISTRIBUTION_KEY_PASSWORD': 'platforms.ios.DISTRIBUTION_KEY_PASSWORD',
               'APPLICATION_NAME': 'APPLICATION_NAME',
               'FABRIC_API_KEY': 'fabric.API_KEY',
               'FABRIC_BUILD_SECRET': 'fabric.BUILD_SECRET',
               'CRASHLYTICS_GROUPS': 'fabric.CRASHLYTICS_GROUPS',
               'DELIVER_USER': 'platforms.ios.DELIVER_USER',
               'DELIVER_PASSWORD': 'platforms.ios.DELIVER_PASSWORD'
               }
        for name, key in map.items():
            set_value(name, Config.get(key))
        set_value('BUILD_NUM', build_num)
        if build_mode != 'release':
            set_value('SIGH_AD_HOC', 'true')
            set_value('GYM_USE_LEGACY_BUILD_API', 'true')

    here = os.getcwd()
    os.chdir(platform_dir())
    try:
        environment_variables()
        shell.cmd('fastlane %s' % build_mode)
    finally:
        os.chdir(here)

def all():
    print('Building iOS')
    install()
    certs()
    fastfiles()
    fastlane(os.environ['BUILD_MODE'], os.environ['BUILD_NUM'])

if __name__ == "__main__":
    shell.on_root()
    Config.load()

    opt_parser = OptionParser('Usage: %prog [options] <install|certs|fastfiles|fastlane>')
    opt_parser.add_option('-o', '--overwrite-environment', help='overwrite environment variables', action="store_true", dest='env', default=False)
    opt_parser.add_option('-m', '--mode', help='release|beta|debug|test')
    opt_parser.add_option('-n', '--num', help='build number')
    options, args = opt_parser.parse_args()

    if len(args) < 1:
        sys.exit('No action is specified')
    action = args[0]

    if action == "install":
        install_android()
    elif action == "certs":
        certs()
    elif action == "fastfiles":
        fastfiles()
    elif action == "fastlane":
        if not options.mode:
            sys.exit('No build mode is specified')
        if not options.num:
            sys.exit('No build number is specified')
        fastlane(options.mode, options.num, options.env)
