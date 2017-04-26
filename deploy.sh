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

echo -e "Deleting previous version of iot4i-deployment if it exists"
kubectl delete --ignore-not-found=true   -f iot4i-deployment.yml

echo -e "Creating pods"
kubectl create -f iot4i-deployment.yml

PORT=$(kubectl get services | grep iot4i | sed 's/.*://g' | sed 's/\/.*//g')

echo ""
echo "View the iot4i-deployment at http://$IP_ADDR:$PORT"
