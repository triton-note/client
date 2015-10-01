#!/bin/bash
set -eu

release_note="$(cd $(dirname $0); pwd)/release.note"

if [ -z "${1:-}" ]
then
	echo "Deploy from local PC" > "$release_note"
else
	git log --format=%B -n 1 $1 > "$release_note"
fi

echo "$release_note"
