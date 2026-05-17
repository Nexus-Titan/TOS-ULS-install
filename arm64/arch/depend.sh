#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root."
  exit 1
fi

echo "⏳ Updating package databases..."
pacman -Sy

echo "⏳ Installing Core Dependencies & Tools..."
pacman -S --noconfirm --needed cryptsetup util-linux gawk mkinitcpio coreutils curl git

echo "⏳ Installing Wayland Display Server Stack (No X11)..."
pacman -S --noconfirm --needed wayland wayland-protocols eglexternalplatform

echo "⏳ Installing ARM64 Hardware & GPU Drivers (AMD/Mesa Open Source)..."
pacman -S --noconfirm --needed mesa lib32-mesa-amber 2>/dev/null || pacman -S --noconfirm --needed mesa
pacman -S --noconfirm --needed xf86-video-amdgpu 2>/dev/null

echo "⏳ Installing Container Runtime & Distrobox..."
pacman -S --noconfirm --needed podman docker distrobox
systemctl enable --now docker.service

echo "⏳ Installing 100% Virtualization Stack (KVM/QEMU AArch64)..."
pacman -S --noconfirm --needed qemu-desktop qemu-emulators-full libvirt virt-manager dnsmasq iptables-nft
systemctl enable --now libvirtd.service

echo "⏳ Configuring Nested Virtualization for ARM64 KVM..."
if [ -d /sys/module/kvm ]; then
  echo "options kvm nested=1" > /etc/modprobe.d/kvm_nested.conf
  echo "✅ Nested KVM configured."
else
  echo "⚠️ KVM module not detected in kernel, skipping nested config."
fi

echo "✅ All dependencies, drivers, Wayland, Distrobox and VM-stacks successfully installed."
