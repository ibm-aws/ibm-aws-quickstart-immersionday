##### Goals

- Request the student environment.
- Validate the environment Variables.


##### Check for tools Installation
```
oc version

```
Sample Output:
```
Client Version: 4.9.23
Server Version: 4.8.11
Kubernetes Version: v1.21.1+9807387
```
```
aws

```
ExpectedOutput:
```
usage: aws [options] <command> <subcommand> [<subcommand> ...] [parameters]
To see help text, you can run:

  aws help
  aws <command> help
  aws <command> <subcommand> help

aws: error: the following arguments are required: command
```
##### Save OpenShift Configuration to Variables
```
export OCP_USER=ocsadmin
export OCP_PASSWORD=ocsadmin

export OCP_API=https://api.d05-cluster.ibmworkshops.com:6443

oc login --insecure-skip-tls-verify=true -u ${OCP_USER} -p ${OCP_PASSWORD} ${OCP_API}
```
##### Review oc login
```
oc login --insecure-skip-tls-verify=true -u ${OCP_USER} -p ${OCP_PASSWORD} ${OCP_API}
Login successful.

You have access to 66 projects, the list has been suppressed. You can list all projects with 'oc projects'

oc whoami


oc whoami --show-console

https://console-openshift-console.apps.d05-cluster.ibmworkshops.com

```
##### Review oc nodes information

```
oc get nodes
```
ExpectedOutput:

```
NAME                                        STATUS   ROLES          AGE     VERSION
ip-10-0-11-133.us-east-2.compute.internal   Ready    worker         6d17h   v1.21.1+9807387
ip-10-0-11-24.us-east-2.compute.internal    Ready    infra,worker   6d17h   v1.21.1+9807387
ip-10-0-30-225.us-east-2.compute.internal   Ready    master         6d17h   v1.21.1+9807387
ip-10-0-35-229.us-east-2.compute.internal   Ready    infra,worker   6d17h   v1.21.1+9807387
ip-10-0-48-68.us-east-2.compute.internal    Ready    master         6d17h   v1.21.1+9807387
ip-10-0-58-26.us-east-2.compute.internal    Ready    worker         5d22h   v1.21.1+9807387
ip-10-0-60-51.us-east-2.compute.internal    Ready    worker         6d17h   v1.21.1+9807387
ip-10-0-7-203.us-east-2.compute.internal    Ready    worker         5d16h   v1.21.1+9807387
ip-10-0-74-4.us-east-2.compute.internal     Ready    master         6d17h   v1.21.1+9807387
ip-10-0-88-242.us-east-2.compute.internal   Ready    infra,worker   6d17h   v1.21.1+9807387
ip-10-0-94-61.us-east-2.compute.internal    Ready    worker         6d17h   v1.21.1+9807387
```
##### Review CP4D Access.

```
https://cpd-zen.apps.d05-cluster.ibmworkshops.com

username: ocsadmin
```
To retrieve password for CP4D, please run this below command.
```
oc extract secret/admin-user-details --keys=initial_admin_password --to=- -n zen > /tmp/out.txt

vi /tmp/out.txt

L6eNLEteltn0

```
###### Scale up your cluster by adding compute nodes.

```
oc get pods -n zen --output name | wc -l

```
ExpectedOutput:
```
239
```
```
oc get machineset -n openshift-machine-api

NAME                                     DESIRED   CURRENT   READY   AVAILABLE   AGE
d05-cluster-pprz8-worker-us-east-2a      2         2         2       2           6d18h
d05-cluster-pprz8-worker-us-east-2b      2         2         2       2           6d18h
d05-cluster-pprz8-worker-us-east-2c      1         1         1       1           6d18h
d05-cluster-pprz8-workerocs-us-east-2a   1         1         1       1           6d17h
d05-cluster-pprz8-workerocs-us-east-2b   1         1         1       1           6d17h
d05-cluster-pprz8-workerocs-us-east-2c   1         1         1       1           6d17h
```

From the list returned in the previous command, choose the machine set to scale up. Only ***Review*** the parameters, Your lab environment already provisioned with replica value to 2.

```
oc edit machineset d05-cluster-pprz8-worker-us-east-2a -n openshift-machine-api


apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  annotations:
    autoscaling.openshift.io/machineautoscaler: openshift-machine-api/d05-cluster-pprz8-worker-us-east-2a
    machine.openshift.io/GPU: "0"
    machine.openshift.io/cluster-api-autoscaler-node-group-max-size: "12"
    machine.openshift.io/cluster-api-autoscaler-node-group-min-size: "1"
    machine.openshift.io/memoryMb: "65536"
    machine.openshift.io/vCPU: "16"
  creationTimestamp: "2022-07-07T12:04:10Z"
  generation: 2
  labels:
    machine.openshift.io/cluster-api-cluster: d05-cluster-pprz8
  name: d05-cluster-pprz8-worker-us-east-2a
  namespace: openshift-machine-api
  resourceVersion: "1161345"
  uid: 2a0db2a3-db74-4d0b-ab4f-4be921f65901
spec:
  replicas: 2
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: d05-cluster-pprz8
      machine.openshift.io/cluster-api-machineset: d05-cluster-pprz8-worker-us-east-2a
  template:
    metadata:
    ----------------------output truncated ----------
```

##### Conclusion
- We have learned how to use the command line tools.
- We have learned how to access the openshift cluster and CP4D environment.
- We have learned how to scale up the cluster by adding compute nodes by reviewing the parameters.
