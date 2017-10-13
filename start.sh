#!/bin/bash

#THECMD=$0

if [[ "" == ${AZURE_CLIENT_ID} ]]; then
  echo "You need to specify a AZURE_CLIENT_ID"
  exit 1
fi

if [[ "" == ${AZURE_CLIENT_SECRET} ]]; then
  echo "You need to specify a AZURE_CLIENT_SECRET"
  exit 1
fi

if [[ "" == ${AZURE_TENANT_ID} ]]; then
  echo "You need to specify a AZURE_TENANT_ID"
  exit 1
fi

if [[ "" == ${AZURE_SUBSCRIPTION_ID} ]]; then
  echo "You need to specify a AZURE_SUBSCRIPTION_ID"
  exit 1
fi

if [[ "" == ${TIMER} ]]; then
  echo "No timer specified, default value = 60 sec"
  TIMER=300
fi

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID >> /dev/null
az account list-locations --query '[].name' -o tsv > ./resources/locations.txt
az account set -s $AZURE_SUBSCRIPTION_ID

if [[ "True" == ${GENERATE} ]]; then
  if [[ "" == ${PREFIX} ]]; then
    echo "You didn't specify any prefix for your visu, this could cause some problems if you are monitoring multiple subscriptions"
  fi
  sh generate.sh
  exit 1
fi

dir="./metrics"
while true
do
  for f in "$dir"/*; do
    sh $f &
  done
  sleep $TIMER
done

