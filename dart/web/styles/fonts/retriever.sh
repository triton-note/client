#!/bin/bash

cd "$(dirname "$0")"

rm -vf *.css *.ttf

target="https://fonts.googleapis.com/css?family=Exo+2:100italic,600,200,300,400,800italic|Roboto+Mono:300"
css="google.css"

wget "$target" -O "$css"

cat "$css" | grep 'src:' | sed 's/.*url(\([^)]*\)).*/\1/' | while read url
do
    wget "$url"
done

cat "$css" | sed 's/\(^.*url(\).*\/\([^\/]*).*$\)/\1\2/' > "${css}.tmp"
diff "$css" "${css}.tmp"
mv -v "${css}.tmp" "$css"
