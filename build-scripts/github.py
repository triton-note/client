#!/usr/bin/env python

from optparse import OptionParser
import json
import os
import re
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
    def _url(cls, sub, proc):
        url = 'https://%s:%s@api.github.com/repos/%s/%s' % (cls.username, cls.token, cls.repo, sub)
        return proc(url).json()

    @classmethod
    def _get(cls, sub, params=None):
        return cls._url(sub, lambda x: requests.get(x, params=params))

    @classmethod
    def _post(cls, sub, data):
        return cls._url(sub, lambda x: requests.post(x, data=json.dumps(data)))

    @classmethod
    def current_sha(cls):
        data = cls._get('branches/%s' % BuildMode.BRANCH)
        return data['commit']['sha']

    @classmethod
    def tags(cls):
        data = cls._get('tags')
        regex = re.compile('%s/%s/%s/\w+' % (cls.TAG_PREFIX, Config.PLATFORM, BuildMode.NAME))
        tags = filter(lambda x: regex.match(x['name']), data)
        return sorted(tags, key=lambda x: x['name'], reverse=True)

    @classmethod
    def logs(cls, last_sha):
        merge = re.compile("Merge branch '.+' into develop")
        def date(sha):
            data = cls._get('commits/%s' % sha)
            return data['commit']['author']['date']
        def line(data):
            title = data['commit']['message'].split('\n')[0]
            if merge.match(title):
                return None
            else:
                return '[%s] %s' % (data['sha'][:7], title)

        data = cls._get('commits', params={'sha': cls.current_sha(), 'since': date(last_sha)})
        return list(filter(lambda x: x != None, map(line, data)))[:-1]

    @classmethod
    def release_note(cls, last_sha=None):
        if not last_sha:
            tags = cls.tags()
            if tags:
                last_sha = tags[0]['commit']['sha']
            else:
                last_sha = None
        return '\n'.join(cls.logs(last_sha))

    @classmethod
    def put_tag(cls):
        tag_name = '/'.join([cls.TAG_PREFIX, Config.PLATFORM, BuildMode.NAME, Config.BUILD_NUM])
        return cls._post('git/refs', {'ref': 'refs/tags/%s' % tag_name, 'sha': cls.current_sha()})

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
