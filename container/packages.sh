#!/bin/sh

# kernel, init
RUN apk add linux-virt losetup

# dracut
RUN apk add dracut --update-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing --allow-untrusted

# Uninstall most mkinitfs files. mkinitfs gets pulled in by linux-virt
RUN rm -rf /sbin/mkinitfs /usr/share/mkinitfs /etc/mkinitfs /boot/initramfs-*

RUN ln -sf /boot/vmlinuz-virt /boot/vmlinuz-$(cd /lib/modules; ls -1 | tail -1)

# common
RUN apk add \
    btrfs-progs cryptsetup dash dmraid mdadm sed lvm2 make sudo e2fsprogs parted bzip2 pigz procps kbd busybox git grep binutils

# common - but distro specific name
RUN apk add partx gpg multipath-tools openssh squashfs-tools qemu-img qemu-system-x86_64 sfdisk ntfs-3g xz

# networking
RUN apk add nfs-utils libnfsidmap dhclient open-iscsi nbd curl

# btrfs - btrfs-progs - btrfs
# crypt - cryptsetup - crypt
# dash - dash - dash
# dmraid - dmraid, partx - dmraid
# gpg - gpg - crypt-gpg
# mdadm - mdadm, sed, partx - mdraid # sed: bad regex '(RUN|IMPORT\{program\})\+?="[[:alpha:]': Missing ']'
# lvm - lvm2 - lvm, lvmmerge, lvmthinpool-monitor
# multipath - multipath-tools, partx - multipath
# openssh - openssh, dracut-modules-network - ssh-client
# squashfs - squashfs-tools - squash

# RUN apk add networkmanager

# additional dependencies to run tests for networking
# RUN apk add qemu-block-nfs qemu-modules

RUN cp /sbin/poweroff /sbin/shutdown
RUN cp /usr/bin/dash /bin/dash
RUN cp /bin/sh /usr/bin/sh

