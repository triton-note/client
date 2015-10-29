#!/usr/bin/env python

import os
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
    shell.mkdirs(os.path.dirname(filename))
    try:
        with open(filename, mode='wb') as file:
            file.write(obj.get()['Body'].read())
        with tarfile.open(mode='r:bz2', name=filename) as tar:
            tar.extractall()
    except botocore.exceptions.ClientError as e:
        if int(e.response['Error']['Code']) == 404:
            print(name, 'is not saved')
        else:
            raise
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
        error_code = int(e.response['Error']['Code'])
        print(name, 'is failed to save:', error_code)
    finally:
        os.remove(filename)

if __name__ == "__main__":
    shell.on_root(sys.argv[0])
    action = sys.argv[1]
    if len(sys.argv) < 3:
        list = ['node_modules']
    else:
        list = sys.argv[2:]

    print(action, list)
    for name in list:
        if action == "load":
            load(name)
        elif action == "save":
            save(name)
