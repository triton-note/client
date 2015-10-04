#!/bin/bash
set -eu

cat <<EOF | while read name; do [ -z $(eval echo '${'$name':-}') ] || (echo 1; break); done
JENKINS_URL
TRAVIS
CIRCLECI
CI
EOF

