import os
import sys

def cmd(line):
    if os.system(line) != 0:
        sys.exit("Failed to execute: %s" % line)

def mkdirs(path):
    if path and not os.path.exists(path):
        os.makedirs(path)

def on_root(script_file):
    root = os.path.dirname(os.path.dirname(sys.argv[0]))
    if root:
        os.chdir(root)
