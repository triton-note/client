#!/usr/bin/env python

import os
import sys

from config import Config
import android
import cordova_prepare
import dart
import ios
import release_note
import shell


if __name__ == "__main__":
    shell.on_root()
    Config.load()

    dart.all()
    cordova_prepare.all()
    release_note.set_environ()
    globals()[os.environ['PLATFORM']].all()
