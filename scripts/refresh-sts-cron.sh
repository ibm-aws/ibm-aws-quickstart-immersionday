#!/bin/sh

## command to run
## ./refresh-sts.sh /home/ec2-user/cloud-pak-deployer arn:aws:iam::481118440516:role/rhos-sts-role 2 10

sudo chown -R ec2-user:ec2-user /home/ec2-user/
export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin

export CLOUDPAKDIR=$1;
export ROLEARN=$2;
export LOGPATH=$3;

cat /dev/null > "$LOGPATH"

# set cloud pak dir
if [ -z $1 ]; then
   echo "cloud-pak-dir parameter 1 cannot be empty."
   exit 1;
fi

# set role-arn to be assumed
if [ -z $2 ]; then
   echo "role-arn parameter 2 cannot be empty."
   exit 1;
fi

#build deployer
/bin/bash $CLOUDPAKDIR/cp-deploy.sh build

out=$(aws sts assume-role --role-arn "$ROLEARN" --role-session-name OCPInstall)
echo "STS token....$out"

# set access key in vault
/bin/bash $CLOUDPAKDIR/cp-deploy.sh vault set --vault-secret aws-access-key --vault-secret-value $(echo "$out" | jq -r '.Credentials.AccessKeyId')

# set secret access key in vault
/bin/bash $CLOUDPAKDIR/cp-deploy.sh vault set --vault-secret aws-secret-access-key --vault-secret-value $(echo "$out" | jq -r '.Credentials.SecretAccessKey')

# set session token in vault
/bin/bash $CLOUDPAKDIR/cp-deploy.sh vault set --vault-secret aws-session-token --vault-secret-value $(echo "$out" | jq -r '.Credentials.SessionToken')