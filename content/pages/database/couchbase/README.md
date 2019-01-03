Title: Demo Script
Date: 2018-09-17

# Demo Script Template
Version: 0.01

## Goal
The goal is to show how easy it is to deploy and manage a container aware and resilient database for your Modern Containerized Application using the Couchbase Operator.

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
[RHPDS](https://rhpds.redhat.com/)

#### OpenShift Workshop
This item is currently in "public beta". Please allow at least 24 hours for support, deploy your workshop with this limitation in mind, thanks.

OpenShift Workshop provisions an OpenShift cluster with metrics and logging enabled on AWS infrastructure for running hands-on-labs, workshops and similar events such as Containers and Cloud-Native Roadshow, OpenShift Middleware Workshops, etc.

Cluster Specification
- Nodes: 1 master, 1 infra, num-of-users/5 nodes
- Storage: NFS with 100 persistent volumes

Access Guide

You have full admin access to the provisioned workshop cluster and can find all details needs to access your cluster in this [document](http://bit.ly/rhpds-openshift-workshop-guide)

> Provisioning Time is about 40 minutes.

City Specification
Please enter a city name of at least 5 characters.

> Need support: Contact [rhpds-admins@redhat.com](mailto:rhpds-admins@redhat.com)

## Demo Prep
> Note the name of your city will change the master url. This example we put the city name as couchbase. You would put your city name where it says couchbase.

> https://master.[YOUR CITY NAME].openshiftworkshop.com

```
oc login --username=opentlc-mgr --password=r3dh4t1! https://master.couchbase.openshiftworkshop.com

oc new-project operator-example

oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/crd.yaml

oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/cluster-role-sa.yaml

oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/cluster-role-user.yaml

oc create serviceaccount couchbase-operator --namespace operator-example

oc create rolebinding couchbase-operator --clusterrole couchbase-operator --serviceaccount operator-example:couchbase-operator

oc adm policy add-scc-to-user anyuid system:serviceaccount:operator-example:couchbase-operator

oc create rolebinding couchbasecluster --clusterrole couchbasecluster --user developer --namespace operator-example

oc create clusterrolebinding couchbasecluster --clusterrole couchbasecluster --user developer

oadm policy add-role-to-user admin user1 -n operator-example

oc create secret docker-registry rh-catalog --docker-server=registry.connect.redhat.com --docker-username=redcouch --docker-password=openshift --docker-email=redcouchredhat@gmail.com

oc secrets add serviceaccount/couchbase-operator secrets/rh-catalog --for=pull
oc secrets add serviceaccount/default secrets/rh-catalog --for=pull
```
> You will need to wait about 5 to 10 minutes for the image to pull from the Red Hat registry.

```
oc login --username=developer
oc project operator-example
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/operator.yaml
```
> Note your pods name is partially random, you will have a different name.

```
oc get pods -w
NAME                                  READY     STATUS    RESTARTS   AGE
couchbase-operator-5bc785c54f-kh6c2   1/1       Running   0          22s
```
> **Do not proceed** to the next step until you see the `couchbase-operator` pod has status `RUNNING`. We use the `-w` option to watch the command, hit `ctrl + C` to escape.

```
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/secret.yaml
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/cluster-basic.yaml
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

![Basic Couchbase Cluster](https://github.com/couchbase-partners/redhat-pds/blob/release-1.0/img/cb-cluster-basic.png)

On the Pods page in OpenShift (https://master.couchbase.openshiftworkshop.com/console/project/operator-example/browse/pods):

![](https://github.com/couchbase-partners/redhat-pds/blob/release-1.0/img/os-cluster-basic.png)

### Failover Demo

Now that we have a cluster up with some data, we can demonstrate the operator in action.

First, delete one of the pods:

```
oc delete pod cb-example-0003
```

By deleting the pod, we are destroying one of the Couchbase nodes. At this point the operator should take over and try to recover the cluster to our desired state.

Couchbase recognizes that a node is missing and triggers fail-over:

![](https://github.com/couchbase-partners/redhat-pds/blob/release-1.0/img/failover-1.png)

Couchbase recognizes the new node coming online and begins rebalancing:

![](https://github.com/couchbase-partners/redhat-pds/blob/release-1.0/img/failover-2.png)

The rebalance continues until the cluster is fully healed.

![](https://github.com/couchbase-partners/redhat-pds/blob/release-1.0/img/failover-3.png)

## Support
> Couchbase Sales Questions: [sales@couchbase.com](mailto:sales@couchbase.com)

> Couchbase Technical Questions: [partners@couchbase.com](mailto:partners@couchbase.com)

> Features or Problems with above: [File a github issue](https://github.com/mwardRH/partner-field-kits/issues)

> RHPDS Questions: [rhpds-admins@redhat.com](mailto:rhpds-admins@redhat.com)

## Deploy an App
### Build and Deploy an App

![](img/couchbase-app-1.png)

> Note: In order to follow this section, you will need a twitter developer account. If you do not have an account, please contact evan.pease@couchbase.com and I will provide temporary credentials.

In order to help demonstrate the Couchbase Autonomous Operator in action, we'll deploy a simple real-time analytics application that ingests tweets from Twitter's API into Couchbase. We will then simulate a node failure and observe how the application and Couchbase respond.

The application is made up of 3 microservices:

1. Tweet Ingester Service - The tweet ingester is a Java application that consumes tweet in real-time from Twitter's APIs into Couchbase.
2. API Service - The API service is Java application that provides several REST end points for exposing data ingested by the Tweet Ingester Service. Under the hood, it is running SQL queries against Couchbase.
3. UI Service - The UI service is a simple Node server that serves a React SPA (single page application). The UI provides visualizations of the data provided by the API Service.

#### S2I Setup for Java Applications

First, import the `openjdk18-openshift` image. This is a S2I (source to image) builder. [S2I](https://access.redhat.com/documentation/en-us/red_hat_jboss_middleware_for_openshift/3/html-single/red_hat_java_s2i_for_openshift/index) will allow us to containerize and deploy an application on OpenShift without having to worry about writing a Dockerfile nor any yaml files!

```
oc import-image registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift --confirm
```

After importing this image, we'll be able to deploy Java applications straight from source code using Open Shift's `new-app` command.


#### Deploy the API Service

First, we'll deploy the API service.

```
oc new-app registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:latest~https://github.com/couchbase-partners/redhat-pds.git \
       -e COUCHBASE_CLUSTER=cb-example \
       -e COUCHBASE_USER=Administrator \
       -e COUCHBASE_PASSWORD=password \
       -e COUCHBASE_TWEET_BUCKET=tweets \
       --context-dir=cb-rh-twitter/twitter-api \
       --name=twitter-api
```

You can watch the build process by running `oc logs -f bc/twitter-api`. Once this is completed it will deploy a pod running the API service.

Now let's expose the API service so it is accessible publicly:

```
oc expose svc twitter-api
```

This should create a route to http://twitter-api-operator-example.apps.couchbase-<CLUSTER_ID>.openshiftworkshop.com. Open the URL http://twitter-api-operator-example.apps.couchbase-<CLUSTER_ID>.openshiftworkshop.com/tweetcount in your browser and you should see a number 0 in your browser. This is a simple API endpoint that returns the number of tweets ingested.

#### Deploy the UI Service

Next, we'll deploy the UI service. This service is a simple node server serving up a ReactJS app. For expediency, a Docker image is already built. We can also deploy Docker images directly with the `new-app` command:

```
oc new-app ezeev/twitter-ui:latest
```

This will deploy our UI service. Let's expose it so we can access it:

```
oc expose svc twitter-ui
```

This should expose a route to http://twitter-ui-operator-example.apps.couchbase-<CLUSTER_ID>.openshiftworkshop.com. Visit this link. You should see a dashboard load **with empty charts**. We will start populating them in the next step after deploying the Tweet Ingester Service.

Now, add the following request parameter to the URL in your browser: `?apiBase=<exposed route to API service>`. The complete URL should look like:

```
http://twitter-ui-operator-example.apps.couchbase-<CLUSTER_ID>.openshiftworkshop.com?apiBase=http://twitter-api-operator-example.apps.couchbase-<CLUSTER_ID>.openshiftworkshop.com
```


#### Deploy the Tweet Ingester Service

Now that we have our API and UI deployed, we are ready to start ingesting and visualizing twitter data! This is a Java application like the API service, so we will deploy it the exact same way:

```
oc new-app registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:latest~https://github.com/couchbase-partners/redhat-pds.git \
       -e TWITTER_CONSUMER_KEY=YOUR_CONSUMER_KEY \
       -e TWITTER_CONSUMER_SECRET=YOUR_CONSUMER_SECRET \
       -e TWITTER_TOKEN=YOUR_TOKEN \
       -e TWITTER_SECRET=YOUR_SECRET \
       -e TWITTER_FILTER='#RegisterToVote' \
       -e COUCHBASE_CLUSTER=cb-example \
       -e COUCHBASE_USER=Administrator \
       -e COUCHBASE_PASSWORD=password \
       -e COUCHBASE_TWEET_BUCKET=tweets \
       --context-dir=cb-rh-twitter/twitter-streamer \
       --name=twitter-streamer
```

You can watch the build with `oc logs -f bc/cb-rh-twitter`. When this is completed you should see a new pod created for the twitter streamer.

At this point you should also see new documents appearing in the tweets bucket in Couchbase, and in the UI at http://twitter-ui-operator-example.apps.couchbase-<CLUSTER_ID>.openshiftworkshop.com/.

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

To remove the twitter streaming app:

```
oc delete dc twitter-streamer
oc delete bc twitter-streamer
oc delete svc twitter-streamer
```

## Deploy a Cluster with Server Groups Enabled

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

## Cleanup

Delete the cluster before moving onto the next example:

`oc delete -f cluster-basic.yaml`
