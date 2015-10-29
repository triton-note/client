#!/usr/bin/env python

import os
import sys

from config import Config
import android
import cordova_prepare
import dart
import ios
import shell

if __name__ == "__main__":
    shell.on_root(sys.argv[0])
    Config.load()

    dart.all()
    cordova_prepare.all()
    globals()[os.environ['PLATFORM']].all()
