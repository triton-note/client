#!/usr/bin/env python

from optparse import OptionParser
import os
import re
import subprocess


class BuildMode:
    def __init__(self, branch=None, mode_name=None):
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
                if re.fullmatch(os.environ[key], branch):
                    return name
            return 'test'
        self.BRANCH = branch
        if mode_name:
            self.CURRENT = mode_name
        else:
            self.CURRENT = making()
        print('BuildMode(%s) on branch: %s' % (self.CURRENT, self.BRANCH))

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
    opt_parser.add_option('-b', '--branch', help='branch name')
    opt_parser.add_option('-m', '--mode', help='build mode')
    options, args = opt_parser.parse_args()

    mode = BuildMode(branch=options.branch, mode_name=options.mode)
    print('branch=%s,  mode=%s' % (mode.BRANCH, mode.CURRENT))
