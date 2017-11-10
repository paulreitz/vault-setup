#!/bin/bash
sudo touch /etc/vault/vault-config.hcl
sudo cat >/etc/vault/vault-config.hcl <<EOL
listener "tcp" {
    address = "0.0.0.0:8200"
    tls_disable = 1
}

backend "s3" {
    access_key = "${aws_access_key}"
    secret_key = "${aws_secret_key}"
    bucket = "${bucket_name}"
    region = "${bucket_region}"
}
EOL

sudo touch /etc/systemd/system/vault.service
sudo cat >/etc/systemd/system/vault.service <<EOL
[Unit]
Description=vault server
Requires=network-online.target
After=network-online.target consul.service

[Service]
Restart=always
ExecStart=/usr/bin/vault server -config=/etc/vault/vault-config.hcl

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl enable vault.service
sudo systemctl start vault.service
