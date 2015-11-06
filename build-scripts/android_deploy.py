from glob import glob
import importlib
import os
import sys

import pip

from config import BuildMode, Config
import shell


def googleplay(track_name):
    print('Deploying to Google Play:', track_name)

    def install_import(package, module):
        pip.main(['install', package])
        globals()[module] = importlib.import_module(module)

    install_import('google-api-python-client', 'apiclient')

    keyp12 = Config.file('android', 'service_account_key.p12')
    for apk in glob(os.path.join('build', 'outputs', 'apk', '*-release.apk')):
        print(apk)
    sys.exit('No implemention of deploy to Google Play')

def crashlytics():
    print('Deploying to Crashlytics')
    shell.CMD(os.path.join('.', 'gradlew'), 'crashlyticsUploadDistributionRelease').call()

def all():
    dir = os.path.join('platforms', 'android')
    map = {
           'release': 'production',
           'beta': 'beta'
           }
    track_name = map.get(BuildMode.NAME)

    here = os.getcwd()
    os.chdir(dir)
    try:
        if track_name:
            googleplay(track_name)
        else:
            crashlytics()
    finally:
        os.chdir(here)
