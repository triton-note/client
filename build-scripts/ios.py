#!/usr/bin/env python

from optparse import OptionParser
import os
import shutil
import subprocess
import sys

from config import BuildMode, Config
import shell


def platform_dir(*paths):
    return os.path.join('platforms', 'ios', *paths)

def install():
    try:
        shell.CMD('gem', 'which', 'fastlane').output()
    except subprocess.CalledProcessError:
        shell.CMD('sudo', 'gem', 'install', 'fastlane').call()
    shell.CMD('cordova', 'prepare', 'ios').call()

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
    shutil.copy(Config.script_file('ios_Fastfile.rb'), os.path.join(dir, 'Fastfile'))

def fastlane(overwrite_environ=True):
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
        set_value('BUILD_NUM', Config.BUILD_NUM)
        if not (BuildMode.is_RELEASE() or BuildMode.is_BETA()):
            set_value('SIGH_AD_HOC', 'true')
            set_value('GYM_USE_LEGACY_BUILD_API', 'true')

    here = os.getcwd()
    os.chdir(platform_dir())
    try:
        environment_variables()
        shell.CMD('fastlane', BuildMode.NAME).call()
    finally:
        os.chdir(here)

def all():
    shell.marker_log('Building iOS')
    install()
    certs()
    fastfiles()
    fastlane()

if __name__ == "__main__":
    shell.on_root()

    opt_parser = OptionParser('Usage: %prog [options] <install|certs|fastfiles|fastlane>')
    opt_parser.add_option('-o', '--overwrite-environment', help='overwrite environment variables', action="store_true", dest='env', default=False)
    opt_parser.add_option('-b', '--branch', help="branch name")
    opt_parser.add_option('-m', '--mode', help="release|beta|debug|test")
    opt_parser.add_option('-n', '--num', help="build number")
    options, args = opt_parser.parse_args()

    Config.init(branch=options.branch, build_mode=options.mode, build_num=options.num, platform='ios')

    if len(args) < 1:
        all()
    else:
        action = args[0]
        if action == "install":
            install()
        elif action == "certs":
            certs()
        elif action == "fastfiles":
            fastfiles()
        elif action == "fastlane":
            fastlane(overwrite_environ=options.env)
