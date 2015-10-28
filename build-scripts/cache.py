#!/usr/bin/env python

import os
import sys
import boto3
import tarfile
import io

def getObject(name):
    s3 = boto3.resource('s3')
    folder = os.environ['PROJECT_REPO_SLUG']
    bucket = s3.Bucket(os.environ['AWS_S3_BUCKET'])
    filename = name + '.tar.bz2'
    return (bucket.Object(folder + "/" + filename), filename)

def mkdirs(path):
    dir = os.path.dirname(path)
    if not os.path.exists(dir):
        os.makedirs(dir)

def load(name):
    (obj, filename) = getObject(name)
    if obj == None:
        print(name, 'is not saved')
    else:
        print('Loading', obj, 'to', filename)
        mkdirs(filename)
        file = open(filename, mode='wb')
        try:
            file.write(obj.get()['Body'].read())
            file.close()
            tar = tarfile.open(mode='r:bz2', name=filename)
            for member in tar.getmembers():
                if member.isfile():
                    mkdirs(member.name)
                    src = tar.extractfile(member)
                    dst = open(member.name, mode='wb')
                    dst.write(src.read())
                    dst.close()
        finally:
            file.close()
            os.remove(filename)

def save(name):
    (obj, filename) = getObject(name)
    print('Saving', filename, 'to', obj)
    tar = tarfile.open(mode='w:bz2', name=filename)
    tar.add(name)
    tar.close()
    file = open(filename, mode='rb')
    try:
        obj.put(Body=file.read())
    finally:
        file.close()
        os.remove(filename)

if __name__ == "__main__":
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
