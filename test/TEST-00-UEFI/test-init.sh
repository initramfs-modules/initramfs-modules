#!/bin/sh

# exit when any command fails
set -e

: > /dev/watchdog

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
exec > /dev/console 2>&1


ls -lRa /dev/

echo "made it to the rootfs!"
echo "test" > /etc/test
ls -la /etc/test
echo "Powering down."
mount -n -o remount,ro /
echo "dracut-root-block-success" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
poweroff -f
