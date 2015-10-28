#!/usr/bin/env python

import os, sys, re
import yaml, lxml.html
from config import Config
import download_fonts

config = Config()

def write_settings():
    target = os.path.join('dart', 'web', 'settings.yaml')
    def loadYaml():
        file = open(target, mode='r')
        try:
            return yaml.load(file)
        finally:
            file.close()
    def saveYaml(info):
        file = open(target, mode='w')
        try:
            yaml.dump(info, file, default_flow_style=False)
        finally:
            file.close()

    info = loadYaml()
    for (name, key) in info.items():
        info[name] = config.get(key)
    saveYaml(info)
    print('Set', target)

class IndexHtml:
    def __init__(self):
        self.index = os.path.join('dart', 'web', 'index.html')
        self.dom = self.loadIndex()
        
    def loadIndex(self):
        file = open(self.index, mode='r')
        try:
            return lxml.html.fromstring(file.read())
        finally:
            file.close()
    def saveIndex(self, dom):
        file = open(self.index, mode='w')
        try:
            dom.dump(file)
        finally:
            file.close()

    def fonts(self):
        dir = os.path.join('dart', 'web', 'styles', 'fonts')
        p = re.compile('^https://fonts.googleapis.com/css\?.*$')
        for css in self.dom.xpath("//link[@rel='stylesheet']"):
            href = css.attrib['href']
            if p.match(href):
                name = download_fonts.download(href, dir)
                css.attrib['href'] = 'styles/fonts/' + name

    def js(self):
        print('Searching javascripts:', self.dom)
        
    def close(self):
        string = lxml.html.tostring(self.dom, include_meta_content_type = True)
        print('Writing', self.index, type(string))
        open(self.index, 'wb').write(string)

def all():
    write_settings()
    index = IndexHtml()
    index.fonts()
    index.js()
    index.close()

if __name__ == "__main__":
    action = sys.argv[1]
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
