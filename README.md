# Archaeidae
Custom Archiso (not yet) focus on privacy.

## Tools include
+ `Awesomewm`: Highly customizable/light wm.
+ `Lxdm`: Display manager.
+ `Mpd`: Music Player Daemon.
+ `Oh-my-zsh`
+ `Tmux`: Terminal multiplexer.
+ `Tor-Browser`: A web browser focus on privacy.
+ `ZFS`: If need to install ZFS.

## Build iso
Fist, build a custom repository with AUR packages (~= 111M):

    $ ./build-pkgs.sh

And the iso:

    $ sudo ./setup.sh
    $ sudo ./iso-build.sh

## Make a bootable usb key
You need a device with at least 2G (1.4G for the iso) of free space.

    sudo dd bs=4M if=arch.iso of=/dev/sdX status=progress oflag=sync

## Login
Default login are:
+ User: archlive
+ Pass: archlive
