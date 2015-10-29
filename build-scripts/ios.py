#!/usr/bin/env python

import os
import sys

from config import Config
import shell

def all():
    print('Building iOS')

if __name__ == "__main__":
    shell.on_root(sys.argv[0])
    Config.load()
