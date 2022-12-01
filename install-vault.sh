#!/bin/bash

if [ $1 ]; then
  if [ $1 != "int" ] && [ $1 != "prod" ]; then
    echo 'One argument is required: int | prod'
    exit 1
  fi
else
  echo 'One argument is required: int | prod'
  exit 1
fi

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault-${1} hashicorp/vault -n vault-${1} --set global.openshift=true,server.dev.enabled=true,server.route.enabled=true,server.route.host="" --create-namespace
oc patch route vault-${1} -p '{"spec":{"tls": null}}' -n vault-${1}
oc -n vault-${1} wait --for=condition=Ready pod/vault-${1}-0
export VAULT_ADDR=http://vault-${1}-vault-${1}.apps-crc.testing
export VAULT_TOKEN=root
terraform -chdir=vault/${1} init
terraform -chdir=vault/${1} apply -auto-approve
