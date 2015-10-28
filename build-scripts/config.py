import json
import os

class Config:
    _SRC = None

    @classmethod
    def load(cls, path=None):
        if not path:
            path = os.path.join('build-scripts', 'persistent', 'config.json')
        file = open(path, mode='r')
        try:
            cls._SRC = json.load(file)
        finally:
            file.close()

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
