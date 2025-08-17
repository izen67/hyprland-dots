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
    qbittorrent
    gwenview
    fastfetch
)

AUR_PACKAGES=(
    vesktop
    spotify
    brave-bin
    anydesk
)

# Update system
sudo pacman -Syu --noconfirm

# Install packages
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# Install aur packages
yay -S --noconfirm "${AUR_PACKAGES[@]}"

#Add flathub remove
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Fix speakers crackling (optional)
read -rp "Do you want to disable audio power saving to fix speaker crackle? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    AUDIO_LINE='options snd_hda_intel power_save=0'
    if ! grep -Fxq "$AUDIO_LINE" /etc/modprobe.d/audio_disable_powersave.conf 2>/dev/null; then
        echo "$AUDIO_LINE" | sudo tee -a /etc/modprobe.d/audio_disable_powersave.conf
        echo "Audio power saving disabled."
    else
        echo "Audio crackle fix already applied."
    fi
fi

# Mount SSD (optional)
read -rp "Do you want to add the SSD mount to /etc/fstab? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo mkdir -p /mnt/extra
    UUID_LINE='UUID=60fc72ce-8793-4f92-8641-0db9411d931e /mnt/extra ext4 defaults 0 0'
    if ! grep -Fxq "$UUID_LINE" /etc/fstab; then
        echo "$UUID_LINE" | sudo tee -a /etc/fstab
        echo "Mount entry added."
    else
        echo "Mount entry already exists."
    fi
fi

flatpak install --assumeyes flathub com.github.tchx84.Flatseal
flatpak install --assumeyes flathub com.github.iwalton3.jellyfin-media-player
flatpak install --assumeyes flathub net.lutris.Lutris
flatpak override --user --filesystem=/mnt/extra/lutris net.lutris.Lutris


#TIMESHIFT + ADD BACKUPS TO GRUB:
# Timeshift + grub-btrfs integration
sudo pacman -S --needed --noconfirm grub-btrfs inotify-tools timeshift

# Enable the grub-btrfsd service directory if not already
sudo systemctl enable grub-btrfsd

# Patch ExecStart line in the systemd service file
SERVICE_FILE="/etc/systemd/system/grub-btrfsd.service"

if [[ -f "$SERVICE_FILE" ]]; then
    # Already has a local override
    sudo sed -i 's|ExecStart=.*|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' "$SERVICE_FILE"
else
    # Create a full override copy
    sudo systemctl edit --full grub-btrfsd --force
    sudo sed -i 's|ExecStart=.*|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' \
        /etc/systemd/system/grub-btrfsd.service
fi

# Reload systemd and restart the service
sudo systemctl daemon-reexec
sudo systemctl restart grub-btrfsd

