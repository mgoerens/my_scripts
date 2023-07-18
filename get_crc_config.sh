#!/bin/bash

# use first: crc config set kubeadmin-password <password_you_prefer>
if [ `crc status | awk '{if ($1 == "OpenShift:") print $2}'` == "Running" ]; then
#  export PATH="/home/mgoerens/.crc/bin/oc:\$PATH"
  oc login -u kubeadmin -p kubeadmin https://api.crc.testing:6443
else
  echo "CRC not Running"
  exit 1
fi

oc config view --raw >> ~/dev/kubeconfigs/crc_config

echo "CRC kubeconfig successfully saved under ~/dev/kubeconfigs/crc_config"
