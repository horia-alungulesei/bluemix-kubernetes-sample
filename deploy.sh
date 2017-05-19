#!/bin/bash

echo "Create iot4i-deployment"
IP_ADDR=$(bx cs workers $CLUSTER_NAME | grep normal | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
exp=$(bx cs cluster-config $CLUSTER_NAME | grep export)
if [ $? -ne 0 ]; then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

echo -e "Downloading iot4i-deployment.yml from" $1
curl --silent $1 > iot4i-deployment.yml

echo -e "Check if deployment exists for app " $CF_APP
kubectl get deployments | grep $CF_APP
if [ $? -ne 0 ]; then
  echo -e "App not deployed to cluster yet, creating pods"
  kubectl create -f iot4i-deployment.yml
else
  echo -e "App already deployed to cluster, updating it..."
  LATEST_APP_VERSION=$(bx cr images | grep $CF_APP | sort -rnk3 | awk '!x[$1]++' | awk '{print $3}')
  # set the new version to the deployment, this would perform a red/black update
  kubectl set image deployment $CF_APP $CF_APP=registry.ng.bluemix.net/iot4i_v2/$CF_APP:$LATEST_APP_VERSION
fi

PORT=$(kubectl get services | grep $SERVICE_NAME | sed 's/.*://g' | sed 's/\/.*//g')

echo ""
echo "View the iot4i-deployment at http://$IP_ADDR:$PORT"
