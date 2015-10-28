#!/bin/bash
set -eu

if [ -z "${PS1:-}" ]
then
    echo '0'
else
    echo '1'
fi
