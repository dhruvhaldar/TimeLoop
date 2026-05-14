#!/bin/bash
set -e
echo "Updating apt..."
apt-get update
echo "Installing prerequisites..."
apt-get install -y ca-certificates curl
echo "Adding Docker's official GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "Adding the repository to apt sources..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" > /etc/apt/sources.list.d/docker.list

echo "Updating apt with new repo..."
apt-get update

echo "Installing Docker..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Adding user $SUDO_USER to docker group..."
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER"
fi
echo "Docker installation complete!"
