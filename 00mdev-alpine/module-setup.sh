#!/bin/bash

depends() {
    echo "bash rootfs-block"
}

install() {
    # see https://gitlab.alpinelinux.org/alpine/mkinitfs/-/blob/master/features.d/base.files

    inst_multiple mdev nlplug-findfs cut blkid

    inst /etc/passwd
    inst /etc/group
    inst /etc/mdev.conf

    inst_dir /etc/modprobe.d
    inst_multiple "/etc/modprobe.d/*"

    inst_dir /lib/mdev
    inst_multiple "/lib/mdev/*"

    inst_hook pre-udev 10 "$moddir/mdev-init.sh"
}
