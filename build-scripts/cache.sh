#!/bin/bash
set -eu

action=$1
folder=$2
name=$3

setup() {
	sudo pip install awscli --upgrade

	export AWS_ACCESS_KEY_ID=$S3_CACHE_ACCESS_KEY
	export AWS_SECRET_ACCESS_KEY=$S3_CACHE_SECRET_KEY
}

load() {
	mkdir -vp $name
	aws s3 sync s3://cache-build/$folder/$name $name --delete
}

save() {
	aws s3 sync $name s3://cache-build/$folder/$name --delete
}

setup
$action
