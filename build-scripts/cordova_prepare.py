#!/usr/bin/env python

import os
import sys

from config import Config
import shell

def environment_variables():
    print('Setting environment variables')
    os.environ['FACEBOOK_APP_NAME'] = Config.get('APPLICATION_NAME')
    os.environ['FACEBOOK_APP_ID'] = Config.get('FACEBOOK_APP_ID')
    os.environ['FABRIC_API_KEY'] = Config.get('fabric.API_KEY')
    os.environ['FABRIC_BUILD_SECRET'] = Config.get('fabric.BUILD_SECRET')
    os.environ['CRASHLYTICS_GROUPS'] = Config.get('fabric.CRASHLYTICS_GROUPS')

def execute():
    print('Now on', os.getcwd())
    prefix = os.path.abspath('node_modules/.bin')
    shell.cmd('ls -la node_modules/.bin')
    shell.mkdirs('plugins')
    shell.cmd('%s/cordova prepare %s' % (prefix, os.environ['PLATFORM']))
    shell.cmd('%s/ionic resources' % prefix)

def all():
    environment_variables()
    execute()

if __name__ == "__main__":
    Config.load()
    if len(sys.argv) > 1:
        if sys.argv[1] == "env":
            environment_variables()
    execute()
