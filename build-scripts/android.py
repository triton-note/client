#!/usr/bin/env python

import json
import os
import subprocess
import sys

from config import Config
from lxml import etree
import shell

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
    target = os.path.join('platforms', 'android', 'build.json')
    with open(target, mode='w') as file:
        json.dump({'android': {'release': build}}, file, indent=4)

def build_num():
    num = os.environ['BUILD_NUM']
    print('Setting build_num', num)
    target = 'config.xml'
    with open(target, mode='rb') as file:
        elem = etree.fromstring(file.read())
    elem.attrib['android-versionCode'] = num
    with open(target, mode='wb') as file:
        file.write(etree.tostring(elem, encoding='utf-8', xml_declaration=True))

def build():
    mode = os.environ['BUILD_MODE']
    print('Building by cordova', mode)
    dir = os.path.join('platforms', 'android')
    multi = 'true'
    if mode != "release" and mode != "beta":
        multi = 'false'
    key = 'cdvBuildMultipleApks'
    target = os.path.join(dir, 'gradle.properties')
    def read_lines():
        if os.path.exists(target):
            with open(target, mode='r') as file:
                lines = file.readlines()
                lines = filter(lambda a: not key in a, lines)
                return map(lambda a: a.rstrip(), lines)
    lines = list(read_lines())
    lines.append('%s=%s' % (key, multi))
    with open(target, mode='w') as file:
        file.write('\n'.join(lines) + '\n')
    print('Add', target, ':', key, '=', multi)
    shell.cmd('cordova build android --release --buildConfig=%s' % os.path.join(dir, 'build.json'))

def deploy():
    import android_deploy
    android_deploy.all()

def all():
    print('Building Android')
    install_android()
    keystore()
    build_num()
    build()
    deploy()

if __name__ == "__main__":
    Config.load()

    action = sys.argv[1]
    if action == "install":
        install_android()
    elif action == "keystore":
        keystore()
    elif action == "build_num":
        build_num()
    elif action == "build":
        build()
    elif action == "deploy":
        deploy()
