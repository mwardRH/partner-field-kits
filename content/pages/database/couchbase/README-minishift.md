Title: Demo Script
Date: 2018-09-17

# Demo Script Template
Version: 0.01

## Goal
The goal is to show how easy it is to deploy and manage a container aware and resilient database for your Modern Containerized Application using the Couchbase Operator for MiniShift

We will extend the Kubernetes native functionality by deploying a Custom Resource Definition (CRD). We will use the Couchbase Operator to interact with the CRD and deploy our database pods from the Red Hat Container Registry.

### Features
- Use the Operator to deploy a 4 node Couchbase Cluster.
- Show auto recovery and cluster rebalancing.

### Limitation
- Everything is done from the admin account. This is **NOT** a hard requirement for production usage, but done for simplicity. This limitation will be removed shortly, in the next iteration.
- In this version we do not have an application connected to the database. This will appear in future version. It will show how we can lose a node and not disrupt the application.
- When doing the cluster server group deployment, it requires you have 4 or more nodes.
- The Couchbase Operator only supports Dynamic Provisioning Physical Volumes. This environment uses NSF for PVs (which doesn't support dynamic provisioning).

## Environment Prep
[Minishift start here:](https://www.okd.io/minishift/)

## Demo Prep
`minishift start`

>Login to server ...
>Creating initial project "myproject" ...
>Server Information ...
>OpenShift server started.
>
>The server is accessible via web console at:
>    https://192.168.42.203:8443
>
>You are logged in as:
>    User:     developer
>    Password: <any value>
>
>To login as administrator:
>    oc login -u system:admin

```
oc login --username=system:admin

oc new-project operator-example

oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/86ec177117e43d9cf2254c1fb5ef37c8248bc04a/crd.yaml

oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/86ec177117e43d9cf2254c1fb5ef37c8248bc04a/cluster-role-sa.yaml
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/86ec177117e43d9cf2254c1fb5ef37c8248bc04a/cluster-role-user.yaml

oc create serviceaccount couchbase-operator --namespace operator-example

oc create rolebinding couchbase-operator --clusterrole couchbase-operator --serviceaccount operator-example:couchbase-operator

oc adm policy add-scc-to-user anyuid system:serviceaccount:operator-example:couchbase-operator

oc create rolebinding couchbasecluster --clusterrole couchbasecluster --user developer --namespace operator-example

oc create clusterrolebinding couchbasecluster --clusterrole couchbasecluster --user developer

oadm policy add-role-to-user admin developer -n operator-example

oc create secret docker-registry rh-catalog --docker-server=registry.connect.redhat.com --docker-username=redcouch --docker-password=openshift --docker-email=redcouchredhat@gmail.com

oc secrets add serviceaccount/couchbase-operator secrets/rh-catalog --for=pull
oc secrets add serviceaccount/default secrets/rh-catalog --for=pull
```
> You will need to wait about 5 to 10 minutes for the image to pull from the Red Hat registry.

```
oc login --username=developer
oc project operator-example
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/86ec177117e43d9cf2254c1fb5ef37c8248bc04a/operator.yaml
```
> Note your pods name is partially random, you will have a different name.

```
oc get pods -w
NAME                                  READY     STATUS    RESTARTS   AGE
couchbase-operator-5bc785c54f-kh6c2   1/1       Running   0          22s
```
> **Do not proceed** to the next step until you see the `couchbase-operator` pod has status `RUNNING`. We use the `-w` option to watch the command, hit `ctrl + C` to escape.

```
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/86ec177117e43d9cf2254c1fb5ef37c8248bc04a/secret.yaml
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/86ec177117e43d9cf2254c1fb5ef37c8248bc04a/cluster-basic.yaml
```
You should start seeing Couchbase pods appearing immediately. It will take a couple of minutes for the cluster to be ready.

```
oc get pods -w
NAME                                  READY     STATUS    RESTARTS   AGE
cb-example-0000                       1/1       Running   0          3m
cb-example-0001                       1/1       Running   0          3m
cb-example-0002                       1/1       Running   0          2m
cb-example-0003                       1/1       Running   0          2m
couchbase-operator-5bc785c54f-kh6c2   1/1       Running   0          7m
```
> Remember to hit `ctrl + c` to escape.

```
oc expose service/cb-example-ui
```
Get the route to the Couchbase UI:

```
oc get routes
NAME            HOST/PORT                                                             PATH      SERVICES        PORT        TERMINATION   WILDCARD
cb-example-ui   cb-example-ui-operator-example.apps.couchbase.openshiftworkshop.com             cb-example-ui   couchbase                 None
```

Open the URL outputted by `oc get routes` in your browser and login with:
> Username: Administrator
> Password: password

## Start Demo Here
Open the URL outputted by `oc get routes` in your browser and login with:
> Username: Administrator
> Password: password.

Navigate to "Servers" to see the server list:

![Basic Couchbase Cluster](https://github.com/couchbase-partners/redhat-pds/blob/master/img/cb-cluster-basic.png)

On the Pods page in OpenShift (https://master.couchbase.openshiftworkshop.com/console/project/operator-example/browse/pods):

![](https://github.com/couchbase-partners/redhat-pds/blob/master/img/os-cluster-basic.png)

### Failover Demo

Now that we have a cluster up with some data, we can demonstrate the operator in action.

First, delete one of the pods:

```
oc delete pod cb-example-0003
```

By deleting the pod, we are destroying one of the Couchbase nodes. At this point the operator should take over and try to recover the cluster to our desired state.

Couchbase recognizes that a node is missing and triggers fail-over:

![](https://github.com/couchbase-partners/redhat-pds/blob/master/img/failover-1.png)

Couchbase recognizes the new node coming online and begins rebalancing:

![](https://github.com/couchbase-partners/redhat-pds/blob/master/img/failover-2.png)

The rebalance continues until the cluster is fully healed.

![](https://github.com/couchbase-partners/redhat-pds/blob/master/img/failover-3.png)

## Deploy an App
> App Deployment... coming soon. 

## Cleanup

Delete the cluster before moving onto the next example:

`oc delete -f cluster-basic.yaml`
