#!/bin/bash

check() {
    # Only include the module if another module requires it
    return 255
}

install() {
    # see https://gitlab.alpinelinux.org/alpine/mkinitfs/-/blob/master/features.d/base.files

    # /lib/mdev/persistent-storage is dependent on blkid
    # /lib/mdev/persistent-storage is dependent on cut

    inst_multiple mdev nlplug-findfs blkid cut

    inst /etc/passwd
    inst /etc/group
    inst /etc/mdev.conf

    inst_dir /etc/modprobe.d
    inst_multiple "/etc/modprobe.d/*"

    inst_dir /lib/mdev
    inst_multiple "/lib/mdev/*"

    inst_hook pre-udev 10 "$moddir/mdev-init.sh"
}
