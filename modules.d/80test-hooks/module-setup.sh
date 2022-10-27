#!/bin/bash

check() {
    return 255
}

install() {
    inst_hook mount 90 "$moddir/hook-mount-post.sh"
}
