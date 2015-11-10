import os
import subprocess
import sys


class CMD:
    def __init__(self, *args):
        self.args = list(args)
        print('$ %s' % ' '.join(self.args))

    def call(self, *adding):
        self.args.extend(adding)
        subprocess.check_call(self.args)

    def output(self, *adding):
        self.args.extend(adding)
        return subprocess.check_output(self.args, universal_newlines=True).rstrip()

    def pipe(self, input, *adding):
        self.args.extend(adding)
        return subprocess.Popen(self.args, universal_newlines=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE).communicate(input=input)

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

def marker_log(title, content=None):
    c = '################'
    print()
    print('%s %s %s' % (c, title, c))
    if content:
        print(content)
        print(c)
        print()
