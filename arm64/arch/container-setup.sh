#!/bin/bash

echo "⏳ [Container] Updating Debian package index..."

if command -v sudo &> /dev/null; then
  sudo apt-get update && sudo apt-get install -y curl git build-essential procps flatpak
else
  apt-get update && apt-get install -y curl git build-essential procps flatpak
fi

echo "⏳ [Container] Configuring Flathub and Flatpak applications..."
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user install -y flathub com.valvesoftware.Steam
flatpak --user install -y flathub com.github.tchx84.Flatseal

echo "⏳ [Container] Checking Homebrew installation..."
if [ ! -d "$HOME/.linuxbrew" ] && [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
  echo "⏳ [Container] Installing Homebrew..."
  echo "" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "⏳ [Container] Activating Homebrew environment..."
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  grep -q "brew shellenv" ~/.bashrc || echo "eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"" >> ~/.bashrc
else
  eval "$($HOME/.linuxbrew/bin/brew shellenv)"
  grep -q "brew shellenv" ~/.bashrc || echo "eval \"\$($HOME/.linuxbrew/bin/brew shellenv)\"" >> ~/.bashrc
fi

echo "⏳ [Container] Tapping repositories and installing packages via Brew..."
brew tap Nexus-Titan/tab https://github.com/Nexus-Titan/homebrew-tap.git
brew update
brew install nexus-titan

brew tap tiwut/tab https://github.com/tiwut/homebrew-tap.git
brew update
brew install tiwut/tab/tiwut-launcher

echo "✅ [Container] Inside container configuration successfully finished!"
