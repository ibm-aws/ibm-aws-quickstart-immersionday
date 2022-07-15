#!/bin/bash
#==========================
# Loading Data to S3 Bucket
#==========================
function load_data_s3() {
  echo "******************* Loading Data to S3 *******************"
  export S3Bucket=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".S3Bucket")
  export S3BucketArn=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".S3BucketArn")
  export aws_secret_access_key=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".aws_secret_access_key")
  export aws_access_key_id=$(aws secretsmanager get-secret-value --secret-id S3ImmerssiondayBucketSecrets | jq -r ".SecretString" | jq -r ".aws_access_key_id")
  cd ..;aws s3 cp s3/data/ s3://$S3Bucket/ --recursive
}

#==========================
# Loading Data to RedShift
#==========================
function load_data_redshit() {
  echo "******************* Loading Data to RedShift *******************"
  export REDSHIFT_ENDPOINT=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftEndpoint")
  export REDSHIFT_PORT=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftPort")
  export REDSHIFT_USERNAME=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftMasterUsername")
  export REDSHIFT_PASSWORD=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftMasterPassword")
  export REDSHIFT_DBNAME=$(aws secretsmanager get-secret-value --secret-id RedshiftImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RedshiftDBName")
  # Call Fat Jar
  java -jar redshift-data-loading-prod.jar $REDSHIFT_ENDPOINT $REDSHIFT_PORT $REDSHIFT_DBNAME $REDSHIFT_USERNAME $REDSHIFT_PASSWORD
}

#====================
# Loading Data to RDS
#====================
function load_data_rds() {


  echo "******************* Installing Postgresql *******************"
sudo tee /etc/yum.repos.d/pgdg.repo<<EOF
[pgdg13]
name=PostgreSQL 13 for RHEL/CentOS 7 - x86_64
baseurl=https://download.postgresql.org/pub/repos/yum/13/redhat/rhel-7-x86_64
enabled=1
gpgcheck=0
EOF

  sudo yum update -y -q
  sudo yum install postgresql13 postgresql13-server -y -q
  sudo /usr/pgsql-13/bin/postgresql-13-setup initdb
  sudo systemctl enable --now postgresql-13


  echo "******************* Loading Data to RDS *******************"
  # retrieve rds details from secretmanager
  export PGENDPOINT=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSEndpoint")
  export PGPORT=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSPort")
  export PGUSERNAME=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSUserName")
  export PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSPassword")
  export PGDBNAME=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSDbname")

  # drop DB tables
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"CASES_AGESEX_refined\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"VACC_refined\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"flanders_cases_prediction_table\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"merged_pii_info_table\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"transaction\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_Belgium_agg\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_Flanders_agg\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_belgium_covid_statistics_table\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_regional_covid_statistics_table\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"vacc\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"HOSP_refined\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"account\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"healthcare_personnel_integrated_data_table\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"mort\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"MORT_refined\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"address\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"healthcare_personnel_integrated_data_table_v1\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"mylan_specialty_personnel_data_table\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts-data-region\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_Brussels\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"Merged_HOSP_CAS\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"credit_card\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"healthcare_personnel_integrated_datatable_v1\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"pii_info\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts-data-region_mod\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_Brussels_agg\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_Wallonia\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_brussels_region_table\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_regional_risk_index_table\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"Merged_VACC_MORT\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"TESTS_refined\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"data_country_level\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"merged_pii_data_source\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"test\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_Belgium\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_Flanders\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_Wallonia_agg\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_flanders_region_table\" cascade"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "drop table if exists \"public\".\"ts_wallonia_region_table\" cascade"

  # create tables

  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"CASES_AGESEX_refined\" (\"DATE\" character varying(1024), \"PROVINCE\" character varying(1024), \"REGION\" character varying(1024), \"AGEGROUP\" character varying(1024), \"SEX\" character varying(1024), \"CASES\" integer, \"RISK_INDEX\" integer)"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"HOSP_refined\" (\"DATE\" date, \"PROVIENCE\" character varying(1024), \"REGION\" character varying(1024), \"NR_REPORTING\" integer,\"TOTAL_IN\" integer,\"TOTAL_IN_ICU\" integer,\"TOTAL_IN_RESP\" integer,\"TOTAL_IN_ECMO\" integer,\"NEW_IN\" integer,\"NEW_OUT\" integer )"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"MORT_refined\" (\"DATE\" date, \"REGION\" character varying(1024), \"AGEGROUP\" character varying(1024), \"SEX\" character varying(1024), \"DEATHS\" integer )"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"Merged_HOSP_CAS\" (\"DATE\" date, \"PROVINCE\" character varying(1024), \"REGION\" character varying(1024), \"NR_REPORTING\" integer, \"TOTAL_IN\" integer, \"TOTAL_IN_ICU\" integer, \"TOTAL_IN_RESP\" integer, \"TOTAL_IN_ECMO\" integer, \"NEW_IN\" integer, \"NEW_OUT\" integer, \"AGEGROUP\" character varying(1024), \"SEX\" character varying(1024), \"CASES\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"Merged_VACC_MORT\" (\"DATE\" date, \"REGION\" character varying(1024), \"AGEGROUP\" character varying(1024), \"SEX\" character varying(1024), \"BRAND\" character varying(1024), \"DOSE\" character varying(1024), \"COUNT\" integer, \"DEATHS\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"TESTS_refined\" (\"DATE\" date, \"PROVINCE\" character varying(1024), \"REGION\" character varying(1024), \"TESTS_ALL\" integer, \"TESTS_ALL_POS\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"VACC_refined\" (\"DATE\" date, \"REGION\" character varying(1024), \"AGEGROUP\" character varying(1024), \"SEX\" character varying(1024), \"BRAND\" character varying(1024), \"DOSE\" character varying(1024), \"COUNT\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"account\" (\"id\" bigint NOT NULL, \"created_at\" bigint, \"last_modified\" bigint, \"account_number\" character varying(255), \"default_account\" boolean, \"user_name\" character varying(100), \"family_name\" character varying(100), \"given_name\" character varying(100), \"email\" character varying(30), \"phone_number\" character varying(20) ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"address\" (\"id\" bigint NOT NULL, \"created_at\" bigint, \"last_modified\" bigint, \"address_type\" character varying(20), \"city\" character varying(255), \"country\" character varying(255), \"state\" character varying(255), \"street1\" character varying(255), \"street2\" character varying(255), \"zip_code\" integer, \"account_id\" bigint ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"credit_card\" (\"id\" bigint NOT NULL, \"created_at\" bigint, \"last_modified\" bigint, \"number\" character varying(2000), \"type\" character varying(20), \"account_id\" bigint ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"data_country_level\" (\"DATE\" character varying(1024), \"Total_cases\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"flanders_cases_prediction_table\" (\"cases\" integer NOT NULL ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"healthcare_personnel_integrated_data_table\" (\"id\" integer NOT NULL, \"first_name\" character varying(50), \"last_name\" character varying(50), \"place\" character varying(50), \"email\" character varying(255), \"gender\" character varying(50), \"age\" integer, \"organization\" character varying(255) ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"healthcare_personnel_integrated_data_table\" (\"id\" integer NOT NULL, \"first_name\" character varying(50), \"last_name\" character varying(50), \"place\" character varying(50), \"email\" character varying(255), \"gender\" character varying(50), \"age\" integer, \"organization\" character varying(255) ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"healthcare_personnel_integrated_data_table_v1\" (\"id\" integer NOT NULL, \"first_name\" character varying(50), \"last_name\" character varying(50), \"place\" character varying(50), \"email\" character varying(255), \"gender\" character varying(50), \"age\" integer, \"organization\" character varying(255) ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"healthcare_personnel_integrated_datatable_v1\" (\"id\" integer, \"first_name\" character varying(50), \"last_name\" character varying(50), \"place\" character varying(50), \"email\" character varying(255), \"gender\" character varying(50), \"age\" integer, \"organization\" character varying(255) ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"merged_pii_data_source\" (\"id\" integer NOT NULL, \"first_name\" character varying(1024), \"last_name\" character varying(1024), \"email\" character varying(1024), \"gender\" character varying(1024), \"age\" integer, \"organization\" character varying(1024) ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"merged_pii_info_table\" (\"id\" character varying(1024), \"first_name\" character varying(1024), \"last_name\" character varying(1024), \"email\" character varying(1024), \"gender\" character varying(1024), \"age\" integer, \"Organization\" character varying(1024) ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"mort\" (\"DATE\" text, \"REGION\" text, \"AGEGROUP\" text, \"SEX\" text, \"DEATHS\" text ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"mylan_specialty_personnel_data_table\" (\"id\" integer NOT NULL, \"first_name\" character varying(50) NOT NULL, \"last_name\" character varying(50) NOT NULL, \"place\" character varying(50) NOT NULL, \"email\" character varying(100) NOT NULL, \"gender\" character varying(50) NOT NULL, \"age\" integer NOT NULL, \"organization\" character varying(255) NOT NULL ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"pii_info\" (\"id\" integer, \"first_name\" character varying(1024), \"last_name\" character varying(1024), \"place\" character varying(1024), \"email\" character varying(1024), \"gender\" character varying(1024), \"age\" integer, \"organization\" character varying(1024) ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"test\" (\"id\" bigint NOT NULL, \"account_number\" character varying(255) ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"transaction\" (\"id\" bigint NOT NULL, \"amount\" numeric(20,2) NOT NULL, \"type\" character varying(2) NOT NULL, \"cc_id\" bigint ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts-data-region\" (\"DATE\" character varying(1024), \"REGION\" character varying(1024), \"Total_cases\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts-data-region_mod\" (\"DATE\" date, \"REGION\" character varying(1024), \"Total_cases\" integer, \"Risk Index\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_Belgium\" (\"DATE\" date, \"Total_cases\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_Belgium_agg\" (\"DATE\" date, \"TOTAL_CASES_AGG\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_Brussels\" (\"DATE\" character varying(1024), \"REGION\" character varying(1024), \"Total_cases\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_Brussels_agg\" (\"DATE\" date, \"TOTAL_CASES_AGG\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_Flanders\" (\"DATE\" character varying(1024), \"REGION\" character varying(1024), \"Total_cases\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_Flanders_agg\" (\"DATE\" date, \"TOTAL_CASES_AGG\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_Wallonia\" (\"DATE\" character varying(1024), \"REGION\" character varying(1024), \"Total_cases\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_Wallonia_agg\" (\"DATE\" date, \"TOTAL_CASES_AGG\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_belgium_covid_statistics_table\" (\"date\" date NOT NULL, \"total_cases\" integer ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_brussels_region_table\" (\"date\" date NOT NULL, \"region\" character varying(30) NOT NULL, \"total_cases\" integer NOT NULL ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_flanders_region_table\" (\"date\" date NOT NULL, \"region\" character varying(30) NOT NULL, \"total_cases\" integer NOT NULL ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_regional_covid_statistics_table\" (\"date\" date NOT NULL, \"region\" character varying(30) NOT NULL, \"total_cases\" integer NOT NULL ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_regional_risk_index_table\" (\"date\" date NOT NULL, \"region\" character varying(30) NOT NULL, \"total_cases\" integer NOT NULL, \"risk_index\" integer NOT NULL ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"ts_wallonia_region_table\" (\"date\" date NOT NULL, \"region\" character varying(30) NOT NULL, \"total_cases\" integer NOT NULL ) "
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"vacc\" (\"DATE\" text, \"REGION\" text, \"AGEGROUP\" text, \"SEX\" text, \"BRAND\" text, \"DOSE\" text, \"COUNT\" text ) "
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"account\" ADD CONSTRAINT account_pkey PRIMARY KEY (\"id\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"address\" ADD CONSTRAINT address_pkey PRIMARY KEY (\"id\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"credit_card\" ADD CONSTRAINT credit_card_pkey PRIMARY KEY (\"id\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"flanders_cases_prediction_table\" ADD CONSTRAINT flanders_cases_prediction_table_pkey PRIMARY KEY (\"cases\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"mylan_specialty_personnel_data_table\" ADD CONSTRAINT pii_info_table_pkey PRIMARY KEY (\"id\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"test\" ADD CONSTRAINT test_pkey PRIMARY KEY (\"id\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"transaction\" ADD CONSTRAINT transaction_pkey PRIMARY KEY (\"id\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"ts_belgium_covid_statistics_table\" ADD CONSTRAINT ts_belgium_data_table_pkey PRIMARY KEY (\"date\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"ts_brussels_region_table\" ADD CONSTRAINT ts_brussels_data_table_pkey PRIMARY KEY (\"date\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"ts_flanders_region_table\" ADD CONSTRAINT ts_flanders_table_pkey PRIMARY KEY (\"date\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"ts_wallonia_region_table\" ADD CONSTRAINT ts_wallonia_table_pkey PRIMARY KEY (\"date\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"address\" ADD CONSTRAINT fk_address_account_id FOREIGN KEY (\"account_id\") REFERENCES public.account(\"id\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"credit_card\" ADD CONSTRAINT fk_credit_card_account_id FOREIGN KEY (\"account_id\") REFERENCES public.account(\"id\")" || true
  #psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"transaction\" ADD CONSTRAINT fk_transaction_credit_card_id FOREIGN KEY (\"cc_id\") REFERENCES public.credit_card(\"id\")" || true

  # download CSV to import to tables

  mkdir csv || true

  export GITHUBURL=https://github.com/ibm-aws/ibm-aws-quickstart-immersionday
  wget -q $GITHUBURL/raw/main/rds/csv/CASES_AGESEX_refined.csv -O ./csv/CASES_AGESEX_refined.csv
  wget -q $GITHUBURL/raw/main/rds/csv/HOSP_refined.csv -O ./csv/HOSP_refined.csv
  wget -q $GITHUBURL/raw/main/rds/csv/MORT_refined.csv -O ./csv/MORT_refined.csv
  wget -q $GITHUBURL/raw/main/rds/csv/Merged_HOSP_CAS.csv -O ./csv/Merged_HOSP_CAS.csv
  wget -q $GITHUBURL/raw/main/rds/csv/Merged_VACC_MORT.csv -O ./csv/Merged_VACC_MORT.csv
  wget -q $GITHUBURL/raw/main/rds/csv/TESTS_refined.csv -O ./csv/TESTS_refined.csv
  wget -q $GITHUBURL/raw/main/rds/csv/VACC_refined.csv -O ./csv/VACC_refined.csv
  wget -q $GITHUBURL/raw/main/rds/csv/account.csv -O ./csv/account.csv
  wget -q $GITHUBURL/raw/main/rds/csv/address.csv -O ./csv/address.csv
  wget -q $GITHUBURL/raw/main/rds/csv/credit_card.csv -O ./csv/credit_card.csv
  wget -q $GITHUBURL/raw/main/rds/csv/data_country_level.csv -O ./csv/data_country_level.csv
  wget -q $GITHUBURL/raw/main/rds/csv/flanders_cases_prediction_table.csv -O ./csv/flanders_cases_prediction_table.csv
  wget -q $GITHUBURL/raw/main/rds/csv/healthcare_personnel_integrated_data_table.csv -O ./csv/healthcare_personnel_integrated_data_table.csv
  wget -q $GITHUBURL/raw/main/rds/csv/healthcare_personnel_integrated_data_table_v1.csv -O ./csv/healthcare_personnel_integrated_data_table_v1.csv
  wget -q $GITHUBURL/raw/main/rds/csv/healthcare_personnel_integrated_datatable_v1.csv -O ./csv/healthcare_personnel_integrated_datatable_v1.csv
  wget -q $GITHUBURL/raw/main/rds/csv/merged_pii_data_source.csv -O ./csv/merged_pii_data_source.csv
  wget -q $GITHUBURL/raw/main/rds/csv/merged_pii_info_table.csv -O ./csv/merged_pii_info_table.csv
  wget -q $GITHUBURL/raw/main/rds/csv/mort.csv -O ./csv/mort.csv
  wget -q $GITHUBURL/raw/main/rds/csv/mylan_specialty_personnel_data_table.csv -O ./csv/mylan_specialty_personnel_data_table.csv
  wget -q $GITHUBURL/raw/main/rds/csv/pii_info.csv -O ./csv/pii_info.csv
  wget -q $GITHUBURL/raw/main/rds/csv/test.csv -O ./csv/test.csv
  wget -q $GITHUBURL/raw/main/rds/csv/transaction.csv -O ./csv/transaction.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts-data-region.csv -O ./csv/ts-data-region.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts-data-region_mod.csv -O ./csv/ts-data-region_mod.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_Belgium.csv -O ./csv/ts_Belgium.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_Belgium_agg.csv -O ./csv/ts_Belgium_agg.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_Brussels.csv -O ./csv/ts_Brussels.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_Brussels_agg.csv -O ./csv/ts_Brussels_agg.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_Flanders.csv -O ./csv/ts_Flanders.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_Flanders_agg.csv -O ./csv/ts_Flanders_agg.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_Wallonia.csv -O ./csv/ts_Wallonia.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_Wallonia_agg.csv -O ./csv/ts_Wallonia_agg.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_belgium_covid_statistics_table.csv -O ./csv/ts_belgium_covid_statistics_table.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_brussels_region_table.csv -O ./csv/ts_brussels_region_table.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_flanders_region_table.csv -O ./csv/ts_flanders_region_table.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_regional_covid_statistics_table.csv -O ./csv/ts_regional_covid_statistics_table.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts-data-region-RI.csv -O ./csv/ts-data-region-RI.csv
  wget -q $GITHUBURL/raw/main/rds/csv/ts_wallonia_region_table.csv -O ./csv/ts_wallonia_region_table.csv
  wget -q $GITHUBURL/raw/main/rds/csv/vacc.csv -O ./csv/vacc.csv


  # import CSV to datatable
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"CASES_AGESEX_refined\" from './csv/CASES_AGESEX_refined.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"HOSP_refined\" from './csv/HOSP_refined.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"MORT_refined\" from './csv/MORT_refined.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"Merged_HOSP_CAS\" from './csv/Merged_HOSP_CAS.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"Merged_VACC_MORT\" from './csv/Merged_VACC_MORT.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"TESTS_refined\" from './csv/TESTS_refined.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"VACC_refined\" from './csv/VACC_refined.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"account\" from './csv/account.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"address\" from './csv/address.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"credit_card\" from './csv/credit_card.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"data_country_level\" from './csv/data_country_level.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"flanders_cases_prediction_table\" from './csv/flanders_cases_prediction_table.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"healthcare_personnel_integrated_data_table\" from './csv/healthcare_personnel_integrated_data_table.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"healthcare_personnel_integrated_data_table_v1\" from './csv/healthcare_personnel_integrated_data_table_v1.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"healthcare_personnel_integrated_datatable_v1\" from './csv/healthcare_personnel_integrated_datatable_v1.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"merged_pii_data_source\" from './csv/merged_pii_data_source.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"merged_pii_info_table\" from './csv/merged_pii_info_table.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"mort\" from './csv/mort.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"mylan_specialty_personnel_data_table\" from './csv/mylan_specialty_personnel_data_table.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"pii_info\" from './csv/pii_info.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"test\" from './csv/test.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"transaction\" from './csv/transaction.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts-data-region\" from './csv/ts-data-region.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts-data-region_mod\" from './csv/ts-data-region_mod.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_Belgium\" from './csv/ts_Belgium.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_Belgium_agg\" from './csv/ts_Belgium_agg.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_Brussels\" from './csv/ts_Brussels.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_Brussels_agg\" from './csv/ts_Brussels_agg.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_Flanders\" from './csv/ts_Flanders.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_Flanders_agg\" from './csv/ts_Flanders_agg.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_Wallonia\" from './csv/ts_Wallonia.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_Wallonia_agg\" from './csv/ts_Wallonia_agg.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_belgium_covid_statistics_table\" from './csv/ts_belgium_covid_statistics_table.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_brussels_region_table\" from './csv/ts_brussels_region_table.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_flanders_region_table\" from './csv/ts_flanders_region_table.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_regional_covid_statistics_table\" from './csv/ts_regional_covid_statistics_table.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts-data-region-RI\" from './csv/ts-data-region-RI.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"ts_wallonia_region_table\" from './csv/ts_wallonia_region_table.csv' delimiter ',' CSV HEADER"
  psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "\COPY public.\"vacc\" from './csv/vacc.csv' delimiter ',' CSV HEADER"

  # remove csv folder
  rm -rf ./csv/ || true
}

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
  echo
  echo "*************************** End ****************************"
}

load_data_redshit
load_data_rds
load_data_s3
print_values
