#!/usr/bin/env python

import json
import os
import shutil
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
    store = os.path.join('build-scripts', 'persistent', 'keys', 'keystore')
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
        dom = etree.fromstring(file.read())
    print(target, dom)
    elem = dom
    print('widget', elem)
    elem.attrib['android-versionCode'] = num
    with open(target, mode='wb') as file:
        file.write(etree.tostring(dom, encoding='utf-8', xml_declaration=True))

def build():
    mode = os.environ['BUILD_MODE']
    print('Building by cordova', mode)
    dir = os.path.join('platforms', 'android')
    if mode != "release" and mode != "beta":
        target = os.path.join(dir, 'gradle.properties')
        with open(target, mode='a') as file:
            file.write("\ncdvBuildMultipleApks=false\n")
    shell.cmd('cordova build android --release --buildConfig=%s' % os.path.join(dir, 'build.json'))

def deploy():
    print('Deploying')

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
