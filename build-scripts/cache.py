#!/usr/bin/env python

from multiprocessing import Pool
from optparse import OptionParser
import os
import re
import sys
import tarfile

import boto3
import botocore
import shell


def getObject(name):
    s3 = boto3.resource('s3')
    folder = os.environ['PROJECT_REPO_SLUG']
    bucket = s3.Bucket(os.environ['AWS_S3_BUCKET'])
    filename = name + '.tar.bz2'
    return (bucket.Object(folder + "/" + filename), filename)

def load(name):
    (obj, filename) = getObject(name)
    print('Loading', obj, 'to', filename)
    shell.mkdirs(os.path.join(os.path.dirname(filename), name))
    try:
        with open(filename, mode='wb') as file:
            file.write(obj.get()['Body'].read())
        with tarfile.open(mode='r:bz2', name=filename) as tar:
            tar.extractall()
    except botocore.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        print(name, 'is failed to load:', error_code)
    finally:
        os.remove(filename)

def save(name):
    (obj, filename) = getObject(name)
    print('Saving', filename, 'to', obj)
    try:
        with tarfile.open(mode='w:bz2', name=filename) as tar:
            tar.add(name)
        with open(filename, mode='rb') as file:
            obj.put(Body=file.read())
    except botocore.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        print(name, 'is failed to save:', error_code)
    finally:
        os.remove(filename)

if __name__ == "__main__":
    shell.on_root()

    opt_parser = OptionParser('Usage: %prog [options] <load|save> [dir...]')
    opt_parser.add_option('-p', '--profile', help='AWS profile')
    opt_parser.add_option('-b', '--bucket', help='S3 bucket name')
    opt_parser.add_option('-r', '--repo', help='project repository slug for github: <username|organization>/<project_name>')
    options, args = opt_parser.parse_args()

    if len(args) < 1:
        sys.exit('No action is directed')
    action = args[0]

    if len(args) > 1:
        names = args[1:]
    else:
        names = ['node_modules', '.pip_cache']

    def get_repo():
        url = shell.CMD('git', 'config', '--get', 'remote.origin.url').output()
        m = re.fullmatch('^http.*github\.com/([\w-]+/[\w-]+)\.git$', url)
        if m:
            return m.group(1)

    def set_env(name, value, otherwise=None):
        if not value and not os.environ.get(name):
            if otherwise:
                value = otherwise()
        if value:
            print('Setting environment variable: %s=%s' % (name, value))
            os.environ[name] = value

    set_env('AWS_S3_BUCKET', options.bucket, lambda: 'build-config')
    set_env('PROJECT_REPO_SLUG', options.repo, lambda: get_repo())
    set_env('AWS_PROFILE', options.profile)

    print(action, names)
    with Pool(processes=len(names)) as pool:
        if action == "load":
            pool.map(load, names)
        elif action == "save":
            pool.map(save, names)
