#!/bin/bash -xe

# retrieve rds details from secretmanager

export S3Bucket=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".S3Bucket")
export S3BucketArn=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".S3BucketArn")
export aws_secret_access_key=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".aws_secret_access_key")
export aws_access_key_id=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".aws_access_key_id")

cd ..;aws s3 cp s3/data/ s3://$S3Bucket/ --recursive
