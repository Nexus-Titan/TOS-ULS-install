#!/bin/bash

error_exit() {
    whiptail --title "Installation Error" --msgbox "$1" 10 60
    exit 1
}

show_progress() {
    local message="$1"
    local pid="$2"
    local delay=0.1
    local spin_chars="/-\|"
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r%s %c" "$message" "${spin_chars:$((i++ % ${#spin_chars})):1}"
        sleep "$delay"
    done
    printf "\r%s   \n" "$message"
}

check_and_install_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        whiptail --title "Dependency Check" --msgbox "Whiptail is required for this installer but not found. Attempting to install it now. This may require an internet connection." 10 60

        if [[ -f /etc/debian_version ]]; then
            if ! apt update && apt install -y whiptail; then
                error_exit "Failed to install 'whiptail'. Please install it manually with 'sudo apt install whiptail' and try again."
            fi
        elif [[ -f /etc/fedora-release ]]; then
            if ! dnf install -y newt; then
                error_exit "Failed to install 'newt' (which provides whiptail). Please install it manually with 'sudo dnf install newt' and try again."
            fi
        elif [[ -f /etc/arch-release ]]; then
            if ! pacman -Sy --noconfirm newt; then
                error_exit "Failed to install 'newt' (which provides whiptail). Please install it manually with 'sudo pacman -Sy newt' and try again."
            fi
        else
            error_exit "Could not automatically install 'whiptail'. Please install the 'whiptail' package manually for your distribution and rerun the script."
        fi
    fi
}


check_and_install_whiptail

if [[ $EUID -ne 0 ]]; then
   whiptail --title "Permission Error" --msgbox "This installer requires root privileges (sudo). Please run this script with 'sudo ./main.sh'." 10 60
   exit 1
fi

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
        error_exit "Unsupported architecture detected: $ARCH_NAME.\nThis installer supports x86_64 and AArch64 (ARM64) architectures only."
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
    whiptail --title "Installation in Progress" --infobox "Downloading and executing the TiwutOS-ULS setup script. This may take a few moments..." 8 60 &
    INSTALL_PID=$!
    
    sleep 1

    (
        curl -sSL "$SCRIPT_URL" > /tmp/tiwutos-uls-installer.sh
        if [[ $? -ne 0 ]]; then
            echo "Download failed"
            exit 1
        fi
        bash /tmp/tiwutos-uls-installer.sh "$@"
        if [[ $? -ne 0 ]]; then
            echo "Installation script failed"
            exit 1
        fi
        rm -f /tmp/tiwutos-uls-installer.sh
    ) &
    SCRIPT_EXEC_PID=$!

    wait $SCRIPT_EXEC_PID

    if [[ $? -eq 0 ]]; then
        whiptail --title "Installation Complete" --msgbox "TiwutOS-ULS has been successfully installed!\n\nPlease follow any post-installation instructions provided by the TiwutOS-ULS documentation." 12 60
    else
        error_exit "TiwutOS-ULS installation encountered an error during download or execution.\nPlease check your internet connection and the details above."
    fi
else
    whiptail --title "Installation Canceled" --msgbox "TiwutOS-ULS installation canceled by user." 10 60
    exit 0
fi

exit 0
