#!/usr/bin/env python

import os
import sys

from config import Config
import android
import cordova_prepare
import dart
import ios

if __name__ == "__main__":
    Config.load()

    dart.all()
    cordova_prepare.all()
    globals()[os.environ['PLATFORM']].all()
