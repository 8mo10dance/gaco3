#!/bin/bash

set -eux

BUCKET_NAME="microposts"

aws s3api create-bucket --bucket "$BUCKET_NAME"

# CarrierWave が public-read ACL を付けて保存する画像を、ブラウザから参照できるようにする。
aws s3api put-bucket-ownership-controls --bucket "$BUCKET_NAME" --ownership-controls '{
  "Rules": [{ "ObjectOwnership": "BucketOwnerPreferred" }]
}'
aws s3api put-public-access-block --bucket "$BUCKET_NAME" --public-access-block-configuration '{
  "BlockPublicAcls": false,
  "IgnorePublicAcls": false,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}'

aws s3api put-bucket-cors --bucket "$BUCKET_NAME" --cors-configuration '{
  "CORSRules": [
    {
      "AllowedMethods": ["PUT"],
      "AllowedOrigins": ["*"]
    }
  ]
}'
