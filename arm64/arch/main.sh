#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root."
  exit 1
fi

BASE_DIR=$(dirname "$(realpath "$0")")
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

echo "⏳ Cleaning up system safely..."
KEEP_PKGS="^cryptsetup$|^util-linux$|^gawk$|^mkinitcpio$|^coreutils$|^base$|^base-devel$|^linux$|^linux-firmware$|^grub$|^efibootmgr$|^dhcpcd$|^networkmanager$|^systemd$|^pacman$|^curl$|^git$|^wayland$|^weston$|^sway$|^distrobox$|^docker$|^podman$|^mesa$|^libvirt$|^qemu-desktop$|^virt-manager$|^libassuan$|^pinentry$|^gnupg$|^gpgme$"

TARGETS=$(pacman -Qqe | grep -Ev "$KEEP_PKGS")

if [ -n "$TARGETS" ]; then
  echo "Removing non-essential packages..."
  pacman -Rn --noconfirm $TARGETS 2>/dev/null
  echo "✅ System cleaned."
else
  echo "✅ System is already minimal."
fi

mkdir -p "$KEY_DIR" "$SCRIPT_DIR"
chmod 755 /tos /tos/install "$SCRIPT_DIR"
chmod 700 "$KEY_DIR"

echo "⏳ Loading local scripts from $BASE_DIR..."
for script in depend.sh distrobox.sh root-mgr.sh container-setup.sh; do
    if [ -f "$BASE_DIR/$script" ]; then
        cp "$BASE_DIR/$script" "$SCRIPT_DIR/"
        chmod +x "$SCRIPT_DIR/$script"
    else
        echo "❌ Error: $script not found in $BASE_DIR!"
        exit 1
    fi
done

echo "⏳ Running Dependencies Script (depend.sh)..."
SUDO_USER="$REAL_USER" "$SCRIPT_DIR/depend.sh"

echo "⏳ Executing Distrobox Setup as user '$REAL_USER'..."
chown "$REAL_USER":"$REAL_USER" "$SCRIPT_DIR/distrobox.sh"
su - "$REAL_USER" -c "/bin/bash $SCRIPT_DIR/distrobox.sh"

echo ""
echo "🖥️  Select Desktop Environment to install:"
echo "1) GNOME"
echo "2) KDE Plasma"
echo "3) Skip / None"
read -p "Enter choice [1-3]: " DE_CHOICE

case $DE_CHOICE in
  1)
    if [ -f "$BASE_DIR/desk-env/gnome/main.sh" ]; then
      echo "⏳ Launching GNOME Setup..."
      chmod +x "$BASE_DIR/desk-env/gnome/main.sh"
      "$BASE_DIR/desk-env/gnome/main.sh"
    else
      echo "❌ Error: GNOME script missing at $BASE_DIR/desk-env/gnome/main.sh"
    fi
    ;;
  2)
    if [ -f "$BASE_DIR/desk-env/KDE-Plasma/main.sh" ]; then
      echo "⏳ Launching KDE Plasma Setup..."
      chmod +x "$BASE_DIR/desk-env/KDE-Plasma/main.sh"
      "$BASE_DIR/desk-env/KDE-Plasma/main.sh"
    else
      echo "❌ Error: KDE Plasma script missing at $BASE_DIR/desk-env/KDE-Plasma/main.sh"
    fi
    ;;
  *)
    echo "⏭️  Skipping Desktop Environment installation."
    ;;
esac

chmod 700 /tos /tos/install "$SCRIPT_DIR"

echo "⚙️ Running Root Manager..."
"$SCRIPT_DIR/root-mgr.sh"
