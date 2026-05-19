#!/usr/bin/env bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "🛑 Error: This script must be run as root!"
  exit 1
fi

echo "🚀 Starting KDE Plasma installation for Arch Linux ARM64 🐧"

echo "🔄 Synchronizing package databases and updating system..."
pacman -Syu --noconfirm

echo "📦 Installing KDE Plasma, SDDM, and essential apps..."
pacman -S --needed --noconfirm plasma sddm konsole dolphin

echo "⚙️ Enabling SDDM display manager service..."
systemctl enable sddm.service

echo "✨ KDE Plasma installation successful! 🎉"
