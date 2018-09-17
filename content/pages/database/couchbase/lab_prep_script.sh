# /bin/
#!/usr/bin/env bash
# version: 0.1

#Sign in Section
read -p 'OpenShift Master URL: ' OCPMASTERURL

read -p 'OpenShift Admin Username (Default: opentlc-mgr): ' USERNAME
USERNAME=${USERNAME:-opentlc-mgr}

read -p 'OpenShift Admin Password: (Default: r3dh4t1!): ' PASSWORD
PASSWORD=${PASSWORD:-r3dh4t1!}

oc login --username=$USERNAME --password=$PASSWORD $OCPMASTERURL

#Create Project
echo "Prepping environment"
oc new-project operator-example

echo "Deploying CRD"
oc create -f crd.yaml

echo "Sleep for 5 minutes"
sleep 300

echo "Setting Permissions and pulling image"
oc create -f ./src/cluster-role-sa.yaml
oc create -f ./src/cluster-role-user.yaml
oc create serviceaccount couchbase-operator --namespace operator-example
oc create rolebinding couchbase-operator --clusterrole couchbase-operator --serviceaccount operator-example:couchbase-operator
oc adm policy add-scc-to-user anyuid system:serviceaccount:operator-example:couchbase-operator
oc create rolebinding couchbasecluster --clusterrole couchbasecluster --user developer --namespace operator-example
oc create clusterrolebinding couchbasecluster --clusterrole couchbasecluster --user developer
oc create secret docker-registry rh-catalog --docker-server=registry.connect.redhat.com --docker-username=redcouch --docker-password=openshift --docker-email=redcouchredhat@gmail.com
oc secrets add serviceaccount/couchbase-operator secrets/rh-catalog --for=pull
oc secrets add serviceaccount/default secrets/rh-catalog --for=pull

echo "Sleeping for 7 for the image to populate in the registry"
sleep 420


#Deploy Operator
echo "Deploying operator and secrets"
oc create -f ./src/operator.yaml
oc create -f ./src/secret.yaml

echo "Sleeping while the operator gets started."
sleep 180

echo "Exposing route"
oc expose service/cb-example-ui


# Working section.
#END=10 # Change this number to the number of users in the environment

#for i in $(seq 1 $END); do
#	oc create rolebinding couchbasecluster --clusterrole couchbasecluster --user $i --namespace operator-example
#	oc create clusterrolebinding couchbasecluster --clusterrole couchbasecluster --user $i
#done
