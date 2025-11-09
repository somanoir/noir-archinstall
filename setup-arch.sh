#!/usr/bin/env bash

# Install required packages
install_packages() {
  paru -S --needed --noconfirm "$@"
  # for pkg; do
  #   paru -S --needed --noconfirm "${pkg}"
  # done
}

packages_common_utils=(
  "git"
  "git-lfs"
  "lazygit"
  "pacman-contrib"
  "curl"
  "wget"
  "net-tools"
  "unzip"
  "rsync"
  "glibc"
  "cmake"
  "meson"
  "cpio"
  "go"
  "luarocks"
  "nodejs"
  "npm"
  "uv"
  "podman"
  "pkgconf-pkg-config"
  "stow"
  "nwg-look"
  "zsh"
  "starship"
  "fzf"
  "zoxide"
  "lsd"
  "bat"
  "bat-extras"
  "cava"
  "brightnessctl"
  "playerctl"
  "pavucontrol"
  "alsa-utils"
  "pipewire"
  "lib32-pipewire"
  "pipewire-pulse"
  "pipewire-alsa"
  "pipewire-audio"
  "wireplumber"
  "btop"
  "python-pip"
  "python-pipx"
  "python3-gobject"
  "gtk4"
  "fastfetch"
  "bluez"
  "bluez-utils"
  "rofi-bluetooth-git"
  "networkmanager-dmenu"
  "openvpn"
  "networkmanager-openvpn"
  "rofi-power-menu"
  "yt-dlp"
  "ly"
  "ntfs-3g"
  "acpi"
  "libva-nvidia-driver"
  "zstd"
  "mlocate"
  "bind"
  "man-db"
  "man-pages"
  "tealdeer"
  "ark"
  "downgrade"
  "less"
  "ripgrep"
  "reflector"
  "pkgfile"
  "gvfs"
  "gvfs-mtp"
  "gvfs-smb"
  "ncdu"
  "dkms"
  "archlinux-xdg-menu"
  "bibata-cursor-theme"
  "tela-circle-icon-theme-dracula"
  "qt5ct-kde"
  "qt6ct-kde"
  "xdg-desktop-portal-gtk"
  "xdg-desktop-portal-hyprland"
  "ollama"
)

packages_common_x11=(
  "xorg"
  "xsel"
  "dex"
  "xdotool"
  "xclip"
  "cliphist"
  "xinput"
  "rofi"
  "polybar"
  "dunst"
  "feh"
  "maim"
  "picom"
)

packages_common_wayland=(
  "qt5-wayland"
  "qt6-wayland"
  "egl-wayland"
  "wlr-randr"
  "wl-clipboard"
  "wl-clip-persist"
  "cliphist"
  "rofi-wayland"
  "rofi"
  "waybar"
  "mako"
  "swww"
)

packages_hyprland=(
  "hyprland"
  "hyprutils"
  "hyprpicker"
  "hyprpolkitagent"
  "hyprshot"
  "xdg-desktop-portal-hyprland"
  "hyprlock"
  "pyprland"
  "hypridle"
  "uwsm"
)

packages_niri=(
  "niri"
  "xwayland-satellite"
  "xdg-desktop-portal-gnome"
  "hyprlock"
)

packages_awesome=(
  "awesome"
  "lain"
  "polkit-gnome"
)

packages_i3=(
  "i3-wm"
  "i3lock"
  "autotiling"
)

packages_apps=(
  "ghostty"
  "alacritty"
  "firefox"
  "librewolf-bin"
  "neovim"
  "vim"
  "nano"
  "code"
  "mpd"
  "mpc"
  "mpv"
  "dolphin"
  "nautilus"
  "yazi"
  "imagemagick"
  "qbittorrent"
  "keepassxc"
  "foliate"
  "mcomix"
  "okular"
  "libreoffice-fresh"
  "discord"
  "filezilla"
  "filelight"
  "gnome-disk-utility"
  "nomacs"
  "obsidian"
  "rmpc"
  "shortwave"
  "qalculate-gtk"
  "clock-rs-git"
)

packages_fonts=(
  "ttf-hack-nerd"
  "noto-fonts"
  "noto-fonts-cjk"
  "noto-fonts-emoji"
  "noto-fonts-extra"
  "otf-font-awesome"
)

packages_gaming=(
  "steam"
  "lutris"
  "umu-launcher"
)

packages_firmware=(
  "aic94xx-firmware"
  "ast-firmware"
  "linux-firmware-qlogic"
  "wd719x-firmware"
  "upd72020x-fw"
)

packages_nvidia=(
  "nvidia-dkms"
  "lib32-nvidia-utils"
  "nvidia-utils"
  "nvidia-settings"
)

set_variables() {
  sudo pacman -S --needed --noconfirm gum

  choice_backup_hook=$(gum choose "Yes" "No" --header "Would you like to setup a pacman hook that creates a copy of the /boot directory?")
  choice_microcode=$(gum choose "Intel" "AMD" "None" --header "Would you like to install processor microcode?")
  choice_nvidia=$(gum choose "Yes" "No" --header "Would you like to install Nvidia drivers?")
  choice_wm=$(gum choose "hyprland" "niri" "awesome" "i3" --no-limit --header "Choose window managers to be installed.")
  choice_apps=$(gum choose "Yes" "No" --header "Would you like to install apps (browsers, file managers, terminal emulators, etc.)?")
  choice_gaming_tools=$(gum choose "Yes" "No" --header "Would you like to install gaming tools?")
  choice_dotfiles=$(gum choose "Yes" "No" --header "Would you like to install Noir Dotfiles?")
  choice_wallpapers=$(gum choose "Yes" "No" --header "Would you like to install Noir Wallpapers?")
}

setup_backup_hook() {
  case "$choice_backup_hook" in
  Yes)
    echo "→ Setting up pacman boot backup hook..."
    echo "→ Configuring /boot backup when pacman transactions are made..."
    sudo -i -u root /bin/bash <<EOF
mkdir /etc/pacman.d/hooks
echo "[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup" > /etc/pacman.d/hooks/50-bootbackup.hook
EOF
    ;;
  No) echo "→ Skipping setup of pacman boot backup hook..." ;;
  esac
}

install_window_managers() {
  IFS = ', '
  for choice in "${choice_wm[@]}"; do
    case "$choice" in
    hyprland*)
      install_packages "${packages_hyprland[@]}"
      install_packages "${packages_common_wayland[@]}"
      ;;
    niri*)
      install_packages "${packages_niri[@]}"
      install_packages "${packages_common_wayland[@]}"
      ;;
    awesome*)
      install_packages "${packages_awesome[@]}"
      install_packages "${packages_common_x11[@]}"
      ;;
    i3*)
      install_packages "${packages_i3[@]}"
      install_packages "${packages_common_x11[@]}"
      ;;
    esac
  done
}

install_misc() {
  # Ollama
  # curl -fsSL https://ollama.com/install.sh | sh

  # Rofi Power Menu
  pipx install git+https://github.com/cjbassi/rofi-power
}

install_microcode() {
  case "$choice_microcode" in
  Intel)
    echo "→ Installing Intel microcode..."
    paru -S --needed --noconfirm intel-ucode
    ;;
  AMD)
    echo "→ Installing AMD microcode..."
    paru -S --needed --noconfirm amd-ucode
    ;;
  None) echo "→ Skipping installation of microcode..." ;;
  esac
}

install_nvidia_drivers() {
  case "$choice_nvidia" in
  Yes)
    echo "→ Installing Nvidia drivers..."
    install_packages "${packages_nvidia[@]}"
    ;;
  No) echo "→ Skipping installation of Nvidia drivers..." ;;
  esac
}

install_apps() {
  case "$choice_apps" in
  Yes)
    echo "→ Installing applications..."
    install_packages "${packages_apps[@]}"
    ;;
  No) echo "→ Skipping installation of apps..." ;;
  esac
}

install_gaming_tools() {
  case "$choice_gaming_tools" in
  Yes)
    echo "→ Installing gaming tools..."
    install_packages "${packages_gaming[@]}"
    ;;
  No) echo "→ Skipping installation of gaming tools..." ;;
  esac
}

setup_mpd() {
  mkdir ~/.local/share/mpd
  touch ~/.local/share/mpd/database
  mkdir ~/.local/share/mpd/playlists
  touch ~/.local/share/mpd/state
  touch ~/.local/share/mpd/sticker.sql

  systemctl --user enable --now mpd.service
  mpc update
}

install_flatpaks() {
  flatpak install flathub com.github.tchx84.Flatseal --assumeyes
  flatpak install flathub com.github.vikdevelop.photopea_app --assumeyes
}

install_dotfiles() {
  case "$choice_dotfiles" in
  Yes)
    echo "→ Installing Noir Dotfiles..."

    cd ~ || exit
    case "$choice_wallpapers" in
    Yes)
      git clone --depth 1 --recurse-submodules https://github.com/somanoir/.noir-dotfiles.git
      ;;
    No)
      git clone --depth 1 https://github.com/somanoir/.noir-dotfiles.git
      ;;
    esac
    cd .noir-dotfiles || exit
    stow .

    bat cache --build
    sudo flatpak override --filesystem=xdg-data/themes
    flatpak install org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark

    # Link user configs with root configs
    sudo mkdir /root/.config
    sudo ln -sf /home/$USER/.noir-dotfiles/.zshrc /root/.zshrc
    sudo ln -s /home/$USER/.noir-dotfiles/.config/zsh /root/.config/zsh
    sudo ln -sf /home/$USER/.noir-dotfiles/.config/starship.toml /root/.config/starship.toml
    sudo ln -s /home/$USER/.noir-dotfiles/.config/nvim /root/.config/nvim
    sudo mkdir -p /root/.cache/wal
    sudo ln -s /home/$USER/.noir-dotfiles/.cache/wal/colors-wal.vim /root/.cache/wal/colors-wal.vim

    return 0
    ;;
  No)
    echo "→ Skipping installation of Noir Dotfiles..."
    return 0
    ;;
  esac
}

clear

cat <<"EOF"
                    _        _____      _
     /\            | |      / ____|    | |
    /  \   _ __ ___| |__   | (___   ___| |_ _   _ _ __
   / /\ \ | '__/ __| '_ \   \___ \ / _ \ __| | | | '_ \
  / ____ \| | | (__| | | |  ____) |  __/ |_| |_| | |_) |
 /_/    \_\_|  \___|_| |_| |_____/ \___|\__|\__,_| .__/
                                                 | |
                                                 |_|
EOF

while true; do
  read -rp "Would you like to proceed with setup? (y/n): " answer
  case "$answer" in
  [Yy]*) break ;; # Proceed with the script
  *)
    echo "Exiting."
    exit 1
    ;; # Exit the script
  esac
done

# Create user folders
mkdir /home/$USER/{Code,Games,My}
mkdir -p /home/$USER/.local/{bin,share/backgrounds,share/icons}

# Set global variables
set_variables

# Boot backup hook
setup_backup_hook

# Fix laptop lid acting like airplane mode key
echo "→ Fixing laptop lid acting like airplane mode key..."
sudo -i -u root /bin/bash <<EOF
mkdir /etc/rc.d
echo "#!/usr/bin/env bash
# Fix laptop lid acting like airplane mode key
setkeycodes d7 240
setkeycodes e058 142" > /etc/rc.d/rc.local
EOF

# ZRAM configuration
echo "→ Configuring ZRAM..."
sudo echo "[zram0]
zram-size = min(ram, 8192)" >/etc/systemd/zram-generator.conf

# Pacman eye-candy features
echo "→ Enabling colours and parallel downloads for pacman..."
sudo sed -Ei 's/^#(Color)$/\1/;s/^#(ParallelDownloads).*/\1 = 10/' /etc/pacman.conf

# Setup rust
echo "→ Installing Rust..."
sudo pacman -S --needed --noconfirm rustup
rustup default stable

# Install paru AUR Helper
check_paru="$(sudo pacman -Qs paru | grep "local" | grep "paru")"
if [ -n "${check_paru}" ]; then
  echo "→ Installing paru..."
  sudo pacman -S --needed --noconfirm base-devel
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru
  makepkg -si --needed --noconfirm
fi

# Do an initial update
echo "→ Updating the system..."
paru -Syu --needed --noconfirm

# Install required packages
echo "→ Installing utility packages..."
install_packages "${packages_common_utils[@]}"

# Install window managers
install_window_managers

# Install fonts and missing firmware
echo "→ Installing fonts..."
install_packages "${packages_fonts[@]}"
echo "→ Installing potentially missing firmware..."
install_packages "${packages_firmware[@]}"

# Switch user and root shell to Zsh
echo "→ Switching user and root shell to Zsh..."
sudo chsh -s /usr/bin/zsh $USER
sudo chsh -s /usr/bin/zsh root

# Install miscellaneous packages
install_misc

# Install processor microcode
install_microcode

# Setup Nvidia drivers
install_nvidia_drivers

# Install apps
install_apps

# Install gaming tools
install_gaming_tools

# Setup mandatory mpd folders and files
echo "→ Setting up MPD..."
setup_mpd
# Install flatpaks
echo "→ Installing flatpaks..."
sudo pacman -S --needed --noconfirm flatpak
install_flatpaks

# Set right-click dragging to resize windows in GNOME
echo "→ Setting right-click dragging to resize windows in GNOME..."
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true

# Update tealdeer cache
echo "→ Updating tealdeer cache..."
tldr --update

# Enable services
echo "→ Enabling systemctl services..."
systemctl --user enable pipewire
sudo systemctl enable bluetooth
sudo systemctl enable podman
sudo systemctl enable ollama

# Install Noir Dotfiles
until install_dotfiles; do :; done

choice_reboot=$(gum choose "Yes" "No" --header "INSTALLATION IS COMPLETE. Would you like to reboot now?")
case "$choice_reboot" in
Yes)
  sudo reboot
  ;;
esac
