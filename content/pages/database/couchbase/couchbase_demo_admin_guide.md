Title: Demo Script Admin Guide
Date: 2018-09-10

# Demo Admin Guide
Version: 0.01

# Products Included
Red Hat Products | Version
---------------- | -------
OpenShift | 3.9, and 3.10

Couchbase | Version
--------- | -------
Couchbase | 5.5.1-1
Couchbase Autonomous Operator | 1.0.0-1


# Deprication Rules
Check Point Date? 2019-March-01
Agree upon retirement checkpoint date? N/A
What event occurs to change the checkpoint date?
- RHPDS offers Dynamic Storage for the OpenShift workshops.
- Wildfly goes GA in OpenShift

# Steps to Rebuild Demo

### Login to Red Hat OpenShift Container Platform

> You must log into deploy the OpenShift Workshop located in RHPDS. Instructions for doing this to come in the future. 

### Create Project

Next, we need to create a project for our work.

```
oc new-project operator-example
```

This command creates the `operator-example` project and switches to it.

### Deploy the Operator CRD

```
oc create -f crd.yaml
```

### Create Roles, Accounts & Bindings

```
oc create -f cluster-role-sa.yaml
oc create -f cluster-role-user.yaml

oc create serviceaccount couchbase-operator --namespace operator-example

oc create rolebinding couchbase-operator --clusterrole couchbase-operator --serviceaccount operator-example:couchbase-operator

oc adm policy add-scc-to-user anyuid system:serviceaccount:operator-example:couchbase-operator

oc create rolebinding couchbasecluster --clusterrole couchbasecluster --user developer --namespace operator-example

oc create clusterrolebinding couchbasecluster --clusterrole couchbasecluster --user developer

```

### Create Red Hat Registry Secrets

Before we can deploy the operator we need to specify credentials for pulling container images from Red Hat's registry and add them to the service accounts.

Replace USERNAME and PASSWORD and EMAIL below with your Red Hat account info.

```
oc create secret docker-registry rh-catalog --docker-server=registry.connect.redhat.com --docker-username=redcouch --docker-password=openshift --docker-email=redcouchredhat@gmail.com

oc secrets add serviceaccount/couchbase-operator secrets/rh-catalog --for=pull
oc secrets add serviceaccount/default secrets/rh-catalog --for=pull
```
> Note the image will be pulled from the registry into you local repository. This can take a few minutes.

### Deploy the Operator

```
oc create -f operator.yaml
```

After < 1 minute you should be able to see the operator running:

> Note your pods name is partially random, you will have a different name.

```
oc get pods -w
NAME                                  READY     STATUS    RESTARTS   AGE
couchbase-operator-5bc785c54f-kh6c2   1/1       Running   0          22s
```

**Do not proceed** to the next step until you see the `couchbase-operator` pod has status `RUNNING`. We use the `-w` option to watch the command, hit `ctrl + C` to escape.

### Deploy Couchbase Credentials Secret

The Couchbase clusters deployed in the following steps will use the credentials provided in the `cb-example-auth` secret. Deploying `secret.yaml` will create the secret.

```
oc create -f secret.yaml
```

# Cluster Recipes

### Deploy a Basic Couchbase Cluster

The first cluster that we'll deploy will be a simple, 4 node cluster, with one bucket and 2 replicas.

```
oc create -f cluster-basic.yaml
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

### Expose the Couchbase UI

Next, expose the Couchbase UI so you can log into it:

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
> Password: password.

Navigate to "Servers" to see the server list:

![Basic Couchbase Cluster](img/cb-cluster-basic.png)

On the Pods page in OpenShift (https://master.couchbase.openshiftworkshop.com/console/project/operator-example/browse/pods):

![](img/os-cluster-basic.png)

### Failover Demo

Now that we have a cluster up with some data, we can demonstrate the operator in action.

First, delete one of the pods:

```
oc delete pod cb-example-0003
```

By deleting the pod, we are destroying one of the Couchbase nodes. At this point the operator should take over and try to recover the cluster to our desired state.

Couchbase recognizes that a node is missing and triggers fail-over:

![](img/failover-1.png)

Couchbase recognizes the new node coming online and begins rebalancing:

![](img/failover-2.png)

The rebalance continues until the cluster is fully healed.

![](img/failover-3.png)

### Cleanup

Delete the cluster before moving onto the next example:

```
oc delete -f cluster-basic.yaml

```


## Deploy a Cluster with Server Groups Enabled
> NOTE This requires you have more than 4 nodes. If you have less, this section will fail.

First, we need to add labels to our OpenShift nodes. Labels are used to tell the Operator which zone a particular node belongs too. In this example, we'll declare the node1 and node2 belong to ServerGroup1. Our node2 and node3 will belong to ServerGroup2.

```
 oc label --overwrite nodes node1.couchbase.internal server-group.couchbase.com/zone=ServerGroup1
 oc label --overwrite nodes node2.couchbase.internal server-group.couchbase.com/zone=ServerGroup1
 oc label --overwrite nodes node3.couchbase.internal server-group.couchbase.com/zone=ServerGroup2
 oc label --overwrite nodes node4.couchbase.internal server-group.couchbase.com/zone=ServerGroup2
```

Now deploy the new cluster:

```
oc create -f cluster-server-groups.yaml
```

This deploys a 9 node cluster with ServerGroups enabled. The distribution of nodes is setup so that each zone has 2 Data nodes and 1 Query node. This allows us to keep 2 replicas of the default bucket in each zone.

![](img/9node-server-list.png)

# Deploy an Application
