#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

echo "WARNING: Do you really want to install TiwutOS-ULS?"
echo "This action is IRREVERSIBLE."
echo "The system will be permanently locked down."
read -p "Type YES to proceed: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  exit 1
fi

ROOT_PASS=$(tr -dc 'a-zA-Z0-9!@#$%^&*()_+~|}{[]:;?><,./-=' < /dev/urandom | head -c 256)
echo "root:$ROOT_PASS" | chpasswd
passwd -l root

sysctl -w kernel.modules_disabled=1
sysctl -w kernel.sysrq=0
sysctl -w kernel.unprivileged_bpf_disabled=1
sysctl -w kernel.kptr_restrict=2
sysctl -w kernel.dmesg_restrict=1

LUKS_PASS=$(tr -dc 'a-zA-Z0-9!@#$%^&*()_+~|}{[]:;?><,./-=' < /dev/urandom | head -c 512)
KEYFILE="/etc/luks.key"
echo -n "$LUKS_PASS" > "$KEYFILE"
chmod 400 "$KEYFILE"

ROOT_MAPPER=$(findmnt -n -o SOURCE /)

if [[ "$ROOT_MAPPER" == /dev/mapper/* ]]; then
  CRYPT_NAME=$(basename "$ROOT_MAPPER")
  UNDERLYING_DEV=$(cryptsetup status "$CRYPT_NAME" | awk '/device:/ {print $2}')
  
  echo -n "$LUKS_PASS" | cryptsetup luksAddKey "$UNDERLYING_DEV" -
  
  echo "$CRYPT_NAME $UNDERLYING_DEV $KEYFILE luks" > /etc/crypttab
  
  if grep -q "^FILES=" /etc/mkinitcpio.conf; then
    sed -i "s|^FILES=(|FILES=($KEYFILE |" /etc/mkinitcpio.conf
  else
    echo "FILES=($KEYFILE)" >> /etc/mkinitcpio.conf
  fi
  
  mkinitcpio -P
fi

unset ROOT_PASS
unset LUKS_PASS
history -c
