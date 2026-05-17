#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

pacman -Sy --noconfirm --needed cryptsetup util-linux gawk mkinitcpio coreutils



echo "Dependencies for TiwutOS-ULS successfully installed."
