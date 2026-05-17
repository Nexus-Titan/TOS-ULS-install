#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root."
  exit 1
fi

echo "⏳ Syncing database..."
pacman -Sy

echo "⏳ Installing Core Dependencies & Tools (with non-destructive overwrites)..."
pacman -S --noconfirm --needed --overwrite '*' cryptsetup util-linux gawk mkinitcpio coreutils curl git

echo "⏳ Installing Wayland Display Server Stack (No X11)..."
pacman -S --noconfirm --needed --overwrite '*' wayland wayland-protocols eglexternalplatform

echo "⏳ Installing ARM64 Hardware & GPU Drivers..."
pacman -S --noconfirm --needed --overwrite '*' mesa 2>/dev/null || pacman -S --noconfirm --needed --overwrite '*' mesa
pacman -S --noconfirm --needed --overwrite '*' xf86-video-amdgpu 2>/dev/null

echo "⏳ Installing Container Runtime & Distrobox..."
pacman -S --noconfirm --needed --overwrite '*' crun podman docker distrobox

if grep -q "^docker:" /etc/group; then
  echo "✅ Docker group exists."
else
  groupadd docker
fi

systemctl daemon-reload
systemctl enable --now docker.service 2>/dev/null || systemctl start docker.service

if [ -n "$SUDO_USER" ]; then
  usermod -aG docker "$SUDO_USER"
fi

echo "⏳ Installing Native ARM64 Virtualization Stack..."
pacman -S --noconfirm --needed --overwrite '*' qemu-server qemu-system-aarch64 libvirt virt-manager dnsmasq iptables-nft

systemctl enable --now libvirtd.service 2>/dev/null || systemctl start libvirtd.service

echo "⏳ Configuring Nested Virtualization for ARM64 KVM..."
if [ -d /sys/module/kvm ]; then
  echo "options kvm nested=1" > /etc/modprobe.d/kvm_nested.conf
  echo "✅ Nested KVM configured."
else
  echo "⚠️ KVM module not detected in kernel, skipping nested config."
fi

echo "✅ All core dependencies and drivers successfully installed."
