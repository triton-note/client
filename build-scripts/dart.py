import os
import yaml
from config import Config

config = Config()

def mkdirs(path):
    dir = os.path.dirname(path)
    if not os.path.exists(dir):
        os.makedirs(dir)

def write_settings():
    target = os.path.join('dart', 'web', 'settings.yaml')
    mkdirs(target)
    file = open(target, mode='w')
    try:
        def put(name, key):
            value = config.get(key)
            file.write('%s: %s\n'%(name, value))
        put('awsRegion: ', 'aws.REGION')
        put('cognitoPoolId: ', 'aws.COGNITO_POOL_ID')
        put('s3Bucket: ', 'aws.S3_BUCKET')
    finally:
        file.close()

def all():
    write_settings()
