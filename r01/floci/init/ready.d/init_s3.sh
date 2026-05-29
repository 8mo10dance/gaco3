#!/bin/bash

set -eux

BUCKET_NAME="microposts"

aws s3api create-bucket --bucket "$BUCKET_NAME"
aws s3api put-bucket-cors --bucket "$BUCKET_NAME" --cors-configuration '{
  "CORSRules": [
    {
      "AllowedMethods": ["PUT"],
      "AllowedOrigins": ["*"]
    }
  ]
}'
