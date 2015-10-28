import os, json, itertools

class Config:
    def __init__(self):
        path = os.path.join('build-scripts', 'persistent', 'config.json')
        file = open(path)
        try:
            self._src = json.load(file)
        finally:
            file.close()

    def get(self, path):
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
        return getting(self._src, path.split('.'))
