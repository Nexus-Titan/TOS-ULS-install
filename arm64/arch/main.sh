#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root."
  exit 1
fi

KEY_DIR="/tos/install/keys"
SCRIPT_DIR="/tos/install/scripts"

REAL_USER=${SUDO_USER:-$USER}
if [ "$REAL_USER" = "root" ]; then
  REAL_USER="tosuser"
  if ! id -u "$REAL_USER" &>/dev/null; then
    echo "⏳ Creating dedicated system user '$REAL_USER'..."
    useradd -m -G wheel -s /bin/bash "$REAL_USER"
    echo "$REAL_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  fi
fi
REAL_HOME=$(eval echo ~$REAL_USER)

echo "⏳ Cleaning up system (removing non-essential packages)..."
KEEP_PKGS="^cryptsetup$|^util-linux$|^gawk$|^mkinitcpio$|^coreutils$|^base$|^base-devel$|^linux$|^linux-firmware$|^grub$|^efibootmgr$|^dhcpcd$|^networkmanager$|^systemd$|^pacman$|^curl$|^git$|^wayland$|^weston$|^sway$|^distrobox$|^docker$|^podman$|^mesa$|^libvirt$|^qemu-desktop$|^virt-manager$|^libassuan$|^pinentry$"

TARGETS=$(pacman -Qqe | grep -Ev "$KEEP_PKGS")

if [ -n "$TARGETS" ]; then
  echo "Removing: $TARGETS"
  pacman -Rns --noconfirm $TARGETS 2>/dev/null
  pacman -Rns --noconfirm $(pacman -Qtdq) 2>/dev/null
  echo "✅ System cleaned."
else
  echo "✅ System is already minimal."
fi

mkdir -p "$KEY_DIR" "$SCRIPT_DIR"

chmod 755 /tos
chmod 755 /tos/install
chmod 755 "$SCRIPT_DIR"
chmod 700 "$KEY_DIR"

echo "⏳ Downloading and running Dependencies Script (depend.sh)..."
if curl -sSLf https://nexus-titan.github.io/TOS-ULS-install/arm64/arch/depend.sh -o "$SCRIPT_DIR/depend.sh"; then
  chmod +x "$SCRIPT_DIR/depend.sh"
  SUDO_USER="$REAL_USER" "$SCRIPT_DIR/depend.sh"
else
  echo "❌ Error downloading depend.sh"
  exit 1
fi

echo "⏳ Downloading Distrobox Setup Script (distrobox.sh)..."
if curl -sSLf https://nexus-titan.github.io/TOS-ULS-install/arm64/arch/distrobox.sh -o "$SCRIPT_DIR/distrobox.sh"; then
  chmod +x "$SCRIPT_DIR/distrobox.sh"
  chown "$REAL_USER":"$REAL_USER" "$SCRIPT_DIR/distrobox.sh"
  
  echo "⏳ Executing Distrobox Setup as user '$REAL_USER'..."
  su - "$REAL_USER" -c "/bin/bash $SCRIPT_DIR/distrobox.sh"
else
  echo "❌ Error downloading distrobox.sh"
  exit 1
fi

chmod 700 /tos /tos/install "$SCRIPT_DIR"

echo "⏳ Downloading Root Manager..."
if curl -sSLf https://nexus-titan.github.io/TOS-ULS-install/arm64/arch/root-mgr.sh -o "$SCRIPT_DIR/root-mgr.sh"; then
  echo "✅ Download successful."
  chmod +x "$SCRIPT_DIR/root-mgr.sh"
  echo "⚙️ Running Root Manager..."
  "$SCRIPT_DIR/root-mgr.sh"
else
  echo "❌ Error downloading Root Manager."
  exit 1
fi
