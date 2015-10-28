#!/usr/bin/env python

import os
import sys

from config import Config
import shell

def environment_variables():
    print('Setting environment variables')

def execute():
    shell.mkdirs('plugins')
    shell.cmd('cordova prepare %s' % os.enriron['PLATFORM'])
    shell.cmd('ionic resources')

def all():
    environment_variables()
    execute()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "env":
            environment_variables()
    execute()
