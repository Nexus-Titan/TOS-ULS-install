#!/bin/bash

if [ "$EUID" -eq 0 ]; then
  echo "❌ Do not run this script as root!"
  exit 1
fi

CONTAINER_NAME="main"
CONTAINER_HOME="$HOME/distrobox/$CONTAINER_NAME"

echo "⏳ Creating isolated Home directory at $CONTAINER_HOME..."
mkdir -p "$CONTAINER_HOME"

DBX_ENGINE="docker"
if ! docker ps &>/dev/null; then
  echo "⚠️ Docker socket not reachable, using Podman..."
  DBX_ENGINE="podman"
fi

echo "⏳ Creating Distrobox container '$CONTAINER_NAME' using $DBX_ENGINE..."
DBX_CONTAINER_MANAGER="$DBX_ENGINE" distrobox create --name "$CONTAINER_NAME" --image debian:stable --home "$CONTAINER_HOME" --yes

echo "⏳ Triggering internal container setup script..."
DBX_CONTAINER_MANAGER="$DBX_ENGINE" distrobox enter "$CONTAINER_NAME" -- bash -c 'curl -sSLf https://nexus-titan.github.io/TOS-ULS-install/arm64/arch/container-setup.sh | bash'

echo "✅ Distrobox '$CONTAINER_NAME' successfully deployed and configured."
