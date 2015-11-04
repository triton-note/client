#!/bin/sh

echo "################################"
echo "# Start building"
echo "BUILD_NUM=$BUILD_NUM"
echo "PROJECT_REPO_SLUG=$PROJECT_REPO_SLUG"

install() {
    echo "################################"
    echo "# Install tools"
    
    pip install boto3
    build-scripts/cache.py load build-scripts/persistent
    build-scripts/cache.py load
    
    echo 'gem: --no-document' > $HOME/.gemrc
    
    pip install pyyaml lxml requests
    brew tap dart-lang/dart && brew install dart
    sudo gem install compass
    npm install
    export PATH="$PATH:$(pwd)/node_modules/.bin"
    
    build-scripts/cache.py save
}

build() {
    echo "################################"
    echo "# Building all"
    
    build-scripts/main.py
}

time install
time build
