#!/bin/sh

trap 'poweroff -f' EXIT

set -ex

mkfs.ext4 -q  /dev/sdb
mkdir -p /root
mount /dev/sdb /root
cp -a -t /root /source/*
umount /root
echo "dracut-root-block-created" | dd oflag=direct,dsync of=/dev/sda
poweroff -f
