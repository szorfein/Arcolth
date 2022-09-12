# Archaeidae
Custom Archiso focus on privacy.

+ Spoof MAC address for wifi card.
+ Generic hostname set to 'host'.
+ Timezone set to UTC.

## Tools include
+ `Awesomewm`: Highly customizable/light wm.
+ `Lxdm`: Display manager.
+ `Mpd`: Music Player Daemon.
+ `Oh-my-zsh`
+ `Tmux`: Terminal multiplexer.
+ `Tor-Browser`: A web browser focus on privacy.
+ `ZFS`: If need to install ZFS.
+ `Ruby`

## Build iso
Fist, build a custom repository with AUR and custom packages (~= 46M):

    $ ./build-pkgs.sh

And the iso:

    # ./setup.sh
    # cd /root/iso
    # mkarchiso -v -o out .

## Make a bootable usb key
You need a device with at least 1.4G of free space.

    sudo dd bs=4M if=/root/iso/archimg.iso of=/dev/sdX status=progress oflag=sync

## Login
Default login are:
+ User: archlive
+ Pass: archlive

## Links
+ https://gitlab.tails.boum.org/tails/tails/-/tree/master/config/chroot_local-includes
