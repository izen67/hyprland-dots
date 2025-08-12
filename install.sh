#!/usr/bin/env bash
set -e  # Exit on error
# Packages from official repos
PACKAGES=(
    kate
    ufw
    steam
    nvtop
    mpv
    wine
    mangohud
    goverlay
    gamemode
    gamescope
    flatpak
    chromium
    plasma-systemmonitor
)

AUR_PACKAGES=(
    vesktop
    spotify
    brave-bin
)

# Update system
sudo pacman -Syu --noconfirm

# Install packages
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# Install aur packages
sudo yay -S --noconfirm "${AUR_PACKAGES[@]}"

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

flatpak install --assumeyes flathub com.github.tchx84.Flatseal
flatpak install --assumeyes flathub com.github.iwalton3.jellyfin-media-player
flatpak install --assumeyes flathub net.lutris.Lutris
flatpak override --user --filesystem=/mnt/extra/lutris net.lutris.Lutris
