#!/bin/bash
set -e

# validate cmd options
function validate_cmd_options() {
    if [[ $operation == "create" ]]; then
        
        # validate subnets
        if [ -z $subnets ]; then
            echo "subnets cannot be blank or empty"
            echo "Please maintain subents logical orders with separated comma(,). All private subnets first followed by public subents"
            echo "i.e. private-subnet-zone-a,private-subnet-zone-b,private-subnet-zone-c,public-subent-zone-a,public-subent-zone-b,public-subent-zone-c"
            exit 1;
        fi

        # validate cluster_url
        if [ -z $cluster_url ]; then
            echo "cluster_url cannot be blank or empty"
            exit 1;
        fi

        # validate cluster_url
        if [ -z $cluster_username ]; then
            echo "cluster_username cannot be blank or empty"
            exit 1;
        fi

        # validate cluster_url
        if [ -z $cluster_password ]; then
            echo "cluster_password cannot be blank or empty"
            exit 1;
        fi

        # validate region
        if [ -z $region ]; then
            echo "AWS region cannot be blank or empty"
            exit 1;
        fi
    fi

    # validate info_path
    if [ -z $info_path ]; then
        echo ".info file path cannot be blank or empty"
        exit 1;
    fi

    echo "***** All arguments are validated *****"
}

function destroy_efs() {
  storage=$(cat "$info_path" | grep -oE -- 'storage ([^ ]+)' | cut -d' ' -f2)
  efs_filesystem_id=$(cat "$info_path" | grep -oE -- 'efs_filesystem_id ([^ ]+)' | cut -d' ' -f2)
  efs_mount_points=$(cat "$info_path" | grep -oE -- 'efs_mount_points ([^ ]+)' | cut -d' ' -f2)

  IFS=, read -ra emp_arr <<< "$efs_mount_points"
  for e in ${emp_arr[@]}; do 
    aws efs delete-mount-target --mount-target-id $e || true
  done

  sleep 60

  aws efs delete-file-system --file-system-id $efs_filesystem_id
  echo "***** efs file system $efs_filesystem_id is destroyed *****"
} 

# authorize worker security group for efs
function authorize_security_group_ingress() {
    aws ec2 authorize-security-group-ingress --group-id $cluster_worker_security_groupid --protocol tcp --port 2049 --cidr $cluster_vpc_cidr | jq . || true
    echo "***** authorize_security_group_ingress is completed *****"   
}

# create EFS
function create_efs() {
    cluster_name=$(echo "$cluster_url" | sed -e 's|https://api\.\([^\.]*\).*|\1|')

    filesystem_id=$(aws efs create-file-system --performance-mode generalPurpose --encrypted --region ${aws_region} --tags Key=Name,Value=${cluster_name}-elastic | jq -r '.FileSystemId')
    echo "efs_filesystem_id "$filesystem_id >> $info_path
    echo "***** EFS filesystem $filesystem_id is created *****"
    sleep 10

    # create mount point
    create_efs_mountpoints
}

# create EFS mountpoint
function create_efs_mountpoints() {
    IFS=, read -ra subents_arr <<< "$cluster_subnets"
    mnt=""
    for sa in ${subents_arr[@]}; do 
        m=$(aws efs create-mount-target --file-system-id $filesystem_id --subnet-id $sa --security-groups $cluster_worker_security_groupid | jq --raw-output .MountTargetId)
        mnt=$mnt$m","
    done
    mnt="${mnt%,}"
    echo "efs_mount_points "$mnt >> $info_path
    echo "***** EFS mountpoints are created *****"
    sleep 300
}

# oc login
function oc_login() {
    oc login $cluster_url --username $cluster_username --password $cluster_password --insecure-skip-tls-verify
    if [ $? == 0 ]; then
        echo "oc login successfully!!"
    else
        echo "oc login failed!!"
        exit 1;
    fi
}

# setup nfs
function setup_nfs() {
    worker_node=`oc get nodes | grep worker | tail -1 | awk '/compute.internal/ {print $1}'` 
    echo  "worker_node.."$worker_node

    filesystem_dns_name=$filesystem_id.efs.$aws_region.amazonaws.com 
    echo "filesystem_dns_name.." $filesystem_dns_name

    namespace=default

    oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:$namespace:nfs-client-provisioner

# Create RBAC
$(cat <<EOF |oc create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: default
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: default
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
EOF 
)

echo "==========Creating Deployment=========="

# Create deployment

$(cat <<EOF | oc create -f - 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2 
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner
            - name: NFS_SERVER
              value: $filesystem_dns_name
            - name: NFS_PATH
              value: /
      volumes:
        - name: nfs-client-root
          nfs:
            server: $filesystem_dns_name
            path: /
EOF
)

# Checking the Status of Deployment pod
status="unknown"
while [ "$status" != "Running" ]
do
  pod_name=$(oc get pods -n $namespace | grep nfs-client | awk '{print $1}' )
  ready_status=$(oc get pods -n $namespace $pod_name  --no-headers | awk '{print $2}')
  pod_status=$(oc get pods -n $namespace $pod_name --no-headers | awk '{print $3}')
  echo $pod_name State - $ready_status, podstatus - $pod_status
  if [ "$ready_status" == "1/1" ] && [ "$pod_status" == "Running" ]
  then
  status="Running"
  else
  status="starting"
  sleep 10
  fi
  echo "$pod_name is $status"
done

$(cat <<EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-nfs-client
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner # or choose another name, must match deployment's env PROVISIONER_NAME'
parameters:
  archiveOnDelete: "false"
EOF 
)

}

SHORT=s:,curl:,cuser:,cpass:,op:,ip:,r:,h
LONG=subnets:,cluster-url:,cluster-username:,cluster-password:,operation:,info-path:,region:,help
OPTS=$(getopt -a -n weather --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
  case "$1" in
    -ip | --info-path )
      info_path="$2"
      shift 2
      ;;
    -s | --subnets )
      subnets="$2"
      shift 2
      ;;
    -r | --region )
      region="$2"
      shift 2
      ;;
    -curl | --cluster-url )
      cluster_url="$2"
      shift 2
      ;;
    -cuser | --cluster-username )
      cluster_username="$2"
      shift 2
      ;;
    -cpass | --cluster-password )
      cluster_password="$2"
      shift 2
      ;;
    -op | --operation )
      operation="$2"
      shift 2
      ;;

    -h | --help)
      "This is a weather script"
      exit 2
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Invalid option: $1"
      ;;
  esac
done

validate_cmd_options
echo "***** all NFS cmd options validation is completed *****"

if [[ $operation == "create" ]]; then
  # oc login
  oc_login

  # cluster parameters
  aws_region=$region
  worker_node=$(oc get nodes --selector=node-role.kubernetes.io/worker -o jsonpath='{.items[0].metadata.name}')
  cluster_vpcid=$(aws ec2 describe-instances --filters "Name=private-dns-name,Values=$worker_node" --query 'Reservations[*].Instances[*].{VpcId:VpcId}' | jq -r '.[0][0].VpcId')
  cluster_vpc_cidr=$(aws ec2 describe-vpcs --filters "Name=vpc-id,Values=$cluster_vpcid" --query 'Vpcs[*].CidrBlock' | jq -r '.[0]')
  cluster_worker_security_groupid=$(aws ec2 describe-instances --filters "Name=private-dns-name,Values=$worker_node" --query 'Reservations[*].Instances[*].{SecurityGroups:SecurityGroups}' | jq -r '.[0][0].SecurityGroups[0].GroupId')
  cluster_subnets=$subnets

  echo "aws_region.."$aws_region
  echo "cluster_vpcid.."$cluster_vpcid
  echo "cluster_vpc_cidr.."$cluster_vpc_cidr
  echo "cluster_subnets.."$cluster_subnets
  echo "worker_node.."$worker_node
  echo "cluster_worker_security_groupid.."$cluster_worker_security_groupid

  # open 2049 port for vpc cidr
  authorize_security_group_ingress

  # create efs
  create_efs

  echo "info.."$(cat $info_path)

  setup_nfs
elif [[ $operation == "destroy" ]]; then
  destroy_efs
else
  echo "Invalid efs storage operation" $operation
fi