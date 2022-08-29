
## validate argument
if [ -z $1 ]; then
    echo "EKS clustername must be supplied as argument-1"
    exit 1;
fi

export CLUSTERNAME=$1
export APPFOLDERNAME=./"predictionapp"
export APPNAMESPACE="immersionday"
export LBPATTERN="risk-index"
export R53PARENTDOMAIN="ibmworkshops.com"
export R53RECORDNAME="risk-index-prediction-app.ibmworkshops.com"
export R53TTL=300
export R53REQUESTFILENAME="r53request.json"
export R53APIPUBLICURL="https://e1s28hehsd.execute-api.us-east-2.amazonaws.com/dev/route53/records/cname/add"

## create prdictionapp folder
rm -rf $APPFOLDERNAME
mkdir -p $APPFOLDERNAME
cd $APPFOLDERNAME

## checkout repo
wget https://github.com/ibm-aws/immersion-day-lab4-app/archive/refs/heads/main.zip
unzip ./main.zip

## login to EKS cluster
aws eks --region us-east-2 update-kubeconfig --name $CLUSTERNAME

## verify EKS login
if [ $? -ne 0 ];then
        echo "unable to login to cluster. please check clustername $CLUSTERNAME"
        exit 1;
fi

## deploy application
kubectl apply -f immersion-day-lab4-app-main/deploy.yaml -n $APPNAMESPACE

## Get LB url
export LBURL=$(kubectl get svc -n $APPNAMESPACE | grep $LBPATTERN | awk '{print $4}')
echo $LBURL

## prepare request json file
#export R53_REQUESTJSON=$(jq -n \
#                  --arg parentdomain "$R53PARENTDOMAIN" \
#                  --arg ttl "$R53TTL" \
#                  --arg recordName "$R53RECORDNAME" \
#                  --arg value "$LBURL" \
#                   '$ARGS.named')
export R53_REQUESTJSON='{"parentdomain":"'$R53PARENTDOMAIN'","ttl":"'$R53TTL'","recordName":"'$R53RECORDNAME'","value":"'$LBURL'"}'
echo $R53_REQUESTJSON
rm -f ./$R53REQUESTFILENAME
echo "$R53_REQUESTJSON" > $R53REQUESTFILENAME

## invoke API url 
curl -X POST -H "Content-Type: application/json" -d "@$R53REQUESTFILENAME" $R53APIPUBLICURL
