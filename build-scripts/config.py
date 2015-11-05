import json
import os
import re
import sys

import shell


class BuildMode:
    @classmethod
    def init(cls, branch=None, mode_name=None):
        if not branch:
            branch = os.environ.get('GIT_BRANCH')
        if not branch:
            branch = shell.cmd('git', 'status').output().split('\n')[0].split()[-1]
        def making():
            map = {
                   'release': 'BRANCH_RELEASE',
                   'beta': 'BRANCH_BETA',
                   'debug': 'BRANCH_DEBUG'
                   }
            for name, key in map.items():
                if re.fullmatch(os.environ[key], branch):
                    return name
            return 'test'
        cls.BRANCH = branch
        if not mode_name:
            mode_name = making()
        cls.NAME = mode_name
        print('BuildMode(%s) on branch: %s' % (cls.NAME, cls.BRANCH))

    @classmethod
    def is_RELEASE(cls):
        return cls.NAME == 'release'
    @classmethod
    def is_BETA(cls):
        return cls.NAME == 'beta'
    @classmethod
    def is_DEBUG(cls):
        return cls.NAME == 'debug'
    @classmethod
    def is_TEST(cls):
        return cls.NAME == 'test'

class Config:
    _DIR = os.path.abspath(os.path.dirname(sys.argv[0]))
    _SRC = None
    PLATFORM = None
    BUILD_NUM = None

    @classmethod
    def init(cls, path=None, branch=None, build_mode=None, build_num=None, platform=None):
        if not build_num:
            build_num = os.environ['BUILD_NUM']
        cls.BUILD_NUM = build_num
        if not platform:
            platform = os.environ['PLATFORM']
        cls.PLATFORM = platform
        BuildMode.init(branch=branch, mode_name=build_mode)
        if not path:
            path = cls.file('config.json')
        with open(path, mode='r') as file:
            cls._SRC = json.load(file)

    @classmethod
    def script_file(cls, *paths):
        return os.path.join(cls._DIR, *paths)

    @classmethod
    def file(cls, *paths):
        return os.path.join(cls._DIR, 'persistent', *paths)

    @classmethod
    def get(cls, path):

        def getting(map, keyList):
            if len(keyList) < 1:
                return None
            elif len(keyList) == 1:
                value = map[keyList[0]]
                if isinstance(value, dict):
                    found = next((t for t in value.items() if BuildMode.NAME in t[0].split(' ')), None)
                    if found != None:
                        return found[1]
                    else:
                        return value.get('default', None)
                else:
                    return value
            else:
                return getting(map[keyList[0]], keyList[1:])
        return getting(cls._SRC, path.split('.'))
