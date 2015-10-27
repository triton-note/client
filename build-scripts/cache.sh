#!/bin/bash
set -eu

action=$1
shift
folder=$1
shift

[ -z "$(type pip 2> /dev/null)" ] && sudo easy_install pip
[ -z "$(type aws 2> /dev/null)" ] && sudo pip install awscli --upgrade

export AWS_ACCESS_KEY_ID=$S3_CACHE_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$S3_CACHE_SECRET_KEY

load() {
	name=$1
	tarfile=${name}.tar.bz2
	echo "Syncing $name ..."
	aws s3 cp s3://cache-build/$folder/$tarfile $tarfile
	tar jxf $tarfile > /dev/null
	rm -f $tarfile
}

save() {
	name=$1
	tarfile=${name}.tar.bz2
	echo "Syncing $name ..."
	tar jcf $tarfile $name > /dev/null
	aws s3 cp $tarfile s3://cache-build/$folder/$tarfile
	rm -f $tarfile
}

if [ "$#" == 0 ]
then
	cat <<EOF | while read name; do $action $name; done
node_modules
EOF
else
	for name in $@; do $action $name; done
fi
