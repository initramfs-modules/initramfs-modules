#!/bin/sh

#debug
mkdir -p /run/initramfs/gombi

if [ -e /sys/firmware/qemu_fw_cfg/by_name/opt/io.dracut/cmdline/raw ]; then
  mkdir -p /etc/cmdline.d/
  cat /sys/firmware/qemu_fw_cfg/by_name/opt/io.dracut/cmdline/raw >> "/etc/cmdline.d/qemu.conf"
  cp /etc/cmdline.d/qemu.conf /run/initramfs/gombi/
fi
