#!/usr/bin/env python

from optparse import OptionParser
import json
import os
import subprocess
import sys

from build_mode import BuildMode
from config import Config
from lxml import etree
import shell


def platform_dir(*paths):
    return os.path.join('platforms', 'android', *paths)

def install_android():
    os.system('brew install android')
    android_home = subprocess.getoutput('brew --prefix android')
    os.environ['ANDROID_HOME'] = android_home
    print('export ANDROID_HOME=%s' % android_home)

    names = [
             'platform-tools',
             'tools',
             'android-21',
             'android-22',
             'extra-google-m2repository',
             'extra-android-support',
             'extra-android-m2repository',
             'build-tools-21.1.2',
             'build-tools-22.0.1'
             ]
    for name in names:
        print('Installing', name)
        shell.cmd('echo y | android update sdk --no-ui --all --filter %s > /dev/null' % name)

def keystore():
    store = Config.file('android', 'keystore')
    print('Using keystore:', store)
    build = {
             'keystore': os.path.abspath(store),
             'storePassword': Config.get('platforms.android.keystore.PASSWORD'),
             'alias': Config.get('platforms.android.keystore.ALIAS'),
             'password': Config.get('platforms.android.keystore.ALIAS_PASSWORD')
             }
    target = platform_dir('build.json')
    with open(target, mode='w') as file:
        json.dump({'android': {'release': build}}, file, indent=4)

def build_num(num):
    num = '%s00' % num
    print('Setting build_num', num)
    target = 'config.xml'
    with open(target, mode='rb') as file:
        elem = etree.fromstring(file.read())
    elem.attrib['android-versionCode'] = num
    with open(target, mode='wb') as file:
        file.write(etree.tostring(elem, encoding='utf-8', xml_declaration=True))

def build():
    build_mode = BuildMode()
    print('Building by cordova', build_mode.CURRENT)
    multi = ('%s' % (build_mode.is_RELEASE() or build_mode.is_BETA)).lower()
    key = 'cdvBuildMultipleApks'
    target = platform_dir('gradle.properties')
    lines = shell.grep(target, lambda a: not key in a)
    with open(target, mode='w') as file:
        file.write('\n'.join(lines))
        file.write('\n%s=%s\n' % (key, multi))
    print('Add', target, ':', key, '=', multi)
    shell.cmd('cordova build android --release --buildConfig=%s' % platform_dir('build.json'))

def deploy():
    import android_deploy
    android_deploy.all()

def all():
    print('Building Android')
    install_android()
    keystore()
    build_num(os.environ['BUILD_NUM'])
    build()
    deploy()

if __name__ == "__main__":
    shell.on_root()
    Config.load()

    opt_parser = OptionParser('Usage: %prog [options] <install|keystore|build_num|build|deploy> [crashlytics|googleplay]')
    opt_parser.add_option('-n', '--num', help='build number')
    opt_parser.add_option('-t', '--track', help='release|beta (only for deploy googleplay)')
    options, args = opt_parser.parse_args()

    if len(args) < 1:
        sys.exit('No action is specified')
    action = args[0]

    if action == "install":
        install_android()
    elif action == "keystore":
        keystore()
    elif action == "build_num":
        if not options.num:
            sys.exit('No build number is specified')
        build_num(options.num)
    elif action == "build":
        if not options.mode:
            sys.exit('No build mode is specified')
        build(options.mode)
    elif action == "deploy":
        if len(args) < 2:
            sys.exit('No deploy target is specified')
        target = args[1]
        import android_deploy
        os.chdir(os.path.join('platforms', 'android'))
        if target == "googleplay":
            if not options.track:
                sys.exit('No track name is specified')
            android_deploy.googleplay(options.track)
        elif target == "crashlytics":
            android_deploy.crashlytics()
