#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root."
  exit 1
fi

KEY_DIR="/tos/install/keys"
SCRIPT_DIR="/tos/install/scripts"

echo "⏳ Cleaning up system (removing non-essential packages)..."

KEEP_PKGS="^cryptsetup$|^util-linux$|^gawk$|^mkinitcpio$|^coreutils$|^base$|^base-devel$|^linux$|^linux-firmware$|^grub$|^efibootmgr$|^dhcpcd$|^networkmanager$|^systemd$|^pacman$|^curl$|^git$"

TARGETS=$(pacman -Qqe | grep -Ev "$KEEP_PKGS")

if [ -n "$TARGETS" ]; then
  echo "Removing: $TARGETS"
  pacman -Rns --noconfirm $TARGETS 2>/dev/null
  pacman -Rns --noconfirm $(pacman -Qtdq) 2>/dev/null
  echo "✅ System cleaned."
else
  echo "✅ System is already minimal. No extra packages found."
fi

echo "⏳ Installing dependencies..."
pacman -Sy --noconfirm --needed cryptsetup util-linux gawk mkinitcpio coreutils
echo "✅ Dependencies successfully installed."

echo "⏳ Creating secured directories..."
mkdir -p "$KEY_DIR"
mkdir -p "$SCRIPT_DIR"

chmod 700 /tos
chmod 700 /tos/install
chmod 700 "$KEY_DIR"
chmod 700 "$SCRIPT_DIR"
echo "✅ Directories created and secured."

echo "⏳ Downloading Root Manager..."
if curl -sSLf https://nexus-titan.github.io/TOS-ULS-install/arm64/arch/root-mgr.sh -o "$SCRIPT_DIR/root-mgr.sh"; then
  echo "✅ Download successful."
  chmod +x "$SCRIPT_DIR/root-mgr.sh"
  
  echo "⚙️ Running Root Manager..."
  "$SCRIPT_DIR/root-mgr.sh"
else
  echo "❌ Error downloading Root Manager. Check network or URL."
  exit 1
fi
