#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root."
  exit 1
fi

echo "⏳ Step 0: Optimizing Pacman for slow/unstable mirrors..."
if ! grep -q "^DisableSandbox" /etc/pacman.conf; then
  sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf
fi
if ! grep -q "^XferCommand = /usr/bin/curl" /etc/pacman.conf; then
  sed -i '/^\[options\]/a XferCommand = /usr/bin/curl -L -C - --retry 5 --retry-delay 3 -f %u -o %o' /etc/pacman.conf
  echo "✅ Pacman download retries configured."
fi

echo "⏳ Step 1: Initializing and updating pacman keyring..."
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Sy --noconfirm --needed archlinuxarm-keyring

echo "⏳ Step 2: Performing FULL system upgrade..."
pacman -Su --noconfirm --overwrite '*'

echo "⏳ Step 3: Installing Core Dependencies & Tools..."
pacman -S --noconfirm --needed --overwrite '*' cryptsetup util-linux gawk mkinitcpio coreutils curl git

echo "⏳ Step 4: Installing Wayland Display Server Stack..."
pacman -S --noconfirm --needed --overwrite '*' wayland wayland-protocols eglexternalplatform

echo "⏳ Step 5: Installing ARM64 Hardware & GPU Drivers..."
pacman -S --noconfirm --needed --overwrite '*' mesa 2>/dev/null || pacman -S --noconfirm --needed --overwrite '*' mesa
pacman -S --noconfirm --needed --overwrite '*' xf86-video-amdgpu 2>/dev/null

echo "⏳ Step 6: Installing Container Runtime & Distrobox..."
pacman -S --noconfirm --needed --overwrite '*' crun podman docker distrobox fuse-overlayfs slirp4netns

echo "⏳ Fixing Rootless Container Permissions (SubUID/SubGID & Storage)..."
TARGET_USER=${SUDO_USER:-tosuser}

touch /etc/subuid /etc/subgid
if ! grep -q "^$TARGET_USER:" /etc/subuid; then
  echo "$TARGET_USER:100000:65536" >> /etc/subuid
  echo "$TARGET_USER:100000:65536" >> /etc/subgid
fi

mkdir -p /etc/containers
cat <<EOF > /etc/containers/storage.conf
[storage]
driver = "overlay"
[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF

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

echo "⏳ Step 7: Installing Native ARM64 Virtualization Stack..."
pacman -S --noconfirm --needed --overwrite '*' qemu-base qemu-system-aarch64 libvirt virt-manager dnsmasq iptables-nft

systemctl enable --now libvirtd.service 2>/dev/null || systemctl start libvirtd.service

echo "⏳ Step 8: Configuring Nested Virtualization for ARM64 KVM..."
if [ -d /sys/module/kvm ]; then
  echo "options kvm nested=1" > /etc/modprobe.d/kvm_nested.conf
  echo "✅ Nested KVM configured."
else
  echo "⚠️ KVM module not detected in kernel, skipping nested config."
fi

echo "✅ All core dependencies and drivers successfully installed."
