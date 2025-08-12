#!/usr/bin/env bash
set -e  # Exit on error
# Packages from official repos
PACKAGES=(
    vesktop
    kate
    ufw
    spotify
    steam
    nvtop
    mpv
    lutris
    wine
    gamemode
    gamescope
    brave-bin
    flatpak
    chromium
)

# Update system
sudo pacman -Syu --noconfirm

# Install packages
sudo yay -S --noconfirm "${PACKAGES[@]}"

#Add flathub remove
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

#Fix speakers crackling
echo "options snd_hda_intel power_save=0" | sudo tee -a /etc/modprobe.d/audio_disable_powersave.conf

#Mount ssd
UUID_LINE='UUID=60fc72ce-8793-4f92-8641-0db9411d931e /mnt/extra ext4 defaults 0 0'

# Check if line already exists in /etc/fstab
if ! grep -Fxq "$UUID_LINE" /etc/fstab; then
    echo "$UUID_LINE" | sudo tee -a /etc/fstab
fi

flatpak install flathub com.github.iwalton3.jellyfin-media-player
