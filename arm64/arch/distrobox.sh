#!/bin/bash

if [ "$EUID" -eq 0 ]; then
  echo "❌ Do not run this script as root! Distrobox and Homebrew must be configured as a normal user."
  exit 1
fi

CONTAINER_NAME="main"
CONTAINER_HOME="$HOME/distrobox/$CONTAINER_NAME"

echo "⏳ Creating isolated Home directory at $CONTAINER_HOME..."
mkdir -p "$CONTAINER_HOME"

echo "⏳ Creating Distrobox container '$CONTAINER_NAME' with isolated Home..."
distrobox create --name "$CONTAINER_NAME" --image debian:stable --home "$CONTAINER_HOME" --yes

echo "⏳ Configuring and installing components inside '$CONTAINER_NAME'..."

distrobox enter "$CONTAINER_NAME" -- bash -c '
  echo "⏳ Updating Debian package index..."
  sudo apt-get update && sudo apt-get install -y curl git build-essential procps flatpak

  echo "⏳ Configuring Flathub and Flatpak applications..."
  flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak --user install -y flathub com.valvesoftware.Steam
  flatpak --user install -y flathub com.github.tchx84.Flatseal

  if [ ! -d "$HOME/.linuxbrew" ] && [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
    echo "⏳ Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"" >> ~/.bashrc
  else
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    echo "eval \"\$($HOME/.linuxbrew/bin/brew shellenv)\"" >> ~/.bashrc
  fi

  echo "⏳ Tapping repositories and installing packages via Brew..."
  
  brew tap Nexus-Titan/tab https://github.com/Nexus-Titan/homebrew-tap.git
  brew update
  brew install nexus-titan

  brew tap tiwut/tab https://github.com/tiwut/homebrew-tap.git
  brew update
  brew install tiwut-launcher

  echo "✅ Inside container configuration finished!"
'

echo "✅ Distrobox '$CONTAINER_NAME' is fully configured with its own Home directory."
