#!/usr/bin/env sh

set -o errexit -o nounset

WORKDIR=$HOME/build
DEST=/tmp/pkgs

die() { echo "[-] $1"; exit 1; }

cleanup() {
  [ -d "$WORKDIR" ] && rm -rf "$WORKDIR"
  [ -d "$DEST" ] && rm -rf "$DEST"
  [ -d "$WORKDIR" ] || mkdir -p "$WORKDIR"
  [ -d "$DEST" ] || mkdir -p "$DEST"
}

check_permission() {
  if [ "$(id -u)" -eq 0 ] ; then
    die "Permission too high, use a normal user"
  fi
}

aur() {
  echo "Building $1"
  (cd "$WORKDIR" \
    && wget -cv https://aur.archlinux.org/cgit/aur.git/snapshot/$1.tar.gz \
    && tar xvf $1.tar.gz \
    && cd $1 \
    && makepkg --noconfirm -sC \
    && cp "$1"-*.pkg.tar.zst "$DEST"/
  )
  rm -rf "$WORKDIR/$1"
  echo "Done with $1"
}

tor_key() {
  # https://support.torproject.org/tbb/how-to-verify-signature/
  curl -s https://openpgpkey.torproject.org/.well-known/openpgpkey/torproject.org/hu/kounek7zrdx745qydx6p59t9mqjpuhdf | gpg --import -
}

build_src() {
  (cd "$WORKDIR" \
    && cd "$1" \
    && makepkg --noconfirm -s \
    && cp "$1"-*.pkg.tar.zst "$DEST"/
  )
}

gen_packages() {
  cp -a packages/* "$WORKDIR"/
  build_src "lxdm-theme-archaeidae"
  build_src "ruby-nomansland"
  build_src "ruby-tty-which"
}

create_repo() {
  echo "Creating repo pkgs $DEST"
  cd "$DEST"
  pkgs=$(ls *.pkg.tar.zst)
  for i in $pkgs ; do
    repo-add pkgs.db.tar.gz "$i"
  done
}

main() {
  cleanup
  check_permission
  aur yay
  aur xst-git
  aur cava
  aur python-ueberzug
  tor_key
  aur tor-browser
  gen_packages
  create_repo
}

main "$@"
