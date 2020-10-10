# Arcnid
Custom Archiso

## Tools include
+ `Awesomewm`: Highly customizable/light wm.
+ `Lxdm`: Display manager.
+ `Midori`: A lightweight web browser.
+ `Nipe`: Hide your IP with TOR, proceed safely.
+ `Oh-my-zsh`
+ `Tmux`: Terminal multiplexer.
+ `Zfs`: If need install ZFS.

## Build iso
Fist, build a custom repository with AUR packages (~= 46M):

    $ ./build-pkgs.sh

And the iso:

    # ./setup.sh
    # cd /root/iso
    # mkarchiso -v -o out .

## Make a bootable usb key
You need a device with at least 2G of free space.

    sudo dd bs=4M if=/root/iso/arcolth.iso of=/dev/sdX status=progress oflag=sync

## Login
Default login are:
+ User: archlive
+ Pass: archlive
