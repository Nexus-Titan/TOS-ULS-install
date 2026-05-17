#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Bitte als Root (sudo) ausfuehren."
    exit 1
fi

echo "Moechten Sie GNOME und alle Abhaengigkeiten auf Arch Linux ARM installieren? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Abgebrochen."
    exit 1
fi

pacman -Syu --noconfirm

pacman -S --noconfirm --needed \
    xorg-server \
    gnome \
    gnome-extra \
    gdm \
    networkmanager \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    mesa \
    xf86-video-fbdev

systemctl enable gdm.service
systemctl enable NetworkManager.service

echo "Installation abgeschlossen. Das System startet in 5 Sekunden neu..."
sleep 5
reboot
