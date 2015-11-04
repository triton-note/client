import os
import sys

def cmd(line):
    print('$ %s' % line)
    if os.system(line) != 0:
        sys.exit("Failed to execute: %s" % line)

def mkdirs(path):
    if path and not os.path.exists(path):
        os.makedirs(path)

def on_root():
    root = os.path.join(os.path.dirname(sys.argv[0]), '..')
    os.chdir(root)

def grep(target, pf=None):
    if os.path.exists(target):
        with open(target, mode='r') as file:
            lines = map(lambda a: a.rstrip(), file.readlines())
            if pf:
                lines = filter(pf, lines)
            return lines
    else:
        return []
