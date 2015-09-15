#!/bin/bash

cd $(dirname $0)

rm -vf *.js

wget https://raw.githack.com/aws/amazon-cognito-js/master/dist/amazon-cognito.min.js
wget https://raw.githack.com/mattiasw/ExifReader/master/js/ExifReader.js
wget https://sdk.amazonaws.com/js/aws-sdk-2.2.0.min.js
