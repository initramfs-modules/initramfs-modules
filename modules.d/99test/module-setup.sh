#!/bin/bash

depends() {
    echo "qemu"
}

install() {
    inst_hook shutdown-emergency 000 "$moddir/hard-off.sh"
    inst_hook emergency 000 "$moddir/hard-off.sh"
}
