#!/usr/bin/env python

from optparse import OptionParser
import json
import os
import re
import sys

from config import BuildMode, Config
import requests
import shell


class GitHub:
    TAG_PREFIX = 'deployed'

    class CommitObj:
        def __init__(self, name):
            self.name = name

        def _log(self, format):
            return shell.cmd('git', 'log', self.name, '-n1', "--format=%s" % format).output()

        def sha(self):
            return self._log('%H')

        def parents(self):
            vs = self._log('%P').split()
            return map(lambda x: GitHub.CommitObj(x), vs)

        def timestamp(self):
            v = self._log('%at')
            return int(v)

        def oneline(self):
            return self._log('[%h] %s').strip()

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
        data = shell.cmd('git', 'tag', '-l').output().split('\n')
        regex = re.compile('%s/%s/%s/\w+' % (cls.TAG_PREFIX, Config.PLATFORM, BuildMode.NAME))
        tags = filter(regex.match, data)
        return sorted(tags, reverse=True)

    @classmethod
    def release_note(cls, last=None, target=None):
        if not last:
            tags = cls.tags()
            if tags:
                last = tags[0]
        if last:
            last_sha = GitHub.CommitObj(last).sha()
            obj = GitHub.CommitObj('HEAD')
            lines = []
            while obj and obj.sha() != last_sha:
                parents = sorted(obj.parents(), key=lambda x: x.timestamp(), reverse=True)
                if len(parents) < 2:
                    lines.append(obj.oneline())
                obj = next(iter(parents), None)
            note = '\n'.join(lines)
        else:
            note = shell.cmd('git', 'log', "--format='[%h] %s'", '-n1').output()
        shell.marker_log('Release Note', note)
        if target:
            with open(target, mode='w') as file:
                file.write(note + '\n')
            return target
        else:
            return note

    @classmethod
    def put_tag(cls):
        shell.marker_log('Tagging')
        sha = shell.cmd('git', 'log', "--format='%H'", '-n1').output()
        tag_name = '/'.join([cls.TAG_PREFIX, Config.PLATFORM, BuildMode.NAME, Config.BUILD_NUM])
        res = cls._post('git/refs', {'ref': 'refs/tags/%s' % tag_name, 'sha': sha})
        print(json.dumps(res, indent=4))

if __name__ == "__main__":
    opt_parser = OptionParser('Usage: %prog [options] <install|keystore|build_num|build|deploy> [release_note|tag]')
    opt_parser.add_option('-p', '--platform', help='android|ios')
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
        print(GitHub.release_note(last=options.commit))
    elif action == 'tag':
        if options.list:
            print(GitHub.tags())
        elif options.num:
            GitHub.put_tag()
