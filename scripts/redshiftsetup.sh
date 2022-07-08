#!/bin/bash -xe

# retrieve redshift details from secretmanager

export REDSHIFT_ENDPOINT=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftEndpoint")
export REDSHIFT_PORT=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftPort")
export REDSHIFT_USERNAME=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftMasterUsername")
export REDSHIFT_PASSWORD=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftMasterPassword")
export REDSHIFT_DBNAME=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftDBName")


# Call Fat Jar
java -jar redshift-data-loading-prod.jar $REDSHIFT_ENDPOINT $REDSHIFT_PORT $REDSHIFT_DBNAME $REDSHIFT_USERNAME $REDSHIFT_PASSWORD
