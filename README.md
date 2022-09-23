# Archaeidae
Custom Archiso focus on privacy.

## Tools include
+ `Awesomewm`: Highly customizable/light wm.
+ `Brave` and `Tor-Browser`: Privacy web browsers, avoid to use `tor-browser` if `spior` is enable ([Tor Over Tor](https://gitlab.torproject.org/legacy/trac/-/wikis/doc/TorifyHOWTO#tor-over-tor).
+ `Lxdm`: Display manager.
+ `Mpd`, `ncmpcpp`: Music Player Daemon.
+ ZSH shell with `Oh-my-zsh`.
+ `Tmux` and `screen`: Terminal multiplexer.
+ `ZFS`: If need to install it.
+ `Ruby` with [getch](https://github.com/szorfein/getch) and [spior](https://github.com/szorfein/spior).

## Build iso
Fist, build a custom repository with AUR and custom packages (~= 244M):

    $ ./build-pkgs.sh

And the iso:

    $ sudo ./setup.sh
    $ sudo ./iso-build.sh

## Make a bootable usb key
You need a device with at least 2G of free space (1.5G for the iso).

    sudo dd bs=4M if=~/iso/arch.iso of=/dev/sdx conv=fsync oflag=direct status=progress

## Login
Default login are:
+ User: archlive
+ Pass: archlive

## Test
Install the deps: [ref](https://wiki.archlinux.org/title/archiso#Test_the_ISO_in_QEMU)

    sudo pacman -S qemu-desktop edk2-ovmf

For BIOS

    run_archiso -i path/to/an/arch.iso

With EFI

    run_archiso -u -i path/to/an/arch.iso

## Links
+ https://gitlab.tails.boum.org/tails/tails/-/tree/master/config/chroot_local-includes
