#!/usr/bin/env bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "🛑 Error: This script must be run as root!"
  exit 1
fi

echo "🚀 Starting GNOME installation for Arch Linux ARM64 🐧"

echo "🔄 Synchronizing package databases and updating system..."
pacman -Syu --noconfirm

echo "📦 Installing GNOME and GDM..."
pacman -S --needed --noconfirm gnome gdm

echo "⚙️ Enabling GDM display manager service..."
systemctl enable gdm.service

echo "✨ GNOME installation successful! 🎉"
