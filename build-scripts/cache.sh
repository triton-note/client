#!/bin/bash
set -eu

action=$1
folder=$2
name=$3
tarfile=${name}.tar.bz2

setup() {
	brew install python
	sudo easy_install pip
	sudo pip install awscli --upgrade

	export AWS_ACCESS_KEY_ID=$S3_CACHE_ACCESS_KEY
	export AWS_SECRET_ACCESS_KEY=$S3_CACHE_SECRET_KEY
}

load() {
	aws s3 cp s3://cache-build/$folder/$tarfile $tarfile
	tar jxf $tarfile > /dev/null
}

save() {
	tar jcf $tarfile $name > /dev/null
	aws s3 cp $tarfile s3://cache-build/$folder/$tarfile
}

setup
$action
