#!/bin/bash
set -eu

action=$1
folder=$2

load() {
	brew install s3cmd

	cat <<EOF | s3cmd --configure
$S3_CACHE_ACCESS_KEY
$S3_CACHE_SECRET_KEY





n
y
EOF

	s3cmd get s3://cache-build/${folder}/node_modules.tar.bz2
	tar jxf node_modules.tar.bz2 > /dev/null
}

save() {
	tar jcf node_modules.tar.bz2 node_modules > /dev/null
	s3cmd put node_modules.tar.bz2 s3://cache-build/${folder}/node_modules.tar.bz2
}

$action
