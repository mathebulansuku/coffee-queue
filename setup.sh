#!/usr/bin/env bash

set -euo pipefail

echo "=== Coffee Queue local environment setup (Ubuntu) ==="

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "[1/4] Updating apt package index..."
$SUDO apt-get update -y

echo "[2/4] Installing base dependencies..."
$SUDO apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https

echo "[3/4] Installing Docker Engine (if missing)..."
if ! command -v docker >/dev/null 2>&1; then
  # Docker repository setup (following Docker docs for Ubuntu)
  $SUDO install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

  $SUDO apt-get update -y
  $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "Docker already installed, skipping."
fi

if [[ -n "${SUDO}" ]]; then
  echo "Adding current user to docker group (you may need to log out/in)..."
  $SUDO usermod -aG docker "$USER" || true
fi

echo "[4/4] Installing kubectl (if missing)..."
if ! command -v kubectl >/dev/null 2>&1; then
  KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  $SUDO install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
else
  echo "kubectl already installed, skipping."
fi

echo "Installing Minikube (if missing)..."
if ! command -v minikube >/dev/null 2>&1; then
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  $SUDO install minikube-linux-amd64 /usr/local/bin/minikube
  rm minikube-linux-amd64
else
  echo "Minikube already installed, skipping."
fi

echo
echo "=== Setup complete ==="
echo "- Docker, kubectl, and Minikube should now be installed."
echo "- Log out and back in for docker group changes to take effect."
echo "- To start a local cluster: minikube start --cpus=2 --memory=4096"

