#!/bin/bash
set -e

##### create FSx
<<comment
./fsx.sh --cluster-name fsx-d01 \
--operation create \
--vpc-id vpc-03738f32953df603f \
--vpc-cidr 10.0.0.0/16 \
--multi-az true \
--subnets subnet-05c7d2d610d4db25f,subnet-015bca0698e9b4c41,subnet-03ed7835a97324708 \
--fsx-admin-password Password@123 \
--region us-east-2 \
--oc-username kubeadmin \
--oc-password P2LGe-BRLiV-Y638j-MIqYW \
--oc-api https://api.fsx-d01.ibmworkshops.com:6443
comment

# validate cmd options
function validate_cmd_options() {

    # validate cluster_name
    if [ -z $operation ]; then
        echo "operation cannot be empty or blank"
        exit 1;
    fi

    case "$operation" in
    "create")
        # validate vpc id
        if [ -z $vpc_id ]; then
            echo "vpc-id cannot be empty or blank"
            exit 1;
        fi

        # validate vpc cidr
        if [ -z $vpc_cidr ]; then
            echo "vpc-cidr cannot be empty or blank"
            exit 1;
        fi    

        # validate multi az
        if [ -z $multi_az ]; then
            echo "multi-az cannot be empty or blank"
            exit 1;
        fi    

        # validate subnets
        if [ -z $subnets ]; then
            echo "subnets cannot be blank or empty"
            echo "Please maintain subents logical orders with separated comma(,). All private subnets first followed by public subents"
            echo "i.e. private-subnet-zone-a,private-subnet-zone-b,private-subnet-zone-c,public-subent-zone-a,public-subent-zone-b,public-subent-zone-c"
            exit 1;
        fi

        # storage capacity
        if [ -z $storage_capacity ]; then
            storage_capacity=1024
        fi

        # throughput capacity    
        if [ -z $throughput_capacity ]; then
            throughput_capacity=128
        fi

        # fsx admin password for user fsxadmin and vsadmin
        if [ -z $fsx_admin_password ]; then
            echo "fsx-admin-password cannot be empty or blank"
            exit 1;
        fi
        ;;
    "destroy")

        ;;
    "exist")
        # fsx admin password for user fsxadmin and vsadmin
        if [ -z $fsx_admin_password ]; then
            echo "fsx-admin-password cannot be empty or blank"
            exit 1;
        fi

        ;;
    *)
        echo "The operation can either create,destroy or exist only"
        exit 1;
        ;;
    esac

    # validate trident_operator_version
    if [ -z $trident_operator_version ]; then
        trident_operator_version=23.07.1
    fi


    # validate cluster_name
    if [ -z $cluster_name ]; then
        echo "cluster-name cannot be empty or blank"
        exit 1;
    fi

    # validate region
    if [ -z $region ]; then
        echo "region cannot be empty or blank"
        exit 1;
    fi


    # validate oc-username
    if [ -z $oc_username ]; then
        echo "oc-username cannot be empty or blank"
        exit 1;
    fi

    # validate oc-password
    if [ -z $oc_password ]; then
        echo "oc-password cannot be empty or blank"
        exit 1;
    fi

    # validate oc-api
    if [ -z $oc_api ]; then
        echo "oc-api cannot be empty or blank"
        exit 1;
    fi


    echo "operation.."$operation
    echo "cluster_name.."$cluster_name
    echo "region.."$region
    echo "vpc_id.."$vpc_id
    echo "vpc_cidr.."$vpc_cidr
    echo "multi_az.."$multi_az
    echo "subnets.."$subnets
    echo "storage_capacity.."$storage_capacity
    echo "throughput_capacity.."$throughput_capacity
    echo "fsx_admin_password.."$fsx_admin_password
    echo "oc_username.."$oc_username
    echo "oc_password.."$oc_password
    echo "oc_api.."$oc_api
    echo "trident_operator_version.."$trident_operator_version
}

# create FSx security group
function fsx_sg() {
    fsx_sg_id=$(aws ec2 create-security-group --group-name $cluster_name"_fsx_sg" --description $cluster_name" cluster FSx security group" --vpc-id $vpc_id | jq --raw-output .GroupId)
    echo "fsx_sg_id.."$fsx_sg_id
}

# create security group inbound rules
function fsx_sg_inbound() {
    aws ec2 authorize-security-group-ingress \
    --group-id $fsx_sg_id \
    --protocol "-1" \
    --port 0-0 \
    --cidr $vpc_cidr
}

# create security group outbound rules
function fsx_sg_outbound() {
    aws ec2 authorize-security-group-egress --group-id $fsx_sg_id --protocol "-1" --port 0-0
}

# identify prefer 
function identify_prefer_subnet() {
    subnets_arr=($(echo "$subnets" | tr "," " "))
    if [ $multi_az == "true" ]; then
        pf_subent=${subnets_arr[0]}
    else
        pf_subnet=${subnets_arr[0]}
    fi
    echo "Prefer subnet.. "$pf_subent
}

function subnet_ids_list() {
    subnets_arr=($(echo "$subnets" | tr "," " "))
    if [ $multi_az == "true" ]; then
        fsx_subnet_list=${subnets_arr[0]}" "${subnets_arr[1]}
    else
        fsx_subnet_list=${subnets_arr[0]}
    fi
    echo "FSx subnet list.."$fsx_subnet_list
}

# create FSx
function create_fsx_file_system() {
    # identify deployment type
    if [ $multi_az == "true" ]; then
        deployment_type="MULTI_AZ_1"
    else
        deployment_type="SINGLE_AZ_1"
    fi

    echo "deployment_type.."$deployment_type

    # get prefer subent
    identify_prefer_subnet

    # generate subnet list
    subnet_ids_list

    fsx_file_system_id_json=$(aws fsx create-file-system \
        --file-system-type ONTAP \
        --storage-capacity $storage_capacity \
        --subnet-ids $fsx_subnet_list \
        --security-group-ids $fsx_sg_id \
        --tags Key=Name,Value=$cluster_name \
        --output json \
        --ontap-configuration AutomaticBackupRetentionDays=0,DeploymentType=$deployment_type,FsxAdminPassword=$fsx_admin_password,PreferredSubnetId=$pf_subent,ThroughputCapacity=$throughput_capacity)

    if [ $? -gt 0 ]; then
        echo "FSx file system creation failed"
        exit 1;
    else
        echo "FSx file system json.. "$fsx_file_system_id_json
    fi

    echo $fsx_file_system_id_json >> $(pwd)/fsx_file_system_id_json.json

    fsx_file_system_id=$(cat $(pwd)/fsx_file_system_id_json.json | jq --raw-output .FileSystem.FileSystemId)

    cat /dev/null > $(pwd)/fsx_file_system_id_json.json
    
    echo "fsx_file_system_id.."$fsx_file_system_id

    echo "fsx_filesystem_id "$filesystem_id >> $info_path
    echo "region "$region >> $info_path
}

# create FSx storage virtual machine
function create_fsx_virtual_machine() {
    aws fsx create-storage-virtual-machine \
        --file-system-id $fsx_file_system_id \
        --name $cluster_name \
        --svm-admin-password $fsx_admin_password \
        --tags Key=Name,Value=$cluster_name \
        --output json
    
    if [ $? -gt 0 ]; then
        echo "FSx file virtual machine creation failed"
        exit 1;
    fi
    echo "svm_name "$cluster_name >> $info_path
}

# wait till FSx get created
function verify_fsx_status() {
    status="UNKNOWN"
    while [ $status != "AVAILABLE" ];
    do
        status=$(aws fsx describe-file-systems --file-system-ids $fsx_file_system_id | jq --raw-output .FileSystems[].Lifecycle)
        echo "FSx filesystem status is $status"
        sleep 30
    done
    echo "FSx file system $fsx_file_system_id is $status now"
    # fsx_mngmt_dnsname=management.$fsx_file_system_id.fsx.$region.amazonaws.com
    fsx_mngmt_dnsname=intercluster.$fsx_file_system_id.fsx.$region.amazonaws.com
}

# oc login
function oc_login() {
    oc version
    if [ $? -gt 0 ]; then
        echo "oc utility is not available. please download"
        exit 1;
    fi

    oc login $oc_api --username $oc_username --password $oc_password --insecure-skip-tls-verify

    if [ $? -gt 0 ]; then
        echo "oc login failed"
        exit 1;
    fi
}

# setup trident operator
function setup_trident_operator() {
    wget https://github.com/NetApp/trident/releases/download/v$trident_operator_version/trident-installer-$trident_operator_version.tar.gz
    tar -xf trident-installer-$trident_operator_version.tar.gz
    kubectl create -f ./trident-installer/deploy/crds/trident.netapp.io_tridentorchestrators_crd_post1.16.yaml
    kubectl apply -f ./trident-installer/deploy/namespace.yaml
    cp ./trident-installer/deploy/kustomization_post_1_25.yaml ./trident-installer/kustomization.yaml
    cp ./trident-installer/deploy/kustomization_post_1_25.yaml ./trident-installer/deploy/kustomization.yaml
    kubectl kustomize ./trident-installer/deploy/ > ./trident-installer/deploy/bundle_post_1_25.yaml
    kubectl create -f ./trident-installer/deploy/bundle_post_1_25.yaml
    kubectl get all -n $trident_namespace
    kubectl create -f ./trident-installer/deploy/crds/tridentorchestrator_cr.yaml
    kubectl describe torc trident
    kubectl get pods -n $trident_namespace
    ./trident-installer/tridentctl version || ./trident-installer/tridentctl -n $trident_namespace version
    sleep 20
    oc wait TridentOrchestrator.trident.netapp.io trident --for=jsonpath='{.status.status}'="Installed" --timeout 300s
}

# backend_fsx_ontap_secret yaml
function backend_fsx_ontap_secret_yaml() {
    cat << EOF >> ./ontap_secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-tbc-ontap-nas-advanced-secret
  namespace: $trident_namespace
type: Opaque
stringData:
  username: fsxadmin
  password: $fsx_admin_password
EOF
}

# trident_backend_config yaml
function trident_backend_config_yaml() {
    cat << EOF >> ./trident_backend.yaml
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: backend-fsx-ontap-nas
  namespace: $trident_namespace
spec:
  version: 1
  backendName: tbc-ontap-nas-advanced
  storageDriverName: ontap-nas
  managementLIF: $fsx_mngmt_dnsname
  svm: $cluster_name
  credentials:
    name: backend-tbc-ontap-nas-advanced-secret
EOF
}

# ontap_nas_sc yaml
function ontap_nas_sc_yaml() {
    cat << EOF >> ./ontap_nas_sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ontap-nas
provisioner: csi.trident.netapp.io
parameters:
  storagePools: "tbc-ontap-nas-advanced:.*"
  fsType: "nfs"
allowVolumeExpansion: True
EOF
}

# configure FSx storage
function configure_fsx_storage() {
    
    backend_fsx_ontap_secret_yaml
    trident_backend_config_yaml
    ontap_nas_sc_yaml
    
    oc apply -f ./ontap_secret.yaml &&
    oc apply -f ./trident_backend.yaml &&
    sleep 30 &&
    oc wait TridentBackendConfig backend-fsx-ontap-nas \
        -n $trident_namespace \
        --for=jsonpath='{.status.phase}'="Bound" &&
    oc wait TridentBackendConfig backend-fsx-ontap-nas \
        -n $trident_namespace \
        --for=jsonpath='{.status.lastOperationStatus}'="Success" &&
    oc apply -f ./ontap_nas_sc.yaml
}

function destroy_fsx() {
    fsx_filesystem_id=$(cat "$info_path" | grep -oE -- 'fsx_filesystem_id ([^ ]+)' | cut -d' ' -f2)
    region=$(cat "$info_path" | grep -oE -- 'region ([^ ]+)' | cut -d' ' -f2)
    svm_name=$(cat "$info_path" | grep -oE -- 'svm_name ([^ ]+)' | cut -d' ' -f2)

    # trying to delete FSx volumes
    aws fsx describe-volumes \
        --region "${region}" \
        --filters "Name=file-system-id,Values=${fsx_filesystem_id}" \
        --max-items 5000 \
        --page-size 100 \
        --no-cli-pager \
        --query "Volumes[?Name != \`${svm_name}_root\`].VolumeId" \
        --output text \
        | tr -s "\\t" "\\n" \
        | xargs -I{} aws fsx delete-volume \
                    --region "${region}" \
                    --volume-id {} \
                    --ontap-configuration SkipFinalBackup=true || true

    # get storage virtual machine id
    storage_virtual_machine_id=$( aws fsx describe-storage-virtual-machines \
    --filters "Name=file-system-id,Values=${fsx_filesystem_id}" \
    --output json | jq --raw-output .StorageVirtualMachines[].StorageVirtualMachineId)

    # delete storage virtual machine(SVM)
    aws fsx delete-storage-virtual-machine --storage-virtual-machine-id $storage_virtual_machine_id

    # awaiting to delete SVM
    status="DELETING"
    while [ $status == "DELETING" ];
    do
            status=$(aws fsx describe-storage-virtual-machines --filters "Name=file-system-id,Values=${fsx_filesystem_id}" --output json | jq --raw-output .StorageVirtualMachines[].Lifecycle)
            if [ -z $status ]; then
                status=DELETED
            fi
            echo "FSx stroage virtual machine delete status is $status"
            sleep 30
    done

    # delete FSx
    aws fsx delete-file-system --file-system-id=${fsx_filesystem_id}

    status="DELETING"
    while [ $status == "DELETING" ];
    do
            status=$(aws fsx describe-file-systems --file-system-ids ${fsx_filesystem_id} --output json | jq --raw-output .FileSystems[].Lifecycle) || true
            if [ -z $status ]; then
                status=DELETED
            fi
            echo "FSx file system delete status is $status"
            sleep 30
    done

}

SHORT=cn:,r:,vid:,vcidr:,op:,maz:,s:,sc:,tc:,fap:,ou:,op:,oa:,tov:,h
LONG=cluster-name:,region:,vpc-id:,vpc-cidr:,operation:,multi-az:,subnets:,storage-capacity:,throughput-capacity:,fsx-admin-password:,oc-username:,oc-password:,oc-api:,trident-operator-version:,help
OPTS=$(getopt -a -n weather --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
  case "$1" in
    -op | --operation )
      operation="$2"
      shift 2
      ;;
    -cn | --cluster-name )
      cluster_name="$2"
      shift 2
      ;;
    -r | --region )
      region="$2"
      shift 2
      ;;
    -vid | --vpc-id )
      vpc_id="$2"
      shift 2
      ;;
    -vcidr | --vpc-cidr )
      vpc_cidr="$2"
      shift 2
      ;;
    -maz | --multi-az )
      multi_az="$2"
      shift 2
      ;;
    -s | --subnets )
      subnets="$2"
      shift 2
      ;;
    -sc | --storage-capacity )
      storage_capacity="$2"
      shift 2
      ;;
    -tc | --throughput-capacity )
      throughput_capacity="$2"
      shift 2
      ;;
    -fap | --fsx-admin-password )
      fsx_admin_password="$2"
      shift 2
      ;;
    -ou | --oc-username )
      oc_username="$2"
      shift 2
      ;;
    -op | --oc-password )
      oc_password="$2"
      shift 2
      ;;
    -oa | --oc-api )
      oc_api="$2"
      shift 2
      ;;
    -fid | --fsx-file-system-id )
      fsx_file_system_id="$2"
      shift 2
      ;;
    -tov | --trident-operator-version )
      trident_operator_version="$2"
      shift 2
      ;;

    -h | --help)
      "This is a create/destroy FSx ONTAP"
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

export trident_namespace=trident
export base_path=/home/ec2-user
export installer_workspace=$base_path/installer
export info_path=$installer_workspace/.info

# validate cli option
validate_cmd_options

case "$operation" in
"create")
    # create FSx security group
    fsx_sg

    # Create SG inboud rules
    fsx_sg_inbound

    # Create SG outbound rules
    fsx_sg_outbound

    # create FSx
    create_fsx_file_system

    # create FSx virtual machine
    create_fsx_virtual_machine

    # wait till FSx created
    verify_fsx_status

    # oc login
    oc_login

    # setup_trident_operator
    setup_trident_operator

    # configure_fsx_storage
    configure_fsx_storage

    ;;
"destroy")
    # destroy fsx
    destroy_fsx
    ;;
"exist")
    # oc login
    oc_login
    
    # setup_trident_operator
    setup_trident_operator

    # configure_fsx_storage
    configure_fsx_storage

    ;;
*)
    echo "The operation can either create, destroy or exist only"
    exit 1;
    ;;
esac
