#!/bin/bash

### command with all arguments
##### create cluster
### nohup ./rosa.sh --operation=create --cluster-name=rosa-d01 --compute-machine-type=m5.4xlarge --replicas=3 --region=us-east-2 --machine-cidr=10.0.0.0/16 --service-cidr=172.30.0.0/16 --pod-cidr=10.128.0.0/14 --host-prefix=23 --private=false --multi-az=true --version=4.12.15 --subnets=subnet-5c7d2d610d4db25f,subnet-15bca0698e9b4c41,subnet-3ed7835a97324708,subnet-68bc9661bea107d1,subnet-5a6043f88f7c2461,subnet-a3646c21243f87f9 --fips=false --rosa-token=eyJhbGciOiJIUIqTFJv3GKs9d8k &
##### destroy cluster
### nohup ./rosa.sh --operation=destroy --cluster-name=rosa-d01 --region=us-east-2 --rosa-token=eyJhbGciOiJIUIqTFJv3GKs9d8k &

# validate command line options
function validate_cmd_options() {

    if [ $operation == "create" ]; then
        # validate compute_machine_type
        if [ -z $compute_machine_type ]; then
            echo "compute_machine_type cannot be blank or empty"
            exit 1;
        fi

        # validate replicas
        if [[ -z $replicas || $replicas -lt 1 ]]; then
            echo "replicas cannot be blank or empty and it must be greater than zero"
            exit 1;
        fi

        # validate machine_cidr
        if [ -z $machine_cidr ]; then
            echo "machine_cidr cannot be blank or empty"
            exit 1;
        fi

        # validate service_cidr
        if [ -z $service_cidr ]; then
            echo "service_cidr cannot be blank or empty"
            exit 1;
        fi

        # validate pod_cidr
        if [ -z $pod_cidr ]; then
            echo "pod_cidr cannot be blank or empty"
            exit 1;
        fi

        # validate host_prefix
        if [ -z $host_prefix ]; then
            echo "host_prefix cannot be blank or empty"
            exit 1;
        fi

        # validate private
        case "$private" in
        "true")
            ;;
        "false")
            ;;
        *)
            echo "The private can either true or false only."
            exit 1;
            ;;
        esac

        # validate multi_az
        case "$multi_az" in
        "true")
            ;;
        "false")
            ;;
        *)
            echo "The multi_az can either true or false only."
            exit 1;
            ;;
        esac

        # validate host_prefix
        if [ -z $version ]; then
            echo "version cannot be blank or empty"
            exit 1;
        fi

        # validate subnets
        if [ -z $subnets ]; then
            echo "subnets cannot be blank or empty"
            echo "Please maintain subents logical orders with separated comma(,). All private subnets first followed by public subents"
            echo "i.e. private-subnet-zone-a,private-subnet-zone-b,private-subnet-zone-c,public-subent-zone-a,public-subent-zone-b,public-subent-zone-c"
            exit 1;
        fi

        # validate fips
        case "$fips" in
        "true")
            ;;
        "false")
            ;;
        *)
            echo "The fips can either true or false only."
            exit 1;
            ;;
        esac

        echo "compute_machine_type.."$compute_machine_type
        echo "replicas.."$replicas
        echo "machine_cidr.."$machine_cidr
        echo "service_cidr.."$service_cidr
        echo "pod_cidr.."$pod_cidr
        echo "host_prefix.."$host_prefix
        echo "private.."$private
        echo "multi_az.."$multi_az
        echo "version.."$version
        echo "subnets.."$subnets
        echo "fips.."$fips
    fi

    # validate cluster_name
    if [[ -z $cluster_name || ${#cluster_name} -ge 15 ]]; then
        echo "cluster_name cannot be blank or empty and it must be less than 15 charagets"
        exit 1;
    fi

    # validate region
    if [ -z $region ]; then
        echo "AWS region cannot be blank or empty"
        exit 1;
    fi

    # validate rosa token
    if [ -z $rosa_token ]; then
        echo "rosa-token cannot be blank or empty"
        exit 1;
    fi

    echo "cluster_name.."$cluster_name
    echo "region.."$region
    echo "rosa_token.."$rosa_token
    echo "***** All arguments are validated *****"
}

# identify rosa subnets
function identify_subnets() {
    #split subnets with comma
    subnets_arr=($(echo "$subnets" | tr "," " "))
    # Print the array elements
    # echo ${subnets_arr[0]}
    if [ $private == "true" ]; then
        if [ $multi_az == "true" ]; then
            multi_zone_subnets=${subnets_arr[0]},${subnets_arr[1]},${subnets_arr[2]}
        else
            single_zone_subnets=${subnets_arr[0]}
        fi
    else
        if [ $multi_az == "true" ]; then
            multi_zone_subnets=${subnets_arr[0]},${subnets_arr[1]},${subnets_arr[2]},${subnets_arr[3]},${subnets_arr[4]},${subnets_arr[5]}
        else
            single_zone_subnets=${subnets_arr[0]},${subnets_arr[3]}
        fi
    fi 

    if [ $multi_az == "true" ]; then
        rosa_subnets=$multi_zone_subnets
    else
        rosa_subnets=$single_zone_subnets
    fi
    echo "rosa_subnets.."$rosa_subnets
    echo "***** Subents are identified *****"
}

# download rosa and openshift cli utility
function download_binaries() {
    wget -r -l1 -np -nd -q $rosa_cli_url -P $installer_workspace
    tar -xvzf $installer_workspace/rosa-linux.tar.gz -C $installer_workspace/
    chmod u+x $installer_workspace/rosa

    wget "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${version}/openshift-client-linux-${version}.tar.gz"
    mv openshift-client-linux-${version}.tar.gz $installer_workspace/openshift-client-linux-${version}.tar.gz
    tar -xvf $installer_workspace/openshift-client-linux-${version}.tar.gz $installer_workspace/
            
    sudo chmod u+x $installer_workspace/oc $installer_workspace/kubectl
    sudo mv $installer_workspace/oc /usr/local/bin
    sudo cp /usr/local/bin/oc /usr/bin/

    sudo mv $installer_workspace/kubectl /usr/local/bin
    sudo cp /usr/local/bin/kubectl /usr/bin/
    echo "***** All binaries are downloaded *****"
}

# create_AWSServiceRoleForElasticLoadBalancing
function create_AWSServiceRoleForElasticLoadBalancing() {
    aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"
    echo "***** AWS service role for elastic load balancing is found or created *****"
}

# setup environment
function setup_environment() {
    # rosa subnets
    identify_subnets
    echo "cluster_subnets.."$rosa_subnets

    # download all binaries to installer-files
    download_binaries

    # create AWS service role for elasticloadbalancing
    create_AWSServiceRoleForElasticLoadBalancing
}

# rosa login
function rosa_login() {
    $installer_workspace/rosa login --token=$rosa_token
    if [ $? == 0 ]; then
        echo "rosa login successfully!!"
    else
        echo "rosa login failed!!"
        exit 1;
    fi
}

# install rosa cluster
function install_rosa_cluster() {
    if [ $private == "true" ]; then
        private_link="--private-link"
    else
        private_link=""
    fi


    version_arr=($(echo "$version" | tr "." " "))
    rosa_major_minor_version=${version_arr[0]}.${version_arr[1]}

    # verify rosa quota
    $installer_workspace/rosa verify quota &&
    ecode=$?
    echo "***** Rosa quota is verified *****"

    # create rosa account IAM roles
    if [ $ecode == 0 ]; then
        $installer_workspace/rosa create account-roles --mode auto --yes --version $rosa_major_minor_version && $installer_workspace/rosa create oidc-config --yes --output json  --mode auto
        ecode=$?
        echo "***** rosa account role is created *****"
    else
        echo "rosa verify quota check is failed"
        exit 1;
    fi

    # install rosa cluster
    if [ $ecode == 0 ]; then
        echo "Triggering cluster creation...."
        $installer_workspace/rosa create cluster $private_link --cluster-name=$cluster_name --compute-machine-type=$compute_machine_type --replicas $replicas --region $region --machine-cidr=$machine_cidr --service-cidr=$service_cidr --pod-cidr=$pod_cidr --host-prefix=$host_prefix --private=$private --multi-az=$multi_az --version=$version --subnet-ids=$rosa_subnets  --fips=$fips --watch --yes --sts --mode auto && $installer_workspace/rosa logs install --cluster=$cluster_name --watch
        ecode=$?
        echo "***** rosa cluster is created *****"
    else
        echo "Failed to create rosa IAM roles"
        exit 1;
    fi

    if [ $ecode == 0 ]; then
        $installer_workspace/rosa describe cluster --cluster=$cluster_name
        $installer_workspace/rosa create admin --cluster=$cluster_name > $cred_path
        ecode=$?
        echo "***** rosa cluster admin user is created *****"
        sleep 300
    else
        echo "Failed to create rosa cluster"
    fi

    if [ $ecode != 0 ]; then
        echo "Failed to create admin user"
        exit 1;
    fi
}

# Destroy rosa cluster
function destroy_rosa_cluster() {
    cluster_id=$($installer_workspace/rosa describe cluster --cluster=$cluster_name -o json | jq --raw-output .id)
    ecode=$?
    echo "cluster_id.."$cluster_id

    # get cluster id
    if [ $ecode == 0 ]; then
        $installer_workspace/rosa delete cluster --cluster=$cluster_name --yes && $installer_workspace/rosa logs uninstall -c $cluster_name --watch
        echo "***** Cluster is destroyed *****"
        $installer_workspace/rosa delete operator-roles -c=$cluster_id --mode auto --yes
        echo "***** Cluster operator roles are destroyed *****"
        $installer_workspace/rosa delete oidc-provider -c=$cluster_id --mode auto --yes
        echo "***** Cluster OIDC is destroyed *****"
        ecode=$?
        rm -f $cred_path
        rm -f $info_path
    else
        echo "Failed to describe cluster"
    fi

    # 
}

##### script execution is started from below #####
# create installer files
mkdir -p $(pwd)/installer-files

export installer_workspace=$(pwd)/installer-files
export cred_path=$installer_workspace/.cred
export info_path=$installer_workspace/.info

export rosa_cli_url=https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/rosa-linux.tar.gz

SHORT=cn:,cmt:,rep:,r:,mc:,sc:,pc:,hp:,p:,maz:,ver:,s:,f:,rt:,op:,h
LONG=cluster-name:,compute-machine-type:,replicas:,region:,machine-cidr:,service-cidr:,pod-cidr:,host-prefix:,private:,multi-az:,version:,subnets:,fips:,rosa-token:,operation:,help
OPTS=$(getopt -a -n weather --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
  case "$1" in
    -cn | --cluster-name )
      cluster_name="$2"
      shift 2
      ;;
    -cmt | --compute-machine-type )
      compute_machine_type="$2"
      shift 2
      ;;
    -rep | --replicas )
      replicas="$2"
      shift 2
      ;;
    -r | --region )
      region="$2"
      shift 2
      ;;
    -mc | --machine-cidr )
      machine_cidr="$2"
      shift 2
      ;;
    -sc | --service-cidr )
      service_cidr="$2"
      shift 2
      ;;
    -pc | --pod-cidr )
      pod_cidr="$2"
      shift 2
      ;;
    -hp | --host-prefix )
      host_prefix="$2"
      shift 2
      ;;
    -p | --private )
      private="$2"
      shift 2
      ;;
    -maz | --multi-az )
      multi_az="$2"
      shift 2
      ;;
    -ver | --version )
      version="$2"
      shift 2
      ;;
    -s | --subnets )
      subnets="$2"
      shift 2
      ;;
    -f | --fips )
      fips="$2"
      shift 2
      ;;
    -rt | --rosa-token )
      rosa_token="$2"
      shift 2
      ;;
    -op | --operation )
      operation="$2"
      shift 2
      ;;

    -h | --help)
      "This is a install rosa script"
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

# rosa login
rosa_login

# install rosa cluster
case "$operation" in
"create")
    setup_environment
    install_rosa_cluster
    ;;
"destroy")
    destroy_rosa_cluster
    ;;
*)
    echo "The operation can either create or destroy only"
    exit 1;
    ;;
esac
