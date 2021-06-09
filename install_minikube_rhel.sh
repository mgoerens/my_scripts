#!/bin/bash

PUBLIC_IP=$1

### RUN AS ROOT USER - TODO: Test as normal user

sudo yum update -y

# Install pre requisites

# yum install -y  yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# This version of docker is needed for minikube version: v1.20.0
sudo yum install -y iptables docker-ce-3:19.03.15-3.el8 docker-ce-cli-1:19.03.15-3.el8 containerd.io conntrack

cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF


curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo rpm -Uvh minikube-latest.x86_64.rpm
minikube start --apiserver-ips $PUBLIC_IP --vm-driver=none

minikube status

systemctl enable kubelet.service
systemctl enable docker.service

