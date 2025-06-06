#!/bin/bash

echo "InstanceId,Name,IMDS_Version" > ec2_imds_version.csv

aws ec2 describe-instances \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags,MetadataOptions.HttpTokens]' \
  --output json | jq -r '
  .[][] |
  {
    id: .[0],
    tags: (.[1] // []),
    token: .[2]
  } |
  .name = (.tags[]? | select(.Key == "Name") | .Value) // "N/A" |
  .version = (if .token == "required" then "IMDSv2" else "IMDSv1/v2" end) |
  "\(.id),\(.name),\(.version)"
' >> ec2_imds_version.csv
