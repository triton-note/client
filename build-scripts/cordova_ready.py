#!/usr/bin/env python

from optparse import OptionParser
import os
import re
import shutil

from config import Config
import shell


def environment_variables(overwrite_environ=True):
    map = {
           'FACEBOOK_APP_NAME': 'APPLICATION_NAME',
           'FACEBOOK_APP_ID': 'FACEBOOK_APP_ID',
           'FABRIC_API_KEY': 'fabric.API_KEY',
           'FABRIC_BUILD_SECRET': 'fabric.BUILD_SECRET',
           'CRASHLYTICS_GROUPS': 'fabric.CRASHLYTICS_GROUPS'
           }
    for name, key in map.items():
        if not (os.environ.get(name) and not overwrite_environ):
            print('Setting environment variable:', name)
            os.environ[name] = Config.get(key)

def cleanup():
    print('Clean Up')
    for dir in ['plugins', 'platforms']:
        if os.path.exists(dir):
            shutil.rmtree(dir)

def cordova():
    shell.mkdirs('plugins')
    shell.CMD('cordova', 'platform', 'add', Config.PLATFORM).call()

    regex = re.compile('\${(\w+)}')
    plugins = [
               'cordova-plugin-crosswalk-webview@~1.3.1',
               'cordova-plugin-device@~1.0.1',
               'cordova-plugin-console@~1.0.1',
               'cordova-plugin-camera@~1.2.0',
               'cordova-plugin-splashscreen@~2.1.0',
               'cordova-plugin-statusbar@~1.0.1',
               'cordova-plugin-geolocation@~1.0.1',
               'cordova-plugin-whitelist@~1.0.0',
               'phonegap-plugin-push@~1.3.0',
               'https://github.com/sawatani/Cordova-plugin-file.git#GooglePhotos',
               'https://github.com/fathens/Cordova-Plugin-FBConnect.git#feature/ios APP_ID=${FACEBOOK_APP_ID} APP_NAME=${FACEBOOK_APP_NAME}',
               'https://github.com/fathens/Cordova-Plugin-Crashlytics.git API_KEY=${FABRIC_API_KEY}'
               ]
    for plugin in plugins:
        names = plugin.split()
        variables = []
        for line in names[1:]:
            key, value = line.split('=')
            m = regex.fullmatch(value)
            if m:
                value = os.environ[m.group(1)]
            variables.extend(['--variable', '%s=%s' % (key, value)])
        shell.CMD('cordova', 'plugin', 'add', names[0]).call(*variables)

def ionic():
    shell.CMD('ionic', 'resources').call()

def all():
    shell.marker_log('Cordova')
    environment_variables()
    cleanup()
    cordova()
    ionic()

if __name__ == "__main__":
    shell.on_root()

    opt_parser = OptionParser()
    opt_parser.add_option('-p', '--platform', help='android|ios')
    opt_parser.add_option('-b', '--branch', help="branch name")
    opt_parser.add_option('-m', '--mode', help="release|beta|debug|test")
    opt_parser.add_option('-n', '--num', help="build number")
    opt_parser.add_option('-o', '--overwrite-environment', help='overwrite environment variables', action="store_true", dest='env', default=False)
    opt_parser.add_option('-c', '--no-cleanup', help='do not cleanup before execute', action="store_false", dest='cleanup', default=True)
    opt_parser.add_option('-r', '--no-resources', help='do not create resources', action="store_false", dest='ionic', default=True)
    opt_parser.add_option('-d', '--no-build', help='do not run cordova prepare', action="store_false", dest='cordova', default=True)
    options, args = opt_parser.parse_args()

    Config.init(branch=options.branch, build_mode=options.mode, build_num=options.num, platform=options.platform)

    environment_variables(options.env)
    if options.cleanup:
        cleanup()

    if options.cordova:
        cordova()
    if options.ionic:
        ionic()
