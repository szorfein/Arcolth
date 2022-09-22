# Archaeidae
Custom Archiso (not yet) focus on privacy.

## Tools include
+ `Awesomewm`: Highly customizable/light wm.
+ `Lxdm`: Display manager.
+ `Mpd`: Music Player Daemon.
+ `Oh-my-zsh`
+ `Tmux`: Terminal multiplexer.
+ Privacy web browsers: `Brave` and `Tor-Browser`.
+ `ZFS`: If need to install ZFS.

## Build iso
Fist, build a custom repository with AUR packages (~= 244M):

    $ ./build-pkgs.sh

And the iso:

    $ sudo ./setup.sh
    $ sudo ./iso-build.sh

## Make a bootable usb key
You need a device with at least 2G of free space (1.5G for the iso).

    sudo dd bs=4M if=arch.iso of=/dev/sdX status=progress oflag=sync

## Login
Default login are:
+ User: archlive
+ Pass: archlive
