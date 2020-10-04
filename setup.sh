#!/usr/bin/env sh

set -o errexit -o nounset

WORKDIR="/root/iso"
HOME_DIR="$WORKDIR"/airootfs/etc/skel
THEME="lines"

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
  [ -f /tmp/dotfiles.tar.gz ] || curl -s -L -o /tmp/dotfiles.tar.gz https://github.com/szorfein/dotfiles/archive/master.tar.gz
  [ -d /tmp/dotfiles-master ] || (cd /tmp && tar xf dotfiles.tar.gz)
  (cd /tmp/dotfiles-master \
    && cp -a awesomewm/.config/awesome "$HOME_DIR"/.config/ \
    && cp -a themes "$HOME_DIR"/.dotfiles/
  )
}

add_omz() {
  [ -f /tmp/oh-my-zsh.tar.gz ] || curl -s -L -o /tmp/oh-my-zsh.tar.gz https://github.com/robbyrussell/oh-my-zsh/archive/master.tar.gz
  [ -d /tmp/ohmyzsh-master ] || (cd /tmp && tar xf oh-my-zsh.tar.gz)
  cp -a /tmp/ohmyzsh-master "$HOME_DIR"/.oh-my-zsh
}

add_archzfs() {
  pacman_conf="$WORKDIR"/pacman.conf
  [ -f "$pacman_conf" ] || die "No pacman.conf found"
  cat << EOF | tee -a "$pacman_conf"
[archzfs]
Server = https://archzfs.com/\$repo/\$arch
EOF

  echo "[+] Updating keys..."
  pacman-key -r DDF7DB817396A49B2A2723F7403BD972F75D9D76 --keyserver hkp://pool.sks-keyservers.net:80
  pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76 --keyserver hkp://pool.sks-keyservers.net:80
  pacman -Syy
}

add_dependencies() {
  cat << EOF | tee -a "$WORKDIR"/packages.x86_64
awesome
ruby
# for Nipe
iptables
tor
EOF
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
}

main "$@"
