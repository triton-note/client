#!/usr/bin/env python

import os, sys, re, crypt
import urllib.request

def download(url, dir):
    if not os.path.exists(dir):
        os.makedirs(dir)
    filename = '%s.css'% crypt.crypt(url)
    css = os.path.join(dir, filename)
    print('Downloading', url, 'to', css)
    urllib.request.urlretrieve(url, css)
    def readLines():
        f = open(css, mode='r')
        try:
            return f.readlines()
        finally:
            f.close()
    lines = readLines()
    f = open(css, mode='w')
    try:
        p = re.compile('(^.*url\()(https:[^\)]+)(\).*)')
        for line in lines:
            m = p.match(line)
            if m != None:
                src = m.group(2)
                name = os.path.basename(src)
                urllib.request.urlretrieve(src, os.path.join(dir, name))
                line = m.expand('\\1%s\\3' % name)
            f.write(line)
    finally:
        f.close()
    return filename

if __name__ == "__main__":
    url = sys.argv[1]
    dir = sys.argv[2]
    download(url, dir)
