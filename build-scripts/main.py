#!/usr/bin/env python

import os
import sys

from config import BuildMode, Config
import android
import cordova_prepare
import dart
import ios
import release_note
import shell


class ReleaseNote:
    @classmethod
    def tags_list(cls):
        tags = subprocess.getoutput('git tag -l').split('\n')
        regex = re.compile('deployed/%s/\w+' % BuildMode.NAME)
        return list(filter(regex.match, tags))

    @classmethod
    def recent_tag(cls):
        tags = cls.tags_list()
        if tags:
            tags.sort(reverse=True)
            return tags[0]
        else:
            return None

    @classmethod
    def make(cls):
        arg = '-n1'
        tag = cls.recent_tag()
        if tag:
            arg = '%s...HEAD' % tag
        return subprocess.getoutput("git log --format='[%h] %s' " + arg)

    @classmethod
    def set_environ(cls, key='RELEASE_NOTE_PATH'):
        note = cls.make()
        print('################ Release Note ################')
        print(note)
        print('################')
        target = Config.script_file('.release_note')
        with open(target, mode='w') as file:
            file.write(note + '\n')
        os.environ[key] = target
        return target

if __name__ == "__main__":
    shell.on_root()
    Config.init()

    ReleaseNote.set_environ()
    dart.all()
    cordova_prepare.all()
    globals()[os.environ['PLATFORM']].all()
