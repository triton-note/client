#!/bin/bash
set -eu

release_note="$(cd $(dirname $0); pwd)/.release_note"

range="${2:-}"

if [ -z "${1:-}" ]
then
	echo "Deploy from local PC" > "$release_note"
else
	url="$(git config --get remote.origin.url)"
	git log --format=%B -n 1 $1 > "$release_note"
	[ -z "${range:-}" ] || echo "${url%%.git}/compare/$range" >> "$release_note"
fi

echo "$release_note"
