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
      read -p "Enter the OpenShift Admin User Name: " User
      read -s -p "Password: " password
      echo accepted
      cls
else
      cls
fi

cat src/logo.txt

echo "Logging into $OCP"
oc login --username=opentlc-mgr --password=r3dh4t1! $OCP
cls

echo "oc create -f crd.yaml"
read -p "Deploy CRD into OpenShift Environment" 
oc create -f https://raw.githubusercontent.com/couchbase-partners/redhat-pds/release-1.0/crd.yaml

read -p "Finish environment prep"
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

