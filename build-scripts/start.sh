#!/bin/sh

echo "################"
echo "# Start building"
echo "IS_CI=${IS_CI:-}"
echo "BUILD_NUM=$BUILD_NUM"
echo "BUILD_MODE=$BUILD_MODE"
echo "PROJECT_REPO_SLUG=$PROJECT_REPO_SLUG"
echo "RELEASE_NOTE_PATH=$RELEASE_NOTE_PATH"
echo "PLATFORM=$PLATFORM"

echo "################"
echo "# Using Python3"

brew update
brew install python3

[ -z "$(type pip 2> /dev/null)" ] && sudo easy_install pip
sudo pip install virtualenv

virtualenv --python=/usr/local/bin/python3 .v3
source .v3/bin/activate

pip install boto3 pyyaml lxml

echo "################"
echo "# Install tools"

build-scripts/cache.py load build-scripts/persistent
build-scripts/cache.py load

cat<<EOF > $HOME/.gemrc
gem: --no-document
EOF

brew tap dart-lang/dart && brew install dart
sudo gem install compass
npm install

build-scripts/cache.py save

#### Start building
build-scripts/main.py
