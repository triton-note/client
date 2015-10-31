#!/usr/bin/env python

import os
import re
import subprocess
import sys

from config import BuildMode, Config
import android
import cordova_prepare
import dart
import ios
import shell


class ReleaseNote:
    TAG_PREFIX = 'deployed'

    @classmethod
    def tags_list(cls):
        tags = subprocess.getoutput('git tag -l').split('\n')
        regex = re.compile('%s/%s/%s/\w+' % (cls.TAG_PREFIX, Config.PLATFORM, BuildMode.NAME))
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

    @classmethod
    def put_tag(cls, build_num=None):
        if not build_num:
            build_num = os.environ['BUILD_NUM']
        tag_name = '/'.join([cls.TAG_PREFIX, Config.PLATFORM, BuildMode.NAME, build_num])
        shell.cmd('git tag %s' % tag_name)
        shell.cmd('git push --tags')

if __name__ == "__main__":
    shell.on_root()
    Config.init()

    ReleaseNote.set_environ()

    dart.all()
    cordova_prepare.all()
    globals()[Config.PLATFORM].all()

    ReleaseNote.put_tag()
