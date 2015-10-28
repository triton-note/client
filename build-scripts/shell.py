
def call(cmd):
    if os.system(cmd) != 0:
        sys.exit("Failed to execute: %s" % cmd)
