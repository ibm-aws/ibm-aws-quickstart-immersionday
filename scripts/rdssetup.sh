#!/bin/bash -xe

# retrieve rds details from secret ,anager
export PGENDPOINT=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSEndpoint")
export PGPORT=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSPort")
export PGUSERNAME=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSUserName")
export PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSPassword")
export PGDBNAME=$(aws secretsmanager get-secret-value --secret-id RDSImmerssiondaySecrets | jq -r ".SecretString" | jq -r ".RDSDbname")

# setup postgres client
sudo yum -y install postgresql13

# create tables
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

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "CREATE TABLE IF NOT EXISTS \"public\".\"healthcare_personnel_integrated_datatable_v1\" (\"id\" integer NOT NULL, \"first_name\" character varying(50), \"last_name\" character varying(50), \"place\" character varying(50), \"email\" character varying(255), \"gender\" character varying(50), \"age\" integer, \"organization\" character varying(255) ) "

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

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"account\" ADD CONSTRAINT account_pkey PRIMARY KEY (\"id\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"address\" ADD CONSTRAINT address_pkey PRIMARY KEY (\"id\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"credit_card\" ADD CONSTRAINT credit_card_pkey PRIMARY KEY (\"id\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"flanders_cases_prediction_table\" ADD CONSTRAINT flanders_cases_prediction_table_pkey PRIMARY KEY (\"cases\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"mylan_specialty_personnel_data_table\" ADD CONSTRAINT pii_info_table_pkey PRIMARY KEY (\"id\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"test\" ADD CONSTRAINT test_pkey PRIMARY KEY (\"id\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"transaction\" ADD CONSTRAINT transaction_pkey PRIMARY KEY (\"id\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"ts_belgium_covid_statistics_table\" ADD CONSTRAINT ts_belgium_data_table_pkey PRIMARY KEY (\"date\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"ts_brussels_region_table\" ADD CONSTRAINT ts_brussels_data_table_pkey PRIMARY KEY (\"date\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"ts_flanders_region_table\" ADD CONSTRAINT ts_flanders_table_pkey PRIMARY KEY (\"date\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"ts_wallonia_region_table\" ADD CONSTRAINT ts_wallonia_table_pkey PRIMARY KEY (\"date\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"address\" ADD CONSTRAINT fk_address_account_id FOREIGN KEY (\"account_id\") REFERENCES public.account(\"id\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"credit_card\" ADD CONSTRAINT fk_credit_card_account_id FOREIGN KEY (\"account_id\") REFERENCES public.account(\"id\")" || true

psql -h $PGENDPOINT -d $PGDBNAME -U $PGUSERNAME -c "ALTER TABLE ONLY \"public\".\"transaction\" ADD CONSTRAINT fk_transaction_credit_card_id FOREIGN KEY (\"cc_id\") REFERENCES public.credit_card(\"id\")" || true
