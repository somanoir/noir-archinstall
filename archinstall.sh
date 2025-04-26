#!/usr/bin/env bash

clear

# Cosmetics (colours for text).
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

# Pretty print (function).
info_print () {
  echo -e "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] $1${RESET}"
}

# Pretty print for input (function).
input_print () {
  echo -ne "${BOLD}${BYELLOW}[ ${BGREEN}•${BYELLOW} ] $1${RESET}"
}

# Alert user of bad input (function).
error_print () {
  echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
}

# Virtualization check (function).
virt_check () {
  hypervisor=$(systemd-detect-virt)
  case $hypervisor in
    kvm )  info_print "KVM has been detected, setting up guest tools."
      pacstrap /mnt qemu-guest-agent &>/dev/null
      systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
      ;;
    vmware )  info_print "VMWare Workstation/ESXi has been detected, setting up guest tools."
      pacstrap /mnt open-vm-tools >/dev/null
      systemctl enable vmtoolsd --root=/mnt &>/dev/null
      systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
      ;;
    oracle )  info_print "VirtualBox has been detected, setting up guest tools."
      pacstrap /mnt virtualbox-guest-utils &>/dev/null
      systemctl enable vboxservice --root=/mnt &>/dev/null
      ;;
    microsoft ) info_print "Hyper-V has been detected, setting up guest tools."
      pacstrap /mnt hyperv &>/dev/null
      systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
      systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
      systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
      ;;
  esac
}

# Selecting a kernel to install (function).
kernel_selector () {
  info_print "List of kernels:"
  info_print "1) Stable: Vanilla Linux kernel with a few specific Arch Linux patches applied"
  info_print "2) Hardened: A security-focused Linux kernel"
  info_print "3) Longterm: Long-term support (LTS) Linux kernel"
  info_print "4) Zen Kernel: A Linux kernel optimized for desktop usage"
  input_print "Please select the number of the corresponding kernel (e.g. 1): "
  read -r kernel_choice
  case $kernel_choice in
    1 ) kernel="linux"
      return 0;;
    2 ) kernel="linux-hardened"
      return 0;;
    3 ) kernel="linux-lts"
      return 0;;
    4 ) kernel="linux-zen"
      return 0;;
    * ) error_print "You did not enter a valid selection, please try again."
      return 1
  esac
}

# Selecting a way to handle internet connection (function).
network_selector () {
  info_print "Network utilities:"
  info_print "1) IWD: Utility to connect to networks written by Intel (WiFi-only, built-in DHCP client)"
  info_print "2) NetworkManager: Universal network utility (both WiFi and Ethernet, highly recommended)"
  info_print "3) wpa_supplicant: Utility with support for WEP and WPA/WPA2 (WiFi-only, DHCPCD will be automatically installed)"
  info_print "4) dhcpcd: Basic DHCP client (Ethernet connections or VMs)"
  info_print "5) I will do this on my own (only advanced users)"
  input_print "Please select the number of the corresponding networking utility (e.g. 1): "
  read -r network_choice
  if ! ((1 <= network_choice <= 5)); then
    error_print "You did not enter a valid selection, please try again."
    return 1
  fi
  return 0
}

# Installing the chosen networking method to the system (function).
network_installer () {
  case $network_choice in
    1 ) info_print "Installing and enabling IWD."
      pacstrap /mnt iwd >/dev/null
      systemctl enable iwd --root=/mnt &>/dev/null
      ;;
    2 ) info_print "Installing and enabling NetworkManager."
      pacstrap /mnt networkmanager >/dev/null
      systemctl enable NetworkManager --root=/mnt &>/dev/null
      ;;
    3 ) info_print "Installing and enabling wpa_supplicant and dhcpcd."
      pacstrap /mnt wpa_supplicant dhcpcd >/dev/null
      systemctl enable wpa_supplicant --root=/mnt &>/dev/null
      systemctl enable dhcpcd --root=/mnt &>/dev/null
      ;;
    4 ) info_print "Installing dhcpcd."
      pacstrap /mnt dhcpcd >/dev/null
      systemctl enable dhcpcd --root=/mnt &>/dev/null
  esac
}

# Setting up a password for the user account (function).
userpass_selector () {
  input_print "Please enter name for a user account (enter empty to not create one): "
  read -r username
  if [[ -z "$username" ]]; then
    return 0
  fi
  input_print "Please enter a password for $username (you're not going to see the password): "
  read -r -s userpass
  if [[ -z "$userpass" ]]; then
    echo
    error_print "You need to enter a password for $username, please try again."
    return 1
  fi
  echo
  input_print "Please enter the password again (you're not going to see it): "
  read -r -s userpass2
  echo
  if [[ "$userpass" != "$userpass2" ]]; then
    echo
    error_print "Passwords don't match, please try again."
    return 1
  fi
  return 0
}

# Setting up a password for the root account (function).
rootpass_selector () {
  input_print "Please enter a password for the root user (you're not going to see it): "
  read -r -s rootpass
  if [[ -z "$rootpass" ]]; then
    echo
    error_print "You need to enter a password for the root user, please try again."
    return 1
  fi
  echo
  input_print "Please enter the password again (you're not going to see it): "
  read -r -s rootpass2
  echo
  if [[ "$rootpass" != "$rootpass2" ]]; then
    error_print "Passwords don't match, please try again."
    return 1
  fi
  return 0
}

# User enters a hostname (function).
hostname_selector () {
  input_print "Please enter the hostname: "
  read -r hostname
  if [[ -z "$hostname" ]]; then
    error_print "You need to enter a hostname in order to continue."
    return 1
  fi
  return 0
}

# Microcode detector (function).
microcode_detector () {
  CPU=$(grep vendor_id /proc/cpuinfo)
  if [[ "$CPU" == *"AuthenticAMD"* ]]; then
    info_print "An AMD CPU has been detected, the AMD microcode will be installed."
    microcode="amd-ucode"
  else
    info_print "An Intel CPU has been detected, the Intel microcode will be installed."
    microcode="intel-ucode"
  fi
}

# User chooses the locale (function).
locale_selector () {
  input_print "Please insert the locale you use (format: xx_XX. Enter empty to use en_US, or \"/\" to search locales): " locale
  read -r locale
  case "$locale" in
    '') locale="en_US.UTF-8"
      info_print "$locale will be the default locale."
      return 0;;
    '/') sed -E '/^# +|^#$/d;s/^#| *$//g;s/ .*/ (Charset:&)/' /etc/locale.gen | less -M
      clear
      return 1;;
    *) if ! grep -q "^#\?$(sed 's/[].*[]/\\&/g' <<< "$locale") " /etc/locale.gen; then
      error_print "The specified locale doesn't exist or isn't supported."
      return 1
    fi
    return 0
  esac
}

# User chooses the console keyboard layout (function).
keyboard_selector () {
  input_print "Please insert the keyboard layout to use in console (enter empty to use US, or \"/\" to look up for keyboard layouts): "
  read -r kblayout
  case "$kblayout" in
    '') kblayout="us"
      info_print "The standard US keyboard layout will be used."
      return 0;;
    '/') localectl list-keymaps
      clear
      return 1;;
    *) if ! localectl list-keymaps | grep -Fxq "$kblayout"; then
      error_print "The specified keymap doesn't exist."
      return 1
    fi
    info_print "Changing console layout to $kblayout."
    loadkeys "$kblayout"
    return 0
  esac
}

# Install required packages
installPackages() {
  for pkg; do
    pacstrap /mnt "${pkg}" &>/dev/null
  done
}

packages_common_utils=(
  "git"
  "git-lfs"
  "intel-ucode"
  "pacman-contrib"
  "curl"
  "wget"
  "unzip"
  "rsync"
  "glibc"
  "cmake"
  "meson"
  "cpio"
  "uv"
  "go"
  "rustup"
  "nodejs"
  "npm"
  "podman"
  "pkgconf-pkg-config"
  "stow"
  "nwg_look"
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
  "network-manager-applet"
  "python3-pip"
  "python3-gobject"
  "gtk4"
  "fastfetch"
  "bluez"
  "bluez-utils"
  "blueman"
  "lm_sensors"
  "yt-dlp"
  "catppuccin-gtk-theme-macchiato"
  "catppuccin-cursors-macchiato"
  "tela-circle-icon-theme-dracula"
  "ly"
  "ntfs-3g"
  "acpi"
  "libva-nvidia-driver"
  "zstd"
  "mlocate"
  "bind"
  "man-db"
  "tealdeer"
  "ark"
  "downgrade"
  "less"
  "ripgrep"
  "reflector"
  "pkgfile"
  "man-pages"
  "openvpn"
  "networkmanager-openvpn"
  "gvfs"
  "gvfs-mtp"
  "gvfs-afc"
  "gvfs-dnssd"
  "gvfs-goa"
  "gvfs-google"
  "gvfs-gphoto2"
  "gvfs-nfs"
  "gvfs-onedrive"
  "gvfs-smb"
  "gvfs-wsdd"
  "umu-launcher"
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
  "qt5"
  "qt6"
  "qt5-qtwayland"
  "qt6-qtwayland"
  "egl-wayland"
  "wlr-randr"
  "wlogout"
  "wl-clipboard"
  "copyq"
  "wofi"
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
  "uwsm"
  )

packages_niri=(
  "niri"
  "xwayland-satellite"
  "xdg-desktop-portal-gnome"
  )

packages_awesome=(
  "awesome"
  "lain"
  "polkit-gnome"
  "arc-icon-theme"
  )

packages_i3=(
  "i3-wm"
  "i3lock"
  "autotiling"
  )

packages_apps=(
  "ghostty"
  "firefox"
  "neovim"
  "vim"
  "nano"
  "vscodium-bin"
  "vscodium-bin-features"
  "vscodium-bin-marketplace"
  "mpd"
  "mpc"
  "mpv"
  "thunar"
  "thunar-archive-plugin"
  "thunar-media-tags-plugin"
  "thunar-shares-plugin"
  "thunar-vcs-plugin"
  "thunar-volman"
  "tumbler"
  "yazi"
  "imagemagick"
  "qbittorrent"
  "keepassxc"
  "calibre"
  "discord"
  "filezilla"
  "filelight"
  "gnome-disk-utility"
  "okular"
  )

packages_fonts=(
  "maplemono-ttf"
  "maplemono-nf-unhinted"
  "maplemono-nf-cn-unhinted"
  "gnu-free-fonts"
  "noto-fonts"
  "ttf-bitstream-vera"
  "ttf-croscore"
  "ttf-dejavu"
  "ttf-droid"
  "ttf-ibm-plex"
  "ttf-liberation"
  "wqy-zenhei"
  "ttf-mona-sans"
  "apple-fonts"
  "ttf-ms-fonts"
  "nerd-fonts"
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

install_flatpaks () {
  flatpak install flathub com.github.tchx84.Flatseal
  flatpak install flathub de.haeckerfelix.Shortwave
  flatpak install flathub com.valvesoftware.Steam
  flatpak install flathub io.gitlab.librewolf-community
  flatpak install flathub md.obsidian.Obsidian
}

install_misc () {
  # RMPC Music player
  cargo install --git https://github.com/mierak/rmpc --locked

  # Ollama
  curl -fsSL https://ollama.com/install.sh | sh
}

install_dotfiles () {
  cd ~
  git clone --depth 1 https://github.com/somanoir/.noir-dotfiles.git
  cd .noir-dotfiles
  stow .

  bat cache --build
  sudo flatpak override --filesystem=xdg-data/themes
}

setup_mpd () {
  mkdir ~/.local/share/mpd
  touch ~/.local/share/mpd/database
  mkdir ~/.local/share/mpd/playlists
  touch ~/.local/share/mpd/state
  touch ~/.local/share/mpd/sticker.sql

  systemctl --user enable --now mpd.service
  mpc update
}


# Setting up keyboard layout.
until keyboard_selector; do : ; done

# Choosing the target for the installation.
info_print "Available disks for the installation:"
PS3="Please select the number of the corresponding disk (e.g. 1): "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
  DISK="$ENTRY"
  info_print "Arch Linux will be installed on the following disk: $DISK"
  break
done

# Setting up the kernel.
until kernel_selector; do : ; done

# User choses the network.
until network_selector; do : ; done

# User choses the locale.
until locale_selector; do : ; done

# User choses the hostname.
until hostname_selector; do : ; done

# User sets up the user/root passwords.
until userpass_selector; do : ; done
until rootpass_selector; do : ; done

# Warn user about deletion of old partition scheme.
input_print "This will delete the current partition table on $DISK once installation starts. Do you agree [y/N]?: "
read -r disk_response
if ! [[ "${disk_response,,}" =~ ^(yes|y)$ ]]; then
  error_print "Quitting."
  exit
fi
info_print "Wiping $DISK."
wipefs -af "$DISK" &>/dev/null
sgdisk -Zo "$DISK" &>/dev/null

# Creating a new partition scheme.
info_print "Creating the partitions on $DISK."
parted -s "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 1025MiB \
  set 1 esp on \
  mkpart ROOT 1025MiB 100% \

ESP="/dev/disk/by-partlabel/ESP"
ROOT="/dev/disk/by-partlabel/ROOT"

# Informing the Kernel of the changes.
info_print "Informing the Kernel about the disk changes."
partprobe "$DISK"

# Formatting the ESP as FAT32.
info_print "Formatting the EFI Partition as FAT32."
mkfs.fat -F 32 "$ESP" &>/dev/null

# Formatting the ROOT as EXT4.
mkfs.ext4 "$ROOT"
mount "$ROOT" /mnt

mkdir /mnt/boot
mount "$ESP" /mnt/boot/

# Checking the microcode to install.
microcode_detector

# Pacstrap (setting up a base sytem onto the new root).
info_print "Installing the base system (it may take a while)."
pacstrap -K /mnt base base-devel "$kernel" "$microcode" linux-firmware "$kernel"-headers refind rsync efibootmgr reflector zram-generator sudo &>/dev/null

# Setting up the hostname.
echo "$hostname" > /mnt/etc/hostname

# Generating /etc/fstab.
info_print "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Configure selected locale and console keymap
sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Setting hosts file.
info_print "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1     localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Virtualization check.
virt_check

# Setting up the network.
network_installer

# Configuring /etc/mkinitcpio.conf.
info_print "Configuring /etc/mkinitcpio.conf."
cat > /mnt/etc/mkinitcpio.conf <<EOF
HOOKS=(systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems)
EOF

# Configuring the system.
info_print "Configuring the system (timezone, system clock, initramfs, Snapper, GRUB)."
arch-chroot /mnt /bin/bash -e <<EOF
  # Setting up timezone.
  ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line/?fields=timezone) /etc/localtime &>/dev/null

  # Setting up clock.
  hwclock --systohc

  # Generating locales.
  locale-gen &>/dev/null

  # Generating a new initramfs.
  mkinitcpio -P &>/dev/null

  # Setup rEFInd
  refind-install && refind-mkdefault
EOF

# Setting root password.
info_print "Setting root password."
echo "root:$rootpass" | arch-chroot /mnt chpasswd

# Setting user password.
if [[ -n "$username" ]]; then
  echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/wheel
  info_print "Adding the user $username to the system with root privilege."
  arch-chroot /mnt useradd -m -G wheel -s /bin/zsh "$username"
  info_print "Setting user password for $username."
  echo "$username:$userpass" | arch-chroot /mnt chpasswd
fi

# Boot backup hook.
info_print "Configuring /boot backup when pacman transactions are made."
mkdir /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/50-bootbackup.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF

# Fix laptop lid acting like airplane mode key
mkdir /mnt/etc/rc.d
echo "#!/usr/bin/env bash
# Fix laptop lid acting like airplane mode key
setkeycodes d7 240
setkeycodes e058 142" > /mnt/etc/rc.d/rc.local

# ZRAM configuration.
info_print "Configuring ZRAM."
cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram, 8192)
EOF

# Pacman eye-candy features.
info_print "Enabling colours and parallel downloads for pacman."
sed -Ei 's/^#(Color)$/\1/;s/^#(ParallelDownloads).*/\1 = 10/' /mnt/etc/pacman.conf

# Install packages
info_print "Installing utilities, WMs and applications"
installPackages "${packages_common_utils[@]}"
installPackages "${packages_common_x11[@]}"
installPackages "${packages_common_wayland[@]}"

installPackages "${packages_hyprland[@]}"
installPackages "${packages_niri[@]}"
installPackages "${packages_awesome[@]}"
installPackages "${packages_i3[@]}"

installPackages "${packages_apps[@]}"
installPackages "${packages_fonts[@]}"
installPackages "${packages_firmware[@]}"
installPackages "${packages_nvidia[@]}"

arch-chroot -u "$username" /mnt bash -s <<EOF
  # Install flatpaks
  sudo pacman -S flatpak
  install_flatpaks

  # Setup rust
  rustup default stable

  # Install miscellaneous packages
  install_misc

  # Setup mandatory mpd folders and files
  setup_mpd

  # Create user folders
  mkdir /home/"$username"/{Code,Games,Media,Misc,Mounts,My}

  # Enable services
  systemctl --user enable pipewire
  sudo systemctl enable bluetooth.service
  sudo systemctl enable podman
  sudo systemctl enable ollama
EOF

# Finishing up.
info_print "Done, you may now wish to reboot (further changes can be done by chrooting into /mnt)."
exit
