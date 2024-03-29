#!/bin/bash

#========================
# Creating Users on CP4D
#========================
function create_users() {
  export route=$(oc get route -n zen-46 |awk 'NR==2 {printf $2}')
  # retrieve password
  oc extract secret/admin-user-details -n zen-46 --keys=initial_admin_password --to=- -n zen-46 > /tmp/out.txt
  export password=$(</tmp/out.txt)
  
  # retrieve the message code
  code=$(curl --silent  --output /dev/null --show-error --fail -w "%{http_code}\\n" -k -X POST https://$route/icp4d-api/v1/authorize -H 'cache-control: no-cache'     -H 'content-type: application/json' -d '{"username":"admin","password":"'"$password"'"}')
  
  if [ "$code" != "200" ]; then
        code=$(curl --silent  --output /dev/null --show-error --fail -w "%{http_code}\\n" -k -X POST https://$route/icp4d-api/v1/authorize -H 'cache-control: no-cache'     -H 'content-type: application/json' -d '{"username":"admin","password":"'"$password"'"}')
  fi

  if [ "$code" = "200" ]; then
    #Retrieve token
    export token=$(curl --silent --show-error --fail -k -X POST https://$route/icp4d-api/v1/authorize -H 'cache-control: no-cache'     -H 'content-type: application/json' -d '{"username":"admin","password":"'"$password"'"}' |  jq -r .token)

    export ram=$RANDOM
    curl --silent --output /dev/null --show-error -k -X POST -H "Authorization: Bearer $token" -H "cache-control: no-cache" -d "{\"user_name\":\"user$ram\",\"password\":\"password\",\"displayName\":\"User$ram\",\"permissions\":[\"administrator\",\"can_provision\"],\"user_roles\":[\"zen_administrator_role\"],\"email\":\"user$ram@user.com\"}" "https://$route/icp4d-api/v1/users" -H "Content-Type: application/json"

    curl --silent --output /dev/null --show-error -k -X POST -H "Authorization: Bearer $token" -H "cache-control: no-cache" -d "{\"user_name\":\"datascientist$ram\",\"password\":\"password\",\"displayName\":\"datascientist$ram\",\"permissions\":[\"sign_in_only\"],\"user_roles\":[\"zen_user_role\"],\"email\":\"datascientist@test.com\"}" "https://$route/icp4d-api/v1/users" -H "Content-Type: application/json"

    echo "Users created successfully."
    echo "Password for both user$ram and datascientist$ram is: password"

    echo "providing access to service instances"
    # Call Fat Jar
    java -jar cpd-api-automation_v4.jar "$route" "admin" "$password" "user$ram" "datascientist$ram"

  else
    echo "Error in CP4D Token extraction"
  fi
}

#Create Users
create_users
