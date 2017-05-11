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

echo -e "Check if deployment exists for app " $IOT4I_APP_NAME
kubectl get deployments | grep $IOT4I_APP_NAME
if [ $? -ne 0 ]; then
  echo -e "App not deployed to cluster yet, creating pods"
  kubectl create -f iot4i-deployment.yml
else
  echo -e "App already deployed to cluster, updating it..."
  bx ic init
  bx ic info
  bx ic images
  LATEST_APP_VERSION=$(bx ic images | grep $IOT4I_APP_NAME | sort -rnk2 | awk '!x[$1]++' | awk '{print $2}')
  # set the new version to the deployment, this would perform a red/black update
  kubectl set image deployment $IOT4I_APP_NAME $IOT4I_APP_NAME=registry.ng.bluemix.net/iot4i_v2/$IOT4I_APP_NAME:$LATEST_APP_VERSION
fi

PORT=$(kubectl get services | grep $SERVICE_NAME | sed 's/.*://g' | sed 's/\/.*//g')

echo ""
echo "View the iot4i-deployment at http://$IP_ADDR:$PORT"
