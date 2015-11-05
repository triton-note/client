#!/usr/bin/env python

from optparse import OptionParser
import json
import os
import sys

from config import BuildMode, Config
from lxml import etree
import shell


def platform_dir(*paths):
    return os.path.join('platforms', 'android', *paths)

def install_android():
    shell.cmd('brew', 'install', 'android').call()
    android_home = shell.cmd('brew', '--prefix', 'android').output()
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
        (out, err) = shell.cmd('android', 'update', 'sdk', '--no-ui', '--all', '--filter', name).pipe('y')
        if out:
            lines = filter(lambda x: x.find('Installed') > -1, out.split('\n'))
            print('\n'.join(lines))
        if err:
            print('-- Stderr --')
            print(err)

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

def build_num():
    num = '%s00' % Config.BUILD_NUM
    print('Setting build_num', num)
    target = 'config.xml'
    with open(target, mode='rb') as file:
        elem = etree.fromstring(file.read())
    elem.attrib['android-versionCode'] = num
    with open(target, mode='wb') as file:
        file.write(etree.tostring(elem, encoding='utf-8', xml_declaration=True))

def build():
    shell.marker_log('Building by cordova %s' % BuildMode.NAME)
    multi = ('%s' % (BuildMode.is_RELEASE() or BuildMode.is_BETA())).lower()
    key = 'cdvBuildMultipleApks'
    target = platform_dir('gradle.properties')
    lines = shell.grep(target, lambda a: not key in a)
    with open(target, mode='w') as file:
        file.write('\n'.join(lines))
        file.write('\n%s=%s\n' % (key, multi))
    print('Add', target, ':', key, '=', multi)
    shell.cmd('cordova', 'build', 'android', '--release', '--buildConfig=%s' % platform_dir('build.json')).call()

def deploy():
    import android_deploy
    android_deploy.all()

def all():
    shell.marker_log('Building Android')
    install_android()
    keystore()
    build_num()
    build()
    deploy()

if __name__ == "__main__":
    shell.on_root()

    opt_parser = OptionParser('Usage: %prog [options] <install|keystore|build_num|build|deploy> [crashlytics|googleplay]')
    opt_parser.add_option('-b', '--branch', help="branch name")
    opt_parser.add_option('-m', '--mode', help="release|beta|debug|test")
    opt_parser.add_option('-n', '--num', help="build number")
    opt_parser.add_option('-t', '--track', help="release|beta (only for 'deploy googleplay')")
    options, args = opt_parser.parse_args()

    if len(args) < 1:
        sys.exit('No action is specified')
    action = args[0]

    Config.init(branch=options.branch, build_mode=options.mode, build_num=options.num, platform='android')

    if action == "install":
        install_android()
    elif action == "keystore":
        keystore()
    elif action == "build_num":
        build_num()
    elif action == "build":
        build()
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
