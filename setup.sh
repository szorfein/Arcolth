#!/usr/bin/env sh

set -o errexit -o nounset

WORKDIR="/root/iso-$(date +%Y.%m)"
HOME_DIR="$WORKDIR"/airootfs/etc/skel
THEME="lines"
PKGS=/tmp/pkgs
CURR_USER="/home/ninja"

die() { echo "[-] $1"; exit 1; }
goodbye() { echo; echo "[+] Script ended, bye"; exit 0; }

trap goodbye EXIT

check_permission() {
  if [ "$(id -u)" -ne 0 ] ; then
    die "Permission error, you need to start this script as root."
  fi
}

cleanup() {
  if [ -d "$WORKDIR" ] ; then
    echo "Clean older $WORKDIR"
    rm -rf "$WORKDIR"
  fi
}

check_dep() {
  if ! hash "$1" 2>/dev/null ; then
    pacman -S "$2" --noconfirm
  fi
}

copy_release() {
  echo "Check dependencies"
  check_dep mkarchiso archiso
  check_dep tor tor
  check_dep lxdm lxdm-gtk3
  check_dep unzip unzip
  check_dep mpd mpd
  [ -d /usr/share/archiso/configs/releng ] || die "archiso dir no found"

  cp -r /usr/share/archiso/configs/releng "$WORKDIR"
  sed -i 's/MODULES=()/MODULES=(i915? amdgpu? radeon? nouveau? vboxvideo? vmwgfx?)/g' "$WORKDIR"/airootfs/etc/mkinitcpio.conf
}

create_dirs() {
  mkdir -p "$WORKDIR"
  mkdir -p "$HOME_DIR"/{.config,.dotfiles,images}
  mkdir -p "$HOME_DIR"/.local/share/fonts
  cp -r configs/* "$WORKDIR"/airootfs/
}

download_dots() {
  echo "Adding dotfiles"
  [ -f /tmp/dotfiles.tar.gz ] || curl -s -L -o /tmp/dotfiles.tar.gz https://github.com/szorfein/dotfiles/archive/main.tar.gz
  [ -d /tmp/dotfiles-main ] || (cd /tmp && tar xf dotfiles.tar.gz)
  (cd /tmp/dotfiles-main \
    && cp -r awesomewm/.config/* "$HOME_DIR"/.config/ \
    && cp -r .x/{.Xresources,.xinitrc,.xserverrc} "$HOME_DIR" \
    && cp -r vim/{.vim,.vimrc} "$HOME_DIR" \
    && cp -r ncmpcpp/.ncmpcpp "$HOME_DIR" \
    && cp -r tmux/.tmux.conf "$HOME_DIR" \
    && cp -r vifm/{.config,bin} "$HOME_DIR" \
    && cp -r audio/pulse-generic/bin/volume.sh "$HOME_DIR"/bin/ \
    && cp -r themes "$HOME_DIR"/.dotfiles/ \
    && ./install --dest "$HOME_DIR" --images
  )
  cat << EOF | tee -a "$HOME_DIR"/.config/awesome/module/autostart.lua
app.run_once({'systemctl --user start mpd'})
EOF
  cat << EOF | tee "$WORKDIR"/airootfs/etc/lxdm/PostLogin
#!/usr/bin/env sh
[ -f ~/.config/awesome/loaded-theme.lua ] || (cd ~/.dotfiles/themes && stow $THEME -t ~)
EOF
}

copy_from_home() {
  cp -r "$CURR_USER"/.oh-my-zsh "$HOME_DIR"/
  cp -r "$CURR_USER"/.vim/{plugged,autoload} "$HOME_DIR"/.vim/
  cp -r "$CURR_USER"/.local/share/fonts/{cyberpunk,MaterialDesign-Font-master,SpaceMono-2.1.0} "$HOME_DIR"/.local/share/fonts/
}

add_archzfs() {
  echo "Adding Archzfs"
  pacman_conf="$WORKDIR"/pacman.conf
  [ -f "$pacman_conf" ] || die "No pacman.conf found"
  [ -d "$PKGS" ] || die "Repo pkgs $PKGS no found, use build-pkgs.sh to generate one."
  cat << EOF | tee -a "$pacman_conf"
[pkgs]
SigLevel = Optional TrustAll
Server = file:///$PKGS

[archzfs]
Server = https://archzfs.com/\$repo/\$arch
EOF

  # https://github.com/archzfs/archzfs/wiki#using-the-archzfs-repository
  echo "[+] Updating keys..."
  key="DDF7DB817396A49B2A2723F7403BD972F75D9D76"
  if ! pacman-key -r "$key" ; then
    echo "importing manually"
  fi
  if ! pacman-key --lsign-key "$key" ; then
    curl -o key.gpg -L https://archzfs.com/archzfs.gpg
    pacman-key -a key.gpg
    # https://github.com/archzfs/archzfs/issues/342
    pacman-key --lsign-key "$key"
  fi
  pacman -Syy
}

add_dependencies() {
  cat << EOF | tee -a "$WORKDIR"/packages.x86_64
# Extra deps
gcc
lxdm-gtk3
linux-headers
materia-gtk-theme
ruby
sudo
# Audio
pulseaudio
pulseaudio-alsa
# Music
mpd
ncmpcpp
mpc
# ZFS
archzfs-linux
# Touchpad
xorg-xinput
xf86-input-libinput
# Awesome
awesome
feh
gvim
imagemagick
light
mpv
picom
ueberzug
scrot
stow
tmux
ttf-iosevka-nerd
vifm
xclip
# Xorg
xorg-server
xorg-xprop
xorg-xrandr
xorg-xrdb
# GPU drivers
xf86-video-intel
xf86-video-amdgpu
xf86-video-nouveau
virtualbox-guest-utils
# Privacy
tor
iptables
macchanger
# AUR
brave-bin
cava
tor-browser
xst-git
yay
# Custom pkgs
lxdm-theme-archaeidae
ruby-nomansland
ruby-tty-which
ruby-interfacez
ruby-rainbow
ruby-spior
ruby-getch
EOF
}

add_services() {
  echo "Adding systemd services"
  want_dir="$WORKDIR"/airootfs/etc/systemd/system/multi-user.target.wants
  mkdir -p "$want_dir"
  ln -s /usr/lib/systemd/system/lxdm.service "$WORKDIR"/airootfs/etc/systemd/system/display-manager.service
  ln -s /usr/lib/systemd/system/tor.service "$want_dir"/
  ln -s /usr/lib/systemd/system/iptables.service "$want_dir"/
}

add_user() {
  username="archlive"
  cat << EOF | tee -a "$WORKDIR"/airootfs/etc/passwd
$username:x:1000:1000::/home/$username:/usr/bin/zsh
EOF
  # Default pass: archlive
  cat << EOF | tee -a "$WORKDIR"/airootfs/etc/shadow
$username:$(openssl passwd -6 "$username"):14871::::::
EOF
  cat << EOF | tee "$WORKDIR"/airootfs/etc/group
root:x:0:root
adm:x:4:$username
wheel:x:10:$username
uucp:x:14:$username
audio:x:15:$username
video:x:16:$username
$username:x:1000
EOF
  cat << EOF | tee -a "$WORKDIR"/airootfs/etc/gshadow
root:!!::root
$username:!!::
EOF
  cat << EOF | tee -a "$WORKDIR"/airootfs/root/customize_airootfs.sh
chown -R $username:$username /home/$username
EOF
}

privacy() {
  echo "[+] Setting privacy..."
  ln -sf /usr/share/zoneinfo/UTC "$WORKDIR"/airootfs/etc/localtime
  [ -d "$WORKDIR"/airootfs/etc/iptables ] || \
    mkdir -p "$WORKDIR"/airootfs/etc/iptables

  iptables-save -f "$WORKDIR"/airootfs/etc/iptables/iptables.rules
}

auth() {
  sudo_dir="$WORKDIR/airootfs/etc/sudoers.d"
  cat > "$sudo_dir/zzz_halt" <<- _EOF_
$username ALL = NOPASSWD: /sbin/poweroff ""
$username ALL = NOPASSWD: /sbin/reboot ""
_EOF_
}

fix_permissions() {
  cat >> "$WORKDIR"/profiledef.sh <<- _EOF_
file_permissions+=(
  ["/etc/gshadow"]="0:0:400"
  ["/etc/hostname"]="0:0:444"
  ["/etc/iwd"]="0:0:755"
  ["/etc/lxdm"]="0:0:755"
  ["/etc/lxdm/PostLogin"]="0:0:777"
  ["/etc/machine-id"]="0:0:444"
  ["/etc/skel/"]="0:0:755"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/tor"]="0:0:755"
)
_EOF_
}

fix_boot() {
  # restore systemd-boot
  sed -i 's/uefi-x64.grub.esp/uefi-x64.systemd-boot.esp/g' "$WORKDIR"/profiledef.sh
  sed -i 's/uefi-x64.grub.eltorito/uefi-x64.systemd-boot.eltorito/g' "$WORKDIR"/profiledef.sh
}

remove_packages() {
  # Remove grml-zsh-config, we have a default .zshrc
  sed -i 's/grml-zsh-config//g' "$WORKDIR"/packages.x86_64
  sed -i 's/vim//g' "$WORKDIR"/packages.x86_64 # we use gvim
  sed -i 's/virtualbox-guest-utils-nox//g' "$WORKDIR"/packages.x86_64
  sed -i 's/ipw2100-fw//g' "$WORKDIR"/packages.x86_64
  sed -i 's/ipw2200-fw//g' "$WORKDIR"/packages.x86_64
}

clean_the_useless() {
  rm -rf "$HOME_DIR"/.vim/plugged/**/.git
}

main() {
  check_permission
  cleanup
  copy_release
  create_dirs
  download_dots
  copy_from_home
  add_archzfs
  remove_packages
  add_dependencies
  add_services
  add_user
  privacy
  auth
  fix_permissions
  fix_boot
  clean_the_useless
}

main "$@"
