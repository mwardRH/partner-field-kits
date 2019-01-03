########
# Title: Partner Field Kit - Couchbase Tutorial
# Author: Matthew Ward (https://github.com/mwardRH) 
# Special Thanks: Evan Pease (https://github.com/ezeev)
# 
# Content Link: https://github.com/mwardRH/partner-field-kits/tree/master/content/pages/database/couchbase
# See content link for system requirements. 
#
# NOTE: REQUIREMENT - You must put the URI for OpenShift as the following environment variable. This script relies on this env variable to exist to complete. 
# export OCP=https://master.mward.openshiftworkshop.com
########

export OCP=
export OCPAdminUser=
export OCPAdminPwd=

if [ -z "$OCP" ]
then
      read -p "Enter the OpenShift Server Name: " OCP
      read -p "Enter the OpenShift Admin User Name: " OCPUSER
      read -s -p "Password: " OCPPASSWORD
      echo accepted
      cls
else
      cls
fi

cat src/logo.txt

echo "Logging into $OCP"
oc login --username=$OCPUSER --password=$OCPPASSWORD $OCP
cls

echo "oc create -f crd.yaml"
read -p "Deploy CRD into OpenShift Environment. " CRD
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/crd.yaml

# If value is null it will skip the curl.
if [ -z "$CRD" ]
then
    curl https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/crd.yaml
fi

read -p "Finish environment prep "
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
cls

read -p "Create a project called operator-example "
oc project operator-example

read -p "Let's take a look at the the operator " OPERATOR
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/operator.yaml

# If value is null it will skip the curl.
if [ -z "$CRD" ]
then
    curl https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/operator.yaml
fi

read -p "DO NOT PROCEED until you see the couchbase-operator pod has status RUNNING. ctrl+C to escape."
oc get pods -w
cls

read -p "Deploy Secrets and a basic Couchbase cluster. You should start seeing Couchbase pods appearing immediately. It will take a couple of minutes for the cluster to be ready. "
oc get pods -w

cls 

read -p "Expose the route to the public URL "
oc expose service/cb-example-ui

read -p "Get the route to the Couchbase UI "
oc get routes

cls 

echo "The username is: Administrator"
echo "The password is: password"
read -p "Open your browswer and naviagate to the Couchbase UI. "

cls

echo "Now we are going to fail a node."
echo "OpenShift's replication controller will detect and correct to the state."
echo "Couchbase and it's Operator will detect the new pod and automatically rebalance the node "
read -p "Ready?"

oc delete pod cb-example-0001

echo "Go back to the couchbase panel and watch how it recovers from faulure. "
