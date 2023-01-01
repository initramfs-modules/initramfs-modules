#!/bin/sh

: > /dev/watchdog

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
exec > /dev/console 2>&1

echo "dracut-root-block-success" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker

echo "made it to the rootfs!"
ls -lRa /dev/disk/
touch /etc/test
ls -la /etc/
echo "Powering down."
mount -n -o remount,ro /
poweroff -f
