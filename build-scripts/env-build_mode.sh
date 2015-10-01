#!/bin/bash
set -eu

isMatch() {
	if [ -z "$(echo "$TRAVIS_BRANCH" | sed "s/$2//")" ]
	then
		echo "$1"
		exit 0
	fi
}

isInclude() {
	mode=$1
	shift
	for w in "$@"
	do
		isMatch "$mode" $w
	done
}

isInclude release $BRANCH_RELEASE
isInclude beta $BRANCH_BETA
isInclude debug $BRANCH_DEBUG

echo "test"
