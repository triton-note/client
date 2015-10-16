#!/bin/bash

cd "$(dirname "$0")"

rm -vf *.js

download() {
    url="$1"
    wget "$url"
    wget "${url}.map" || echo "No map: $url"
}

cat <<EOF | while read url; do download "$url"; done
https://raw.githack.com/aws/amazon-cognito-js/master/dist/amazon-cognito.min.js
https://raw.githack.com/mattiasw/ExifReader/master/js/ExifReader.js
https://sdk.amazonaws.com/js/aws-sdk-2.2.0.min.js
EOF
