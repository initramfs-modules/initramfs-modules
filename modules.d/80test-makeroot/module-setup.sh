#!/bin/bash

depends() {
    echo "qemu"
}

install() {
        inst_multiple poweroff cp umount sync dd

        inst_hook initqueue/finished 01 "$moddir/finished-false.sh"
}
