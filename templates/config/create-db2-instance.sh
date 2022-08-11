#!/bin/bash

#=================================================================
# Automation of DB2 Instance Creation
#=================================================================

#set -e

#=========================
# Retrive Port and Host
#=========================
function get_host_port() {

  export hostname=$(oc get po -o wide | grep c-$metadata-db2u-0 |  awk '{ printf $7 }')
  export nodeport=$(oc get svc c-$metadata-db2u-engn-svc -o=jsonpath="{.spec.ports[?(@.port==50000)].nodePort}")

  if [ "$hostname" ] && [ "$nodeport" ]; then
    echo "Host Name : $hostname"
    echo "Port Number: $nodeport"
  else 
    echo "Host and Port missing"

  fi
}

#=============================
# Execute cognos.sh script
#=============================
function run_cognos_config() {
  # Copying the db exection script and executing it
  oc cp cogconfig.sh c-$metadata-db2u-0:/tmp/
  oc exec c-$metadata-db2u-0 -- /bin/sh -c "/tmp/cogconfig.sh"
}


#==================================
# Platform Connections on CP4D.
#==================================
function create_cp4d_connection() {
  export route=$(oc get route |awk 'NR==2 {printf $2}')
  # retrieve password
  export password=$(oc get secrets/admin-user-details --template={{.data.initial_admin_password}} | base64 -d)
  # retrieve the message code
  code=$(curl --silent  --output /dev/null --show-error --fail -w "%{http_code}\\n" -k -X POST https://$route/icp4d-api/v1/authorize -H 'cache-control: no-cache'     -H 'content-type: application/json' -d '{"username":"admin","password":"'"$password"'"}')

  if [ "$code" = "200" ]; then
    #Retrieve token
    export token=$(curl --silent --show-error --fail -k -X POST https://$route/icp4d-api/v1/authorize -H 'cache-control: no-cache'     -H 'content-type: application/json' -d '{"username":"admin","password":"'"$password"'"}' |  jq -r .token)

    #Retrieve catalog id using above token
    export catalog=$(curl --silent --show-error --fail -k 'https://'"$route"'/v2/catalogs' -H "Authorization: Bearer $token" | jq -r .catalogs[0].metadata.guid)

    #Retrieve datasource type
    export datasource=$(curl --silent --show-error --fail -k 'https://'"$route"'/v2/datasource_types/db2' -H "Authorization: Bearer $token" | jq -r .metadata.asset_id)

    #Create connection using catalog id and token
    curl --silent --show-error --fail  -k 'https://'"$route"'/v2/connections?&catalog_id='"$catalog"'' -d '{ "datasource_type": "'$datasource'", "name":"cognoscs", "origin_country": "us",  "properties": { "host":"'"$hostname"'", "port":'"$nodeport"', "database":"'$database_name'", "password": "'$db_password'", "username": "db2inst1" } }' -H "Content-Type: application/json" -H "Authorization: Bearer $token"

    echo "CP4D connection created successfully."
  else
    echo "Error in CP4D Token extraction"
  fi
}


#=================================
# Check Instance Status
#=================================
function check_instance_status() {
  runtime="15 minute"
  endtime=$(date -ud "$runtime" +%s)

  while [[ $(date -u +%s) -le $endtime ]]
  do
    status=$(oc get Db2uCluster $metadata -o jsonpath="{.status.state}")
    echo 'Instance Status: ' $status
    if [ "$status" = "Ready" ]; then
        # get the host and port number
        get_host_port || exit 1
        # execute cognos-test.sh script
        run_cognos_config || exit 1
        # establish cp4d connection
        create_cp4d_connection || exit 1
        echo "Instance created Successfully"
        exit
    else
        echo "Waiting for the instance to get ready"
    fi
    sleep 30
  done

}


#===========================
# Create Instance
#===========================
function create_instance() {
  oc project zen
  export imagesecret=`oc get secret | grep db2u-dockercfg | awk '{ print $1 }'`
  #export imagesecret=`oc get secrets | grep db2u | grep dockercfg | awk '{print $1}'`
  export sc=$(oc get sc | grep cephfs | awk '{print $1}')

  echo $imagesecret
  echo $sc
  
  envsubst < db.yaml > db2.yaml
  oc create -f db2.yaml

  export metadata=$(awk '/metadata/{flag=1} flag && /name:/{printf $NF;flag=""}'  db2.yaml)
  export database_name=$(awk '/environment/{flag=1} flag && /database/{flag=1} flag && /name:/{printf $NF;flag=""}'  db2.yaml)
  export db_password=$(awk '/environment/{flag=1} flag && /instance/{flag=1} flag && /password:/{printf $NF;flag=""}'  db2.yaml)

  if [ $? -eq 0 ]; then
    # create db2 instance
    check_instance_status || exit 1
  else
    echo "Error in DB2 instance creation"
  fi
}

# create db2 instance
create_instance || exit 1