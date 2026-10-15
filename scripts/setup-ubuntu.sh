#!/usr/bin/env bash
# Menyiapkan Ubuntu 24.04: git, make, Docker Engine + Compose plugin (repo resmi Docker).
set -euo pipefail

sudo apt-get update
sudo apt-get install -y ca-certificates curl git make

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"

echo
echo "Selesai. LOGOUT/LOGIN dulu (atau jalankan: newgrp docker) agar docker bisa dipakai tanpa sudo."
echo "VS Code (opsional):  sudo snap install code --classic"
