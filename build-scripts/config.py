import json
import os

class Config:
    _DIR = os.path.join('build-scripts', 'persistent')
    _SRC = None

    @classmethod
    def file(cls, *paths):
        return os.path.join(cls._DIR, *paths)

    @classmethod
    def load(cls, path=None):
        if not path:
            path = cls.file('config.json')
        with open(path, mode='r') as file:
            cls._SRC = json.load(file)

    @classmethod
    def get(cls, path):
        def getting(map, keyList):
            if len(keyList) < 1:
                return None
            elif len(keyList) == 1:
                value = map[keyList[0]]
                if isinstance(value, dict):
                    found = next((t for t in value.items() if os.environ['BUILD_MODE'] in t[0].split(' ')), None)
                    if found != None:
                        return found[1]
                    else:
                        return value.get('default', None)
                else:
                    return value
            else:
                return getting(map[keyList[0]], keyList[1:])
        return getting(cls._SRC, path.split('.'))
