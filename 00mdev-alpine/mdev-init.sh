#!/bin/sh

nlplug-findfs -p /sbin/mdev

rm -rf /lib/dracut/hooks/pre-udev/30-block-genrules.sh
