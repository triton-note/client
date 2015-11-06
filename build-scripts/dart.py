#!/usr/bin/env python

from optparse import OptionParser
import hashlib
import os
import re
import sys
import urllib.request

from config import Config
import lxml.html
import shell
import yaml


def write_settings():
    target = os.path.join('web', 'settings.yaml')
    with open(target, mode='r') as file:
        info = yaml.load(file)
    for (name, key) in info.items():
        info[name] = Config.get(key)
    with open(target, mode='w') as file:
        yaml.dump(info, file, default_flow_style=False)
    print('Set', target)

def download(url, dir):
    def getExt(base):
        m = re.search('.*[^\w]([\w]+)$', base.split('?')[0])
        if m == None:
            return None
        else:
            return m.group(1)
    def uniqueName(base):
        m = hashlib.md5()
        m.update(base.encode('utf-8'))
        return 'cached-%s.%s' % (m.hexdigest(), getExt(base))
    name = uniqueName(url)
    target = os.path.join(dir, name)
    print('Downloading', url, 'to', target)
    shell.mkdirs(dir)
    urllib.request.urlretrieve(url, target)
    return name

class IndexHtml:
    def __init__(self):
        self.index = os.path.join('web', 'index.html')
        with open(self.index, mode='r') as file:
            self.dom = lxml.html.fromstring(file.read())

    def close(self):
        string = lxml.html.tostring(self.dom, include_meta_content_type=True, doctype='<!DOCTYPE html>')
        print('Writing', self.index)
        with open(self.index, 'wb') as file:
            file.write(string)

    def fonts(self):
        dir = os.path.join('web', 'styles', 'fonts')
        def modify(url):
            filename = download(url, dir)
            with open(os.path.join(dir, filename), mode='r+') as f:
                p = re.compile('(^.*url\()(https:[^\)]+)(\).*)')
                lines = f.readlines()
                f.seek(0)
                for line in lines:
                    m = p.match(line)
                    if m != None:
                        loaded = download(m.group(2), dir)
                        line = m.expand('\\1%s\\3' % loaded)
                    f.write(line)
                f.truncate()
            return filename
        p = re.compile('^https://fonts.googleapis.com/css\?.*$')
        for css in self.dom.xpath("//link[@rel='stylesheet']"):
            href = css.attrib['href']
            if p.match(href):
                css.attrib['href'] = 'styles/fonts/' + modify(href)

    def js(self):
        dir = os.path.join('web', 'js')
        p = re.compile('^https://.*\.js$')
        for elem in self.dom.xpath("//script[@type='text/javascript']"):
            href = elem.attrib['src']
            if p.match(href):
                elem.attrib['src'] = 'js/' + download(href, dir)

def build():
    shell.CMD('pub', 'get').call()
    shell.CMD('pub', 'build').call()

def all():
    shell.marker_log('Dart')
    os.chdir('dart')
    try:
        write_settings()
        index = IndexHtml()
        index.fonts()
        index.js()
        index.close()

        build()
    finally:
        os.chdir('..')

if __name__ == "__main__":
    shell.on_root()

    opt_parser = OptionParser('Usage: %prog [options] <settings|fonts|js|build>')
    opt_parser.add_option('-p', '--platform', help='android|ios')
    opt_parser.add_option('-b', '--branch', help="branch name")
    opt_parser.add_option('-m', '--mode', help="release|beta|debug|test")
    opt_parser.add_option('-n', '--num', help="build number")
    options, args = opt_parser.parse_args()

    if len(args) < 1:
        sys.exit('No action is specified')
    action = args[0]

    Config.init(branch=options.branch, build_mode=options.mode, build_num=options.num, platform=options.platform)

    os.chdir('dart')
    if action == 'settings':
        write_settings()
    elif action == 'fonts':
        index = IndexHtml()
        index.fonts()
        index.close()
    elif action == 'js':
        index = IndexHtml()
        index.js()
        index.close()
    elif action == 'build':
        build()
