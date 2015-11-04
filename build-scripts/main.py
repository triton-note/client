#!/usr/bin/env python

import json
import os
import re
import sys

from config import Config
from github import GitHub
import android
import cordova_prepare
import dart
import ios
import shell


if __name__ == "__main__":
    print(sys.version)

    shell.on_root()
    Config.init()
    GitHub.init()

    os.environ['RELEASE_NOTE_PATH'] = GitHub.release_note(target=Config.script_file('.release_note'))

    dart.all()
    cordova_prepare.all()
    globals()[Config.PLATFORM].all()

    GitHub.put_tag()
