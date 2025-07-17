#!/bin/bash

successMessage() {
    echo -e "\033[0;32mSUCCESS\033[0m\t:: $*"
}

errorMessage() {
    echo -e "\033[0;31mERROR\033[0m\t:: $*"
}

infoMessage() {
    echo -e "\033[1;30mINFO\033[0m\t:: $*"
}

warningMessage() {
    echo -e "\033[0;33mWARNING\033[0m\t:: $*"
}


HELP_TEXT=" Usage: ./Startup.sh [OPTIONS]\n\
Options:\n\
    --help              Show this help message and exit\n\
    --verbose           Enable verbose output\n\
    --no-confirm        Skip confirmation prompts\n\
    --network-name      Specify the Wi-Fi network name\n\
    --network-password  Specify the Wi-Fi network password\n\
Example:\n\
    ./Startup.sh --network-name <NETWORK_NAME> --network-password <NETWORK_PASSWORD>\n\
"

PACMAN_PACKAGES=(
    "base-devel"
    "docker"
    "docker-compose"
    "dotnet-sdk"
    "ghostty"
    "git"
    "pavucontrol"
    "telegram-desktop"
    "ttf-font-awesome"
    "ttf-jetbrains-mono"
    "ttf-jetbrains-mono-nerd"
    "waybar"
    "waybar-hyprland"
    # "zsh"
    # "zsh-autosuggestions"
    # "zsh-completions"
    # "zsh-syntax-highlighting"
)

YAY_PACKAGES=(
    "blesh-git"
    "brave-bin"
    "nerd-fonts-jetbrains-mono"
    # "oh-my-zsh-git"
    "openvpn3"
    "outlook-for-linux-bin"
    "spotify-launcher"
    "stremio"
    "teams-for-linux"
    "visual-studio-code-bin"
)

# Global variables
NO_CONFIRM=0
VERBOSE=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --help) errorMessage $HELP_TEXT; exit 0 ;;
        --verbose) VERBOSE=1 ;;
        --no-confirm) NO_CONFIRM=1 ;;
        --network-name) NETWORK_NAME="$2"; shift ;;
        --network-password) NETWORK_PASSWORD="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check if the script is running with sudo/root privileges
if [[ "$EUID" -ne 0 ]]; then
    errorMessage "This script must be run as root!"
    exit 1
fi

# Check if both network name and password are provided
if [[ ( -n "$NETWORK_NAME" && -z "$NETWORK_PASSWORD" ) || ( -z "$NETWORK_NAME" && -n "$NETWORK_PASSWORD" ) ]]; then
    errorMessage "Both parameters are required.\n\
    Example: \n\
    ./Startup.sh --network-name <NETWORK_NAME> --network-password <NETWORK_PASSWORD>"
    exit 1
fi

# Connect to the Wi-Fi network if both parameters are provided
if [[ -n "$NETWORK_NAME" || -n "$NETWORK_PASSWORD" ]]; then
    infoMessage "Connecting to Wi-Fi network: $NETWORK_NAME"
    nmcli devices wifi connect "$NETWORK_NAME" password "$NETWORK_PASSWORD"
fi

# Check for internet connection
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    successMessage "Internet connection is available."
else
    errorMessage "No internet connection. Aborting script execution."
    exit 1
fi

# Check for updates
infoMessage "Checking for system updates..."
if [[ "$NO_CONFIRM" -eq 1 ]]; then
    if [[ "$VERBOSE" -eq 1 ]]; then
        sudo pacman -Syu --noconfirm
    else
        sudo pacman -Syu --noconfirm &>/dev/null
    fi
else
    if [[ "$VERBOSE" -eq 1 ]]; then
        sudo pacman -Syu
    else
        sudo pacman -Syu &>/dev/null
    fi
fi
successMessage "System updated!"

# Refresh the package database
infoMessage "Refreshing pacman package database..."
sudo pacman -Sy &>/dev/null
successMessage "Pacman package database refreshed."
infoMessage "Refreshing Yay package database..."
sudo yay -Sy &>/dev/null
successMessage "Yay package database refreshed."

infoMessage "Installing packages..."

# Install packages using pacman
for package in "${PACMAN_PACKAGES[@]}"; do
    if pacman -Qi "$package" &>/dev/null; then
        successMessage "$package is already installed."
    else
        infoMessage "Installing $package..."
        if [[ "$NO_CONFIRM" -eq 1 ]]; then
            if [[ "$VERBOSE" -eq 1 ]]; then
                sudo pacman -S --noconfirm "$package"
            else
                sudo pacman -S --noconfirm "$package" &>/dev/null
            fi
        else
            if [[ "$VERBOSE" -eq 1 ]]; then
                sudo pacman -S "$package"
            else
                sudo pacman -S "$package" &>/dev/null
            fi
        fi
        successMessage "$package installed successfully."
    fi
done

# Install yay if not already installed
if ! command -v yay &>/dev/null; then
    infoMessage "Installing yay (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git &>/dev/null
    cd yay
    if [[ "$VERBOSE" -eq 1 ]]; then
        sudo -u "$SUDO_USER" makepkg -si --noconfirm
    else
        sudo -u "$SUDO_USER" makepkg -si --noconfirm &>/dev/null
    fi
    cd ..
    rm -rf yay
    successMessage "yay installed successfully."
else
    successMessage "yay is already installed."
fi

# Install packages using yay
for package in "${YAY_PACKAGES[@]}"; do
    if sudo -u "$SUDO_USER" yay -Qi "$package" &>/dev/null; then
        successMessage "$package is already installed."
    else
        infoMessage "Installing $package using yay..."
        if [[ "$NO_CONFIRM" -eq 1 ]]; then
            if [[ "$VERBOSE" -eq 1 ]]; then
                sudo -u "$SUDO_USER" yay -S "$package" --noconfirm
            else
                sudo -u "$SUDO_USER" yay -S "$package" --noconfirm &>/dev/null
            fi
        else
            if [[ "$VERBOSE" -eq 1 ]]; then
                sudo -u "$SUDO_USER" yay -S "$package"
            else
                sudo -u "$SUDO_USER" yay -S "$package" &>/dev/null
            fi
        fi
        successMessage "$package installed successfully."
    fi
done


# Enable and start Docker service
infoMessage "Enabling and starting Docker service..."
if systemctl enable docker.service && systemctl start docker.service; then
    successMessage "Docker service enabled and started successfully."
else
    errorMessage "Failed to enable or start Docker service. Manual intervention may be required."
fi

# Pacman clean up
infoMessage "Pacman cleaning up..."
if [[ "$VERBOSE" -eq 1 ]]; then
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm
else
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm &>/dev/null
fi
successMessage "Cleanup completed."

# Yay clean up
infoMessage "Yay cleaning up..."
if [[ "$VERBOSE" -eq 1 ]]; then
    sudo -u "$SUDO_USER" yay -Rns $(yay -Qdtq) --noconfirm
else
    sudo -u "$SUDO_USER" yay -Rns $(yay -Qdtq) --noconfirm &>/dev/null
fi
successMessage "Yay cleanup completed."

# Final message
successMessage "All packages installed and configured successfully!"
infoMessage "You may need to restart your system for all changes to take effect."

# Reload environment variables
if [[ "$VERBOSE" -eq 1 ]]; then
    source /etc/profile
else
    source /etc/profile &>/dev/null
fi

# Refresh the hash table for pacman
hash -r

# # Change the default shell to zsh
# infoMessage "Changing default shell to zsh..."

# # Check if zsh is already in /etc/shells
# if ! grep -q "/bin/zsh" /etc/shells; then
#     echo "/bin/zsh" | sudo tee -a /etc/shells &>/dev/null
#     successMessage "Successfully added /bin/zsh to /etc/shells."
# else
#     successMessage "/bin/zsh already exists in /etc/shells. Skipping."
# fi

# if [[ "$VERBOSE" -eq 1 ]]; then
#     chsh -s /bin/zsh "$SUDO_USER"
# else
#     chsh -s /bin/zsh "$SUDO_USER" &>/dev/null
# fi
# successMessage "Default shell changed to zsh for user $SUDO_USER."
