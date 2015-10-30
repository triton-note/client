#!/usr/bin/env python

from optparse import OptionParser
import os
import shutil
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

def cleanup():
    print('Clean Up')
    shutil.rmtree('plugins')
    shutil.rmtree('platforms')

def execute():
    shell.mkdirs('plugins')
    shell.cmd('cordova prepare %s' % os.environ['PLATFORM'])
    shell.cmd('ionic resources')

def all():
    environment_variables()
    execute()

if __name__ == "__main__":
    shell.on_root()
    Config.load()

    opt_parser = OptionParser()
    opt_parser.add_option('-e', '--env', help='set environment variables', action="store_true", dest='env', default=False)
    opt_parser.add_option('-c', '--cleanup', help='cleanup before execute', action="store_true", dest='cleanup', default=False)
    opt_parser.add_option('-d', '--dry-run', help='no execution', action="store_false", dest='execute', default=True)
    options, args = opt_parser.parse_args()

    if options.env:
        environment_variables()
    if options.cleanup:
        cleanup()
    if options.execute:
        execute()
