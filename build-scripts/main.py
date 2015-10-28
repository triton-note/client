#!/usr/bin/env python

from config import Config
import cordova_prepare
import dart

if __name__ == "__main__":
    Config.load()

    dart.all()
    cordova_prepare.all()
