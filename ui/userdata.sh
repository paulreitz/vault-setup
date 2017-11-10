#!/bin/bash
sudo touch /etc/systemd/system/vaultui.service
sudo cat >/etc/systemd/system/vaultui.service <<EOL
[Unit]
Description=Vault UI
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --rm -p 80:8000 -e VAULT_URL_DEFAULT=${vault_endpoint} --name vault-ui djenriquez/vault-ui

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl enable vaultui.service
sudo systemctl start vaultui.service