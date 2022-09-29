#!/bin/bash

#===============================================
# Printing Crdentials for S3, RedShift, Postgres
#===============================================
function print_values() {
  echo
  echo "********************** S3 Information **********************"
  export region=$(aws configure get region)
  echo region=$region
  echo
  echo "********************** S3 Information **********************"
  export S3Bucket=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".S3Bucket")
  export S3BucketArn=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".S3BucketArn")
  export aws_secret_access_key=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".aws_secret_access_key")
  export aws_access_key_id=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".aws_access_key_id")
  echo S3Bucket=$S3Bucket
  echo S3BucketArn=$S3BucketArn
  echo Access_Key=$aws_secret_access_key
  echo Secret_key=$aws_access_key_id
  echo S3_endpoint="https://s3.$region.amazonaws.com"
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
  echo RedShift_Endpoint=$REDSHIFT_ENDPOINT
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
  echo "************** Sagemaker role arn Information **************"
  export SAGEMAKERROLEARN=$(aws iam get-role --role-name=SagemakerFullAccessRole | jq -r ".Role.Arn")
  echo SageMakerRole_Arn=$SAGEMAKERROLEARN
  export AWSSAGEMAKERSERVICEROLE=$(aws iam get-role --role-name=ServiceRoleForAmazonSageMakerNotebooks | jq -r ".Role.Arn")
  echo ServiceRoleForAmazonSageMakerNoteBook=$AWSSAGEMAKERSERVICEROLE
  echo
  echo "********************** SageMaker Information **********************"
  export SAGEMAKERSECRETACCESSKEY=$(aws secretsmanager get-secret-value --secret-id AdminUserCredentialSecret | jq -r ".SecretString" | jq -r ".admin_user_secret_access_key")
  export SAGEMAKERACCESSKEY=$(aws secretsmanager get-secret-value --secret-id AdminUserCredentialSecret | jq -r ".SecretString" | jq -r ".admin_user_access_key_id")
  echo SageMaker_Access_Key=$SAGEMAKERSECRETACCESSKEY
  echo SageMaker_Secret_key=$SAGEMAKERACCESSKEY
  echo
  echo "********************** Prediction API Information **********************"
  export PREDICTIONAPIURL=$(aws secretsmanager get-secret-value --secret-id PredictionApiSecret | jq -r ".SecretString" | jq -r ".PredictionApiUrl")
  echo PredictionApiUrl=$PREDICTIONAPIURL
  echo
  echo "*************************** End ****************************"
}

print_values
