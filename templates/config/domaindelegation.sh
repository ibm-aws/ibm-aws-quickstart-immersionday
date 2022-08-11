# You have defined the "ibmworkshops.com" zone in Route53
# You want to create subdomain "${SUBDOMAIN}" and configure proper delegation form parent zone

SUBDOMAIN=$1

PARENTDOMAIN="ibmworkshops.com"
ADDNSRECURL="https://e1s28hehsd.execute-api.us-east-2.amazonaws.com/prod/route53/records/add"
TYPE="NS"
TTL="300"
ROUTINGPOLICY="simple"

if [ $PARENTDOMAIN == $SUBDOMAIN ]; then
  echo "Domain is already created. So, skipping domain creation process"
else
  echo "Creating DNS zone ${SUBDOMAIN}"

  aws route53 create-hosted-zone --output json \
    --name ${SUBDOMAIN} \
    --caller-reference "$(date)" \
    --hosted-zone-config="{\"Comment\": \"domain  ${SUBDOMAIN} is created for immersionday\", \"PrivateZone\": false}" | jq

  echo "Getting the NS servers from the new zone ${SUBDOMAIN}"

  NEW_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${SUBDOMAIN}.\`].Id" --output text)
  NEW_ZONE_NS1=$(aws route53 get-hosted-zone --output json --id ${NEW_ZONE_ID} --query "DelegationSet.NameServers" | jq -r '.[0]')
  NEW_ZONE_NS2=$(aws route53 get-hosted-zone --output json --id ${NEW_ZONE_ID} --query "DelegationSet.NameServers" | jq -r '.[1]')
  NEW_ZONE_NS3=$(aws route53 get-hosted-zone --output json --id ${NEW_ZONE_ID} --query "DelegationSet.NameServers" | jq -r '.[2]')
  NEW_ZONE_NS4=$(aws route53 get-hosted-zone --output json --id ${NEW_ZONE_ID} --query "DelegationSet.NameServers" | jq -r '.[3]')

  ADDNSREQUEST=$(cat <<EOF
        {
                "parentdomain":"$PARENTDOMAIN",
                "subdomain":"$SUBDOMAIN",
                "type":"$TYPE",
                "ttl":"$TTL",
                "routingPolicy":"$ROUTINGPOLICY",
                "ns1value":"$NEW_ZONE_NS1",
                "ns2value":"$NEW_ZONE_NS2",
                "ns3value":"$NEW_ZONE_NS3",
                "ns4value":"$NEW_ZONE_NS4"
        }
EOF)

curl --header "Content-Type: application/json" --request POST --data "$ADDNSREQUEST" "$ADDNSRECURL" | jq -r '.statusCodeValue'

fi
