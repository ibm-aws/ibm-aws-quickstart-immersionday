#!/bin/bash

#========================
# Creating Users on CP4D
#========================
function create_users() {
  export route=$(oc get route -n zen |awk 'NR==2 {printf $2}')
  # retrieve password
  oc extract secret/admin-user-details --keys=initial_admin_password --to=- -n zen > /tmp/out.txt
  export password=$(</tmp/out.txt)
  #export password=$(oc get secrets/admin-user-details --template={{.data.initial_admin_password}} -n zen | base64 -d)

  # retrieve the message code
  code=$(curl --silent  --output /dev/null --show-error --fail -w "%{http_code}\\n" -k -X POST https://$route/icp4d-api/v1/authorize -H 'cache-control: no-cache'     -H 'content-type: application/json' -d '{"username":"admin","password":"'"$password"'"}')

  if [ "$code" = "200" ]; then
    #Retrieve token
    export token=$(curl --silent --show-error --fail -k -X POST https://$route/icp4d-api/v1/authorize -H 'cache-control: no-cache'     -H 'content-type: application/json' -d '{"username":"admin","password":"'"$password"'"}' |  jq -r .token)

    export ram=$RANDOM
    curl -k -X POST -H "Authorization: Bearer $token" -H "cache-control: no-cache" -d "{\"user_name\":\"user$ram\",\"password\":\"password\",\"displayName\":\"User$ram\",\"permissions\":[\"administrator\",\"can_provision\"],\"user_roles\":[\"zen_administrator_role\"],\"email\":\"user$ram@user.com\"}" "https://$route/icp4d-api/v1/users" -H "Content-Type: application/json"

    curl -k -X POST -H "Authorization: Bearer $token" -H "cache-control: no-cache" -d "{\"user_name\":\"datascientist$ram\",\"password\":\"password\",\"displayName\":\"datascientist$ram\",\"permissions\":[\"sign_in_only\"],\"user_roles\":[\"zen_user_role\"],\"email\":\"datascientist@test.com\"}" "https://$route/icp4d-api/v1/users" -H "Content-Type: application/json"

    echo "Users created successfully."
    echo "Password for both user$ram and datascientist$ram is: password"

    export user_id=$(curl -k -s "https://$route/usermgmt/v1/user/user$ram" -H "authorization: Bearer $token" -H "Content-Type: application/json" | jq -r .uid)

    curl -s -k -X GET "https://$route/zen-data/v3/service_instances?fetch_all_instances=true" -H "Authorization: Bearer $token" | jq -r '.service_instances[] | .id' > /tmp/id.txt

    while read line
    do
        echo "Granting Permissions to $line Instance"
    	curl -k -X POST "https://$route/zen-data/v2/serviceInstance/users/" -H "authorization: Bearer $token" -H "Content-Type: application/json" -d "{ \"serviceInstanceID\": \"$line\", \"users\": [{ \"role\": \"Admin\", \"uid\": \"$user_id\", \"username\": \"user$ram\" }] }"
    done < /tmp/id.txt

  else
    echo "Error in CP4D Token extraction"
  fi
}

#Create Users
create_users
