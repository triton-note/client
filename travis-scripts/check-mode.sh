#!/bin/bash
set -eu

isMatch() {
	m=$(echo "$TRAVIS_BRANCH" | sed "s/$1//")
	if [ -z "$m" ]
	then
		return 0
	else
		return 1
	fi
}

isInclude() {
	for w in "$@"
	do
		isMatch $w && return 0
	done
	return 1
}

DEBUG="false"
RELEASE="false"

isInclude $BRANCH_DEBUG && DEBUG="true"

if [ "$DEBUG" != "true" ]
then
	isInclude $BRANCH_RELEASE && RELEASE="true"
fi

export RELEASE=$RELEASE
export DEBUG=$DEBUG
