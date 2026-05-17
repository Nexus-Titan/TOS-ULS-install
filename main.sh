#!/bin/bash

error_exit() {
    whiptail --title "Installation Error" --msgbox "$1" 10 60
    exit 1
}

text_error_exit() {
    echo -e "\e[31m[ERROR]\e[0m $1"
    exit 1
}

check_and_install_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        echo -e "\e[34m[INFO]\e[0m The installer needs 'whiptail' for the user interface."
        echo -e "\e[34m[INFO]\e[0m It is not installed. Attempting to install it now..."
        
        if ! ping -c 1 8.8.8.8 &> /dev/null; then
            text_error_exit "No internet connection detected. Please connect to the internet to install dependencies."
        fi

        if [[ -f /etc/debian_version ]]; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq && apt-get install -y whiptail -qq || text_error_exit "Failed to install 'whiptail'. Run: sudo apt install whiptail"
        elif [[ -f /etc/fedora-release ]]; then
            dnf install -y newt -q || text_error_exit "Failed to install 'newt'. Run: sudo dnf install newt"
        elif [[ -f /etc/arch-release ]]; then
            pacman -Sy --noconfirm libnewt --quiet || text_error_exit "Failed to install 'libnewt'. Run: sudo pacman -Sy libnewt"
        else
            text_error_exit "Could not automatically install 'whiptail'. Please install it manually."
        fi
        
        echo -e "\e[32m[SUCCESS]\e[0m Dependency installed. Starting installer UI..."
        sleep 2
    fi
}

if [[ $EUID -ne 0 ]]; then
   echo -e "\e[31m[ERROR]\e[0m This installer requires root privileges (sudo)."
   echo "Please run this script with: curl ... | sudo bash"
   exit 1
fi

check_and_install_whiptail

whiptail --title "TiwutOS-ULS Installer" --msgbox "Welcome to the TiwutOS-ULS Installer!\n\nThis script will detect your system, download, and execute the appropriate TiwutOS-ULS setup script. TiwutOS-ULS is an immutable, hardened, container-first OS appliance." 15 70

ROOT_URL="https://nexus-titan.github.io/TOS-ULS-install/"
SCRIPT_URL="" 

whiptail --title "System Detection" --infobox "Detecting your operating system and architecture. Please wait..." 8 60
sleep 2

ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
case "$ARCH" in
    x86_64)
        ARCH_NAME="x86_64"
        ARCH="x86"
        ;;
    aarch64)
        ARCH_NAME="ARM64"
        ARCH="arm64"
        ;;
    *)
        error_exit "Unsupported architecture detected: $ARCH.\nThis installer supports x86_64 and AArch64 (ARM64) architectures only."
        ;;
esac

DISTRO_NAME=""
if grep -qs "Ubuntu" /etc/os-release; then
    DISTRO="ubuntu"
    DISTRO_NAME="Ubuntu"
elif grep -qs "Debian" /etc/os-release; then
    DISTRO="debian"
    DISTRO_NAME="Debian"
elif grep -qs "Fedora" /etc/os-release; then
    DISTRO="fedora"
    DISTRO_NAME="Fedora"
elif grep -qs "Arch Linux" /etc/os-release; then
    DISTRO="arch"
    DISTRO_NAME="Arch Linux"
else
    error_exit "Unsupported Linux distribution detected.\nThis installer supports Ubuntu, Debian, Fedora, and Arch Linux only."
fi

if (whiptail --title "System Detected" --yesno "We detected:\n  Architecture: ${ARCH_NAME}\n  Distribution: ${DISTRO_NAME}\n\nIs this correct?" 12 60); then
    whiptail --title "Confirmation" --infobox "System confirmed. Preparing for installation..." 8 60
    sleep 2
else
    error_exit "System detection not confirmed by user. Aborting installation."
fi

SCRIPT_URL="${ROOT_URL}${ARCH}/${DISTRO}/main.sh"

whiptail --title "Download Information" --msgbox "The installer will now attempt to download the specific TiwutOS-ULS setup script for your system from:\n\n${SCRIPT_URL}\n\nPlease ensure you trust the source of this script before proceeding." 15 70

if (whiptail --title "Proceed with Installation?" --yesno "Are you ready to download and execute the TiwutOS-ULS setup script?\n\nThis will install TiwutOS-ULS on your system." 12 60); then
    
    whiptail --title "Installation in Progress" --infobox "Downloading and executing the TiwutOS-ULS setup script. This may take a few moments..." 8 60
    
    curl -sSL "$SCRIPT_URL" > /tmp/tiwutos-uls-installer.sh
    
    if [[ $? -ne 0 ]]; then
        error_exit "Download failed! Please check the URL:\n$SCRIPT_URL"
    fi

    clear
    echo "Running target install script..."
    echo "--------------------------------------------------------"
    
    bash /tmp/tiwutos-uls-installer.sh "$@"
    EXIT_CODE=$?

    rm -f /tmp/tiwutos-uls-installer.sh

    if [[ $EXIT_CODE -eq 0 ]]; then
        whiptail --title "Installation Complete" --msgbox "TiwutOS-ULS has been successfully installed!\n\nPlease follow any post-installation instructions provided." 12 60
    else
        error_exit "The downloaded TiwutOS-ULS script encountered an error (Exit Code: $EXIT_CODE)."
    fi
else
    whiptail --title "Installation Canceled" --msgbox "TiwutOS-ULS installation canceled by user." 10 60
    exit 0
fi

exit 0
