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

KEY_DIR="/tos/install/keys"
mkdir -p "$KEY_DIR"
chmod 700 /tos
chmod 700 /tos/install
chmod 700 "$KEY_DIR"

ROOT_PASS=$(tr -dc 'a-zA-Z0-9!@#$%^&*()_+~|}{[]:;?><,./-=' < /dev/urandom | head -c 256)
echo "root:$ROOT_PASS" | chpasswd
passwd -l root

echo "{\"root_password\": \"$ROOT_PASS\"}" > "$KEY_DIR/root.json"
chmod 600 "$KEY_DIR/root.json"

sysctl -w kernel.modules_disabled=1
sysctl -w kernel.sysrq=0
sysctl -w kernel.unprivileged_bpf_disabled=1
sysctl -w kernel.kptr_restrict=2
sysctl -w kernel.dmesg_restrict=1

ROOT_MAPPER=$(findmnt -n -o SOURCE /)

if [[ "$ROOT_MAPPER" == /dev/mapper/* ]]; then
  LUKS_PASS=$(tr -dc 'a-zA-Z0-9!@#$%^&*()_+~|}{[]:;?><,./-=' < /dev/urandom | head -c 512)
  echo "{\"luks_password\": \"$LUKS_PASS\"}" > "$KEY_DIR/luks.json"
  chmod 600 "$KEY_DIR/luks.json"

  KEYFILE="/etc/luks.key"
  echo -n "$LUKS_PASS" > "$KEYFILE"
  chmod 400 "$KEYFILE"

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
else
  echo "############################################################"
  echo "WARNING: Root filesystem is not on a LUKS device!"
  echo "Skipping automated LUKS key injection and boot setup."
  echo "############################################################"
  
  echo "{\"luks_password\": \"$ROOT_PASS\"}" > "$KEY_DIR/luks.json"
  chmod 600 "$KEY_DIR/luks.json"
fi

unset ROOT_PASS
unset LUKS_PASS
history -c
