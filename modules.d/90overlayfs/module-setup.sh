#!/bin/bash

depends() {
    echo base
}

installkernel() {
    instmods overlay
}

install() {
    inst_hook pre-pivot 01 "$moddir/mount-overlayfs.sh"
}
