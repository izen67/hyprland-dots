#!/usr/bin/env bash
set -e  # Exit on error
# Packages from official repos
PACKAGES=(
    kate
    ark
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
read -rp "Do you want to disable audio power saving to fix speaker crackle? (y/n): " ans_audio
if [[ "$ans_audio" =~ ^[Yy]$ ]]; then
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
# Timeshift + grub-btrfs (optional)
read -rp "Enable GRUB snapshots via grub-btrfs + Timeshift? (y/n): " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    # Install required packages
    sudo pacman -S --needed --noconfirm grub-btrfs inotify-tools timeshift

    # Create a systemd drop-in to override ExecStart correctly
    sudo mkdir -p /etc/systemd/system/grub-btrfsd.service.d
    sudo tee /etc/systemd/system/grub-btrfsd.service.d/override.conf >/dev/null <<'EOF'
[Service]
# Clear upstream ExecStart, then set Timeshift-aware one
ExecStart=
ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto
EOF

    # Reload units and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable --now grub-btrfsd.service

    # Optional: regenerate GRUB now so the snapshots submenu is present
    read -rp "Regenerate GRUB configuration now? (y/n): " regen
    if [[ "$regen" =~ ^[Yy]$ ]]; then
        if [[ -d /boot/grub ]]; then
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        elif [[ -d /boot/grub2 ]]; then
            sudo grub-mkconfig -o /boot/grub2/grub.cfg
        else
            echo "Could not find GRUB directory; skipping grub-mkconfig."
fi
fi

    echo "grub-btrfsd configured for Timeshift snapshots."
else
    echo "Skipping grub-btrfs + Timeshift setup."
fi


# Copy custom Hyprland configs from repo
mkdir -p "$HOME/.config/hypr/custom"

TMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/izen67/hyprland-dots.git "$TMP_DIR"

cp -r "$TMP_DIR/custom/"* "$HOME/.config/hypr/custom/"

rm -rf "$TMP_DIR"

echo "Custom Hypr config installed to $HOME/.config/hypr/custom"
