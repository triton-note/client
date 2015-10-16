#!/bin/bash

cd "$(dirname "$0")/../dart/web"

cat <<EOF > settings.yaml
awsRegion: $AWS_REGION
cognitoPoolId: $AWS_COGNITO_POOL_ID
s3Bucket: $AWS_S3_BUCKET
EOF
