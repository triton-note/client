#!/usr/bin/env python

import os
import re
import sys

from config import BuildMode, Config
from github import GitHub
import android
import cordova_prepare
import dart
import ios
import shell


if __name__ == "__main__":
    Config.init()
    GitHub.init()

    if GitHub.is_deployed():
        print('This is deployed tag')
    else:
        shell.on_root()

        note = GitHub.release_note()
        print('################ Release Note ################')
        print(note)
        print('################')
        target = Config.script_file('.release_note')
        with open(target, mode='w') as file:
            file.write(note + '\n')
        os.environ['RELEASE_NOTE_PATH'] = target

        dart.all()
        cordova_prepare.all()
        globals()[Config.PLATFORM].all()

        GitHub.put_tag()
