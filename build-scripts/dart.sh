#!/bin/bash
set -eu

cd dart

pub get
pub build
