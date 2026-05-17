#!/bin/bash

UI_MODE="text"

ui_msgbox() {
    local title="$1"
    local text="$2"
    if [[ "$UI_MODE" == "whiptail" ]]; then
        whiptail --title "$title" --msgbox "$text" 15 70
    else
        echo -e "\n\e[1;36m=== $title ===\e[0m"
        echo -e "$text"
        echo -e "\e[1;36m=================\e[0m"
        read -p "Press Enter to continue..."
    fi
}

ui_infobox() {
    local title="$1"
    local text="$2"
    if [[ "$UI_MODE" == "whiptail" ]]; then
        whiptail --title "$title" --infobox "$text" 8 60
    else
        echo -e "\n\e[34m[INFO]\e[0m $title: $text"
    fi
}

ui_yesno() {
    local title="$1"
    local text="$2"
    if [[ "$UI_MODE" == "whiptail" ]]; then
        if whiptail --title "$title" --yesno "$text" 15 70; then
            return 0
        else
            return 1
        fi
    else
        echo -e "\n\e[1;33m=== $title ===\e[0m"
        echo -e "$text"
        echo -e "\e[1;33m=================\e[0m"
        while true; do
            read -p "Do you want to proceed? (Y/n): " yn
            case $yn in
                [Yy]* | "" ) return 0;;
                [Nn]* ) return 1;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

ui_error_exit() {
    local text="$1"
    if [[ "$UI_MODE" == "whiptail" ]]; then
        whiptail --title "Installation Error" --msgbox "$text" 15 70
    else
        echo -e "\n\e[1;31m[ERROR]\e[0m $text"
    fi
    exit 1
}

check_and_install_ui() {
    if command -v whiptail &> /dev/null && whiptail --version &> /dev/null; then
        UI_MODE="whiptail"
        return 0
    fi

    echo -e "\e[34m[INFO]\e[0m Attempting to install 'whiptail' for a better installation experience..."
    
    if [[ -f /etc/debian_version ]]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq && apt-get install -y whiptail -qq &> /dev/null
    elif [[ -f /etc/fedora-release ]]; then
        dnf install -y newt -q &> /dev/null
    elif [[ -f /etc/arch-release ]]; then
        pacman -S --noconfirm libnewt --quiet &> /dev/null
    fi

    if command -v whiptail &> /dev/null && whiptail --version &> /dev/null; then
        UI_MODE="whiptail"
    else
        echo -e "\e[33m[WARN]\e[0m Could not setup graphical UI. Falling back to text mode."
        sleep 2
        UI_MODE="text"
    fi
}

if [[ $EUID -ne 0 ]]; then
   echo -e "\e[31m[ERROR]\e[0m This installer requires root privileges (sudo)."
   echo "Please run this script with: curl ... | sudo bash"
   exit 1
fi

check_and_install_ui

ui_msgbox "TiwutOS-ULS Installer" "Welcome to the TiwutOS-ULS Installer!\n\nThis script will detect your system, download, and execute the appropriate TiwutOS-ULS setup script. TiwutOS-ULS is an immutable, hardened, container-first OS appliance."

ROOT_URL="https://nexus-titan.github.io/TOS-ULS-install/"
SCRIPT_URL="" 

ui_infobox "System Detection" "Detecting your operating system and architecture. Please wait..."
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
        ui_error_exit "Unsupported architecture detected: $ARCH.\nThis installer supports x86_64 and AArch64 (ARM64) architectures only."
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
    ui_error_exit "Unsupported Linux distribution detected.\nThis installer supports Ubuntu, Debian, Fedora, and Arch Linux only."
fi

if ui_yesno "System Detected" "We detected:\n  Architecture: ${ARCH_NAME}\n  Distribution: ${DISTRO_NAME}\n\nIs this correct?"; then
    ui_infobox "Confirmation" "System confirmed. Preparing for installation..."
    sleep 2
else
    ui_error_exit "System detection not confirmed by user. Aborting installation."
fi

SCRIPT_URL="${ROOT_URL}${ARCH}/${DISTRO}/main.sh"

ui_msgbox "Download Information" "The installer will now attempt to download the specific TiwutOS-ULS setup script for your system from:\n\n${SCRIPT_URL}\n\nPlease ensure you trust the source of this script before proceeding."

if ui_yesno "Proceed with Installation?" "Are you ready to download and execute the TiwutOS-ULS setup script?\n\nThis will begin the main installation phase."; then
    
    ui_infobox "Installation in Progress" "Downloading the target setup script. This may take a few moments..."
    
    curl -sSL "$SCRIPT_URL" > /tmp/tiwutos-uls-installer.sh
    
    if [[ $? -ne 0 ]]; then
        ui_error_exit "Download failed! Please check your internet connection and the URL:\n$SCRIPT_URL"
    fi

    clear
    echo -e "\e[1;32mRunning target install script...\e[0m"
    echo "--------------------------------------------------------"
    
    bash /tmp/tiwutos-uls-installer.sh "$@"
    EXIT_CODE=$?

    rm -f /tmp/tiwutos-uls-installer.sh

    echo "--------------------------------------------------------"

    if [[ $EXIT_CODE -eq 0 ]]; then
        ui_msgbox "Installation Complete" "TiwutOS-ULS target script has finished executing.\n\nPlease follow any post-installation instructions provided above."
    else
        ui_error_exit "The downloaded TiwutOS-ULS script encountered an error (Exit Code: $EXIT_CODE)."
    fi
else
    ui_msgbox "Installation Canceled" "TiwutOS-ULS installation canceled by user."
    exit 0
fi

exit 0
