#!/usr/bin/env python

from optparse import OptionParser
import re
import subprocess
import sys

from build_mode import BuildMode
from config import Config
import shell


def _tags_list(mode=None):
    if not mode:
        mode = BuildMode().CURRENT
    tags = subprocess.getoutput('git tag -l').split('\n')
    regex = re.compile('deployed/%s/\w+' % mode)
    return list(filter(regex.match, tags))

def _recent_tag(mode=None):
    tags = _tags_list(mode)
    if tags:
        tags.sort(reverse=True)
        return tags[0]
    else:
        return None

def make(mode=None):
    arg = '-n1'
    tag = _recent_tag(mode)
    if tag:
        arg = '%s...HEAD' % tag
    return subprocess.getoutput("git log --format='%h %s' " + arg)

if __name__ == "__main__":
    shell.on_root()
    Config.load()

    opt_parser = OptionParser()
    opt_parser.add_option('-m', '--mode', help='build mode')
    options, args = opt_parser.parse_args()

    if not args:
        sys.exit('No action is directed')
    action = args[0]

    if action == 'make':
        print(make(options.mode))
    elif action == 'recent_tag':
        print(_recent_tag(options.mode))
    elif action == 'tags_list':
        print(_tags_list(options.mode))
