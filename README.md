# Archaeidae
Custom Archiso focus on privacy.

* Change the machine-id.
* Local redirection through Tor.
+ Spoofing MAC address.
+ Timezone set to UTC.

## Tools include
+ `Awesomewm`: Highly customizable/light wm.
+ `Lxdm`: Display manager.
+ `Mpd`, `ncmpcpp`: Music Player Daemon.
+ ZSH shell with `Oh-my-zsh`.
+ `Tmux` and `screen`: Terminal multiplexer.
+ Privacy web browsers: `Brave` and `Tor-Browser`.
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

    sudo dd bs=4M if=~/iso/arch.iso of=/dev/sdX status=progress oflag=sync

## Login
Default login are:
+ User: archlive
+ Pass: archlive

## Links
+ https://gitlab.tails.boum.org/tails/tails/-/tree/master/config/chroot_local-includes
