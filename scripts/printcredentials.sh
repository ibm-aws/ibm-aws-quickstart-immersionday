#!/bin/bash

#===============================================
# Printing Crdentials for S3, RedShift, Postgres
#===============================================
function print_values() {
  echo
  echo "********************** S3 Information **********************"
  export S3Bucket=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".S3Bucket")
  export S3BucketArn=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".S3BucketArn")
  export aws_secret_access_key=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".aws_secret_access_key")
  export aws_access_key_id=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".aws_access_key_id")

  echo S3Bucket=$S3Bucket
  echo S3BucketArn=$S3BucketArn
  echo Secret_Key=$aws_secret_access_key
  echo Access_key=$aws_access_key_id
  echo
  echo "******************* RedShift Information *******************"
  export REDSHIFT_ENDPOINT=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftEndpoint")
  export REDSHIFT_PORT=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftPort")
  export REDSHIFT_USERNAME=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftMasterUsername")
  export REDSHIFT_PASSWORD=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftMasterPassword")
  export REDSHIFT_DBNAME=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftDBName")

  echo RedShift_Username=$REDSHIFT_USERNAME
  echo RedShift_Password=$REDSHIFT_PASSWORD
  echo RedShift_Database_Name=$REDSHIFT_DBNAME
  echo RedShift_Port=$REDSHIFT_PORT
  echo REDSHIFT_Endpoint=$REDSHIFT_ENDPOINT
  echo
  echo "******************* Postgres Information *******************"
  # retrieve rds details from secretmanager
  export PGENDPOINT=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSEndpoint")
  export PGPORT=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSPort")
  export PGUSERNAME=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSUserName")
  export PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSPassword")
  export PGDBNAME=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSDbname")

  echo Postgres_Username=$PGUSERNAME
  echo Postgres_Password=$PGPASSWORD
  echo Postgres_Database_Name=$PGDBNAME
  echo Postgres_Port=$PGPORT
  echo Postgres_Endpoint=$PGENDPOINT
  echo
  echo "*************************** End ****************************"
}

print_values
