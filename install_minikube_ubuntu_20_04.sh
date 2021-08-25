#!/bin/bash

### To test, if permission errors persist remove sudo and run as root

sudo apt update
sudo apt install -y jq haveged python3-pip conntrack docker.io

sudo usermod -a -G docker ubuntu
#sudo groupadd wheel
#sudo echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/99-wheel
#sudo usermod -a -G wheel ubuntu

kubectl_latest_version=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`
curl -LO https://storage.googleapis.com/kubernetes-release/release/${kubectl_latest_version}/bin/linux/amd64/kubectl
sudo mv kubectl /usr/local/bin

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

### TODO: IP as param
minikube start --apiserver-ips 3.68.116.139 --vm-driver=none --apiserver-port 8443 --kubernetes-version=latest

kubectl version
