#!/usr/bin/env python

import os
import sys

from config import Config
import android_build
import cordova_prepare
import dart
import ios_build

def platform_build():
    PLATFORM = os.environ['PLATFORM']
    platforms = {
                 'android': android_build,
                 'ios': ios_build
                 }
    platform = platforms.get(PLATFORM)
    if platform:
        platform.all()
    else:
        sys.exit("Unsupported platform: %s" % PLATFORM)

if __name__ == "__main__":
    Config.load()

    dart.all()
    cordova_prepare.all()
    platform_build()
