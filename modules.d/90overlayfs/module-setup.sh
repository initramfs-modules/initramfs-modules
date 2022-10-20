#!/bin/bash

depends() {
    echo base
}

installkernel() {
    instmods overlay
}

install() {
    inst_hook mount 99 "$moddir/mount-overlayfs.sh"
}
