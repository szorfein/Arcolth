#!/usr/bin/env sh

set -o errexit -o nounset

WORKDIR="/root/iso-$(date +%Y.%m)"
HOME_DIR="$WORKDIR"/airootfs/etc/skel
THEME="lines"
PKGS=/tmp/pkgs

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
  cp -a /usr/share/archiso/configs/releng "$WORKDIR"
  sed -i 's/MODULES=()/MODULES=(i915? amdgpu? radeon? nouveau? vboxvideo? vmwgfx?)/g' "$WORKDIR"/airootfs/etc/mkinitcpio.conf
}

create_dirs() {
  [ -d "$WORKDIR" ] || mkdir "$WORKDIR"
  [ -d "$HOME_DIR"/.config ] || mkdir -p "$HOME_DIR"/.config
  [ -d "$HOME_DIR"/.dotfiles ] || mkdir "$HOME_DIR"/.dotfiles
  [ -d "$HOME_DIR"/images ] || mkdir "$HOME_DIR"/images
  cp -a configs/* "$WORKDIR"/airootfs/
  chmod -R 740 "$WORKDIR"/airootfs/etc/sudoers.d
}

download_dots() {
  echo "Adding dotfiles"
  [ -f /tmp/dotfiles.tar.gz ] || curl -s -L -o /tmp/dotfiles.tar.gz https://github.com/szorfein/dotfiles/archive/main.tar.gz
  [ -d /tmp/dotfiles-master ] || (cd /tmp && tar xf dotfiles.tar.gz)
  (cd /tmp/dotfiles-main \
    && cp -a awesomewm/.config/awesome "$HOME_DIR"/.config/ \
    && cp -a .x/{.Xresources,.xinitrc,.xserverrc} "$HOME_DIR" \
    && cp -a vim/{.vim,.vimrc} "$HOME_DIR" \
    && cp -a ncmpcpp/.ncmpcpp "$HOME_DIR" \
    && cp -a tmux/.tmux.conf "$HOME_DIR" \
    && cp -a vifm/{.config,bin} "$HOME_DIR" \
    && cp -a audio/pulse-generic/bin/volume.sh "$HOME_DIR"/bin/ \
    && cp -a themes "$HOME_DIR"/.dotfiles/ \
    && ./install --dest "$HOME_DIR" --vim --images --fonts \
    && rm -rf "$HOME_DIR"/.local/fonts/{Iosevka}* # we use the AUR pkgs
  )
  cat << EOF | tee -a "$HOME_DIR"/.config/awesome/module/autostart.lua
app.run_once({'systemctl --user start mpd'})
EOF
  cat << EOF | tee "$WORKDIR"/airootfs/etc/lxdm/PostLogin
#!/bin/sh
[ -f ~/.config/awesome/loaded-theme.lua ] || (cd ~/.dotfiles/themes && stow $THEME -t ~)
EOF
  chmod 755 "$WORKDIR"/airootfs/etc/lxdm/PostLogin
  cat << EOF | tee "$HOME_DIR"/.config/awesome/config/env.lua
terminal = os.getenv("TERMINAL") or "xst"
terminal_cmd = terminal .. " -e "
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
web_browser = "tor-browser"
file_browser = "vifm"
terminal_args = { " -c ", " -e " }
net_device = "lo"
disks = { "/" }
cpu_core = 1
sound_system = "pulseaudio"
password = "awesome"
EOF
}

add_omz() {
  echo "Adding oh-my-zsh"
  [ -f /tmp/oh-my-zsh.tar.gz ] || curl -s -L -o /tmp/oh-my-zsh.tar.gz https://github.com/robbyrussell/oh-my-zsh/archive/master.tar.gz
  [ -d /tmp/ohmyzsh-master ] || (cd /tmp && tar xf oh-my-zsh.tar.gz)
  cp -a /tmp/ohmyzsh-master "$HOME_DIR"/.oh-my-zsh

  # Remove grml-zsh-config, we have a default .zshrc
  sed -i 's/grml-zsh-config//g' "$WORKDIR"/packages.x86_64

cat << EOF | tee "$HOME_DIR"/.zshrc
export PATH=\$HOME/bin:\$PATH
export PATH="\$PATH:\$(ruby -e 'puts Gem.user_dir')/bin"
export TERMINAL=xst
export GPG_TTY=\$(tty)
export GPG_AGENT_INFO=""
export ZSH=\$HOME/.oh-my-zsh
# Oh-my-zsh
ZSH_THEME="random"
DISABLE_UPDATE_PROMPT=true
DISABLE_AUTO_UPDATE=true
source \$ZSH/oh-my-zsh.sh
alias vifm=vifmrun
EOF
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
ruby
gcc
lxdm-gtk3
materia-gtk-theme
sudo
xclip
linux-headers
tmux
vifm
scrot
light
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
picom
feh
stow
imagemagick
# Xorg
xorg-server
xorg-xprop
xorg-xrandr
xorg-xrdb
# GPU drivers
xf86-video-intel
xf86-video-amdgpu
xf86-video-nouveau
iptables
tor
# AUR
yay
xst-git
ttf-iosevka-nerd
cava
python-ueberzug
tor-browser
# Custom pkgs
lxdm-theme-archaeidae
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

main() {
  check_permission
  cleanup
  copy_release
  create_dirs
  download_dots
  add_omz
  add_archzfs
  add_dependencies
  add_services
  add_user
  privacy
}

main "$@"
