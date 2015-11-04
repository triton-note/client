#!/usr/bin/env python

from optparse import OptionParser
import json
import os
import re
import subprocess
import sys

from config import BuildMode, Config
from lxml import etree
import requests
import shell


class GitHub:
    TAG_PREFIX = 'deployed'

    @classmethod
    def init(cls, repo=None, username=None, token=None):
        if not repo:
            repo = os.environ['PROJECT_REPO_SLUG']
        if not username:
            username = Config.get('github.USERNAME')
        if not token:
            token = Config.get('github.OAUTH_TOKEN')

        cls.repo = repo
        cls.username = username
        cls.token = token

    @classmethod
    def _post(cls, sub, data):
        url = 'https://api.github.com/repos/%s/%s' % (cls.repo, sub)
        return requests.post(url, json=data, auth=(cls.username, cls.token)).json()

    @classmethod
    def tags(cls):
        data = subprocess.getoutput("git tag -l").split('\n')
        regex = re.compile('%s/%s/%s/\w+' % (cls.TAG_PREFIX, Config.PLATFORM, BuildMode.NAME))
        tags = filter(regex.match, data)
        return sorted(tags, reverse=True)

    @classmethod
    def logs(cls, last):
        arg = '-n1'
        if last:
            arg = '%s...HEAD' % last
        return subprocess.getoutput("git log --format='[%h] %s' " + arg)

    @classmethod
    def release_note(cls, last=None):
        if not last:
            tags = cls.tags()
            if tags:
                last = tags[0]
        return cls.logs(last)

    @classmethod
    def put_tag(cls):
        sha = subprocess.getoutput("git log --format='%H' -n1")
        tag_name = '/'.join([cls.TAG_PREFIX, Config.PLATFORM, BuildMode.NAME, Config.BUILD_NUM])
        return cls._post('git/refs', {'ref': 'refs/tags/%s' % tag_name, 'sha': sha})

if __name__ == "__main__":
    opt_parser = OptionParser('Usage: %prog [options] <install|keystore|build_num|build|deploy> [release_note|tag]')
    opt_parser.add_option('-p', '--platform')
    opt_parser.add_option('-u', '--username', help="GitHub username")
    opt_parser.add_option('-t', '--token', help="GitHub OAuth Token")
    opt_parser.add_option('-b', '--branch', help="branch name")
    opt_parser.add_option('-r', '--repo', help='project repository slug for github: <username|organization>/<project_name>')
    opt_parser.add_option('-m', '--mode', help="release|beta|debug|test")
    opt_parser.add_option('-n', '--num', help="build number")
    opt_parser.add_option('-c', '--commit', help="last commit sha")
    opt_parser.add_option('-l', '--list', help="list tags", action='store_true', default=False)
    options, args = opt_parser.parse_args()

    if len(args) < 1:
        sys.exit('No action is specified')
    action = args[0]

    Config.init(branch=options.branch, build_mode=options.mode, build_num=options.num, platform=options.platform)
    GitHub.init(repo=options.repo, username=options.username, token=options.token)

    if action == 'release_note':
        print(GitHub.release_note(options.commit))
    elif action == 'tag':
        if options.list:
            result = GitHub.tags()
        elif options.num:
            result = GitHub.put_tag()
        print(json.dumps(result, indent=4))
