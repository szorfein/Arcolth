#!/usr/bin/env sh

set -o errexit -o nounset

WORKDIR="/root/iso"
HOME_DIR="$WORKDIR"/airootfs/etc/skel

die() { echo "[-] $1"; exit 1; }
goodbye() { echo "\n[+] Script ended, bye"; exit 0; }

trap goodbye SIGTERM

check_permission() {
  myid=$(id -u)
  [ "$myid" -eq 0 ] || die "Permission error, you need to start this script as root."
}

cleanup() {
  [ -d "$WORKDIR" ] && rm -rf "$WORKDIR"
}

copy_release() {
  echo "Check dependencies"
  if ! hash mkarchiso 2>/dev/null ; then
    pacman -S archiso --noconfirm
  fi
  [ -d /usr/share/archiso/configs/releng ] || die "archiso dir no found"
  cp -a /usr/share/archiso/configs/releng "$WORKDIR"
}

create_dirs() {
  [ -d "$WORKDIR" ] || mkdir "$WORKDIR"
  [ -d "$HOME_DIR"/.config ] || mkdir -p "$HOME_DIR"/.config
  [ -d "$HOME_DIR"/.dotfiles ] || mkdir "$HOME_DIR"/.dotfiles
}

download_dots() {
  echo "Adding dotfiles"
  [ -f /tmp/dotfiles.tar.gz ] || curl -s -L -o /tmp/dotfiles.tar.gz https://github.com/szorfein/dotfiles/archive/master.tar.gz
  [ -d /tmp/dotfiles-master ] || (cd /tmp && tar xf dotfiles.tar.gz)
  (cd /tmp/dotfiles-master \
    && cp -a awesomewm/.config/awesome "$HOME_DIR"/.config/ \
    && cp -a picom/.config/picom "$HOME_DIR"/.config/ \
    && cp -a .x/{.Xresources,.xinitrc,.xserverrc} "$HOME_DIR" \
    && cp -a themes "$HOME_DIR"/.dotfiles/
  )
  cat << EOF | tee "$HOME_DIR"/.config/awesome/config/env.lua
terminal = os.getenv("TERMINAL") or "urxvt"
terminal_cmd = terminal .. " -e "
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
web_browser = "midori"
file_browser = "vifm"
terminal_args = { " -T ", " -e " }
net_device = "wlan0"
disks = { "/home" }
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
export TERMINAL=urxvt
export GPG_TTY=\$(tty)
export GPG_AGENT_INFO=""
export ZSH=\$HOME/.oh-my-zsh
# Oh-my-zsh
ZSH_THEME="random"
DISABLE_UPDATE_PROMPT=true
DISABLE_AUTO_UPDATE=true
source \$ZSH/oh-my-zsh.sh
EOF
}

add_archzfs() {
  echo "Adding Archzfs"
  pacman_conf="$WORKDIR"/pacman.conf
  [ -f "$pacman_conf" ] || die "No pacman.conf found"
  cat << EOF | tee -a "$pacman_conf"
[archzfs]
Server = https://archzfs.com/\$repo/\$arch
EOF

  # https://github.com/archzfs/archzfs/wiki#using-the-archzfs-repository
  echo "[+] Updating keys..."
  pacman-key -r DDF7DB817396A49B2A2723F7403BD972F75D9D76 --keyserver hkp://pool.sks-keyservers.net:80
  pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76 --keyserver hkp://pool.sks-keyservers.net:80
  pacman -Syy
}

add_dependencies() {
  cat << EOF | tee -a "$WORKDIR"/packages.x86_64
# Extra deps
ruby
lxdm-gtk3
sudo
midori
xclip
rxvt-unicode
linux-headers
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
xorg-server
# GPU drivers
xf86-video-fbdev
xf86-video-vesa
xf86-video-intel
xf86-video-amdgpu
xf86-video-ati
xf86-video-nouveau
# Nipe
perl-config-simple
perl-cpan-meta-check
perl-yaml
perl-capture-tiny
perl-sub-name
perl-pod-coverage
iptables
tor
EOF
}

add_services() {
  echo "Adding systemd services"
  mkdir -p "$WORKDIR"/airootfs/etc/systemd/system/multi-user.target.wants
  ln -s /usr/lib/systemd/system/lxdm.service archlive/airootfs/etc/systemd/system/display-manager.service
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
}

main "$@"
