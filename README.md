# Arcolth
Custom Archiso

## Tools include

+ `Awesomewm`: Highly customizable/light wm
+ `Lxdm`: display manager
+ `Nipe`: Hide your IP with TOR, proceed safely.
+ `Oh-my-zsh`
+ `Zfs`: If need install ZFS.

## Build iso

    ./setup.sh
    cd iso
    mkarchiso -v -o out .

## Make a bootable usb key

    sudo dd bs=4M if=/path/to/arcolth.iso of=/dev/sdX status=progress oflag=sync
