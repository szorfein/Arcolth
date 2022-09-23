#!/usr/bin/env sh

set -o errexit -o nounset

WORKDIR="/root/iso-$(date +%Y.%m)"
DEST="/home/ninja/iso"

die() { echo "[-] $1"; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Permission are not enought."
[ -d "$WORKDIR" ] || die "$WORKDIR no found, launch ./setup.sh first."
[ -d "$DEST" ] || die "$DEST no found, create or correct the path please."

mkarchiso -v -w "$WORKDIR" -o "$DEST" "$WORKDIR"
