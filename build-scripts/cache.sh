#!/bin/bash
set -eu

action=$1
folder=$2

brew install s3cmd

cat <<EOF | s3cmd --configure
$S3_CACHE_ACCESS_KEY
$S3_CACHE_SECRET_KEY




EOF

load() {
	s3cmd get s3://cache-build/${folder}/node_modules.tar.bz
	tar jxf node_modules.tar.bz
}

save() {
	tar jcf node_modules.tar.bz node_modules
	s3cmd put node_modules.tar.bz s3://cache-build/${folder}/node_modules.tar.bz
}

$action
