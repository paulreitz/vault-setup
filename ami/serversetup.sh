#!/bin/bash
cd ~
sudo apt-get update
sudo apt-get install -y curl unzip

curl -s https://releases.hashicorp.com/vault/0.8.3/vault_0.8.3_linux_amd64.zip > vault_0.8.3_linux_amd64.zip

unzip vault_0.8.3_linux_amd64.zip
sudo mv vault /usr/bin/vault
rm vault_0.8.3_linux_amd64.zip

sudo mkdir -p /etc/vault