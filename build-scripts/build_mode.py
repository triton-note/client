#!/usr/bin/env python

from optparse import OptionParser
import os
import re
import subprocess


class BuildMode:
    def __init__(self, branch=None):
        if not branch:
            branch = os.environ.get('GIT_BRANCH')
        if not branch:
            branch = subprocess.getoutput("git status | head -n1 | awk '{print $NF}'")
        def making():
            map = {
                   'release': 'BRANCH_RELEASE',
                   'beta': 'BRANCH_BETA',
                   'debug': 'BRANCH_DEBUG'
                   }
            for name, key in map.items():
                if re.search(os.environ[key], branch):
                    return name
            return 'test'
        self.BRANCH = branch
        self.CURRENT = making()

    def is_RELEASE(self):
        return self.CURRENT == 'release'
    def is_BETA(self):
        return self.CURRENT == 'beta'
    def is_DEBUG(self):
        return self.CURRENT == 'debug'
    def is_TEST(self):
        return self.CURRENT == 'test'

if __name__ == "__main__":
    opt_parser = OptionParser()
    options, args = opt_parser.parse_args()

    if args:
        branch = args[0]
    else:
        branch = None

    mode = BuildMode(branch)
    print('branch=%s,  mode=%s' % (mode.BRANCH, mode.CURRENT))
