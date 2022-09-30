#!/bin/bash

depends() {
    echo base
}

installkernel() {
    instmods overlay
}

install() {
    inst_multiple mount rm
    inst_script "$moddir/mount-overlayfs.sh" "/sbin/mount-overlayfs"
}
