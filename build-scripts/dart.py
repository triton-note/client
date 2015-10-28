import os
import yaml
from config import Config

config = Config()

def write_settings():
    target = os.path.join('dart', 'web', 'settings.yaml')
    def loadYaml():
        file = open(target, mode='r')
        try:
            return yaml.load(file)
        finally:
            file.close()
    def saveYaml(info):
        file = open(target, mode='w')
        try:
            yaml.dump(info, file, default_flow_style=False)
        finally:
            file.close()

    info = loadYaml()
    for (name, key) in info.items():
        info[name] = config.get(key)
    saveYaml(info)
    print('Set', target)


def all():
    write_settings()
