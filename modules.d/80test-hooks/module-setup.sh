#!/bin/bash

check() {
    return 255
}

depends() {
    echo base
}

install() {
    inst_hook pre-mount 01 "$moddir/hook-mount-pre.sh"
    inst_hook mount 90 "$moddir/hook-mount-post.sh"
}
