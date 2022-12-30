#!/bin/bash

if [ -f /etc/os-release ]; then
 . /etc/os-release
fi

cd /tmp

export KERNEL='5.15.76'

mkdir -p /efi/kernel

export DEBIAN_FRONTEND=noninteractive

# enable getting source debs
sed -i~orig -e 's/# deb-src/deb-src/' /etc/apt/sources.list

apt-get update -y -qq -o Dpkg::Use-Pty=0
apt-get upgrade -y -qq -o Dpkg::Use-Pty=0

apt-get install -y -qq --no-install-recommends -o Dpkg::Use-Pty=0  apt-utils ca-certificates git fakeroot gzip dracut-core wget linux-base sudo libelf1

wget https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh && chmod +x ubuntu-mainline-kernel.sh

sudo ./ubuntu-mainline-kernel.sh -nc -ns --yes -d -p . -i $KERNEL
export KERNEL=$(dpkg -l | grep linux-modules | head -1  | cut -d\- -f3- | cut -d ' ' -f1)

# kernel binary
ls -la /boot

cp -r /boot/vmlinuz-$KERNEL /efi/kernel/vmlinuz

apt-get install -y -qq --no-install-recommends -o Dpkg::Use-Pty=0 squashfs-tools

apt-get install -y -qq --no-install-recommends -o Dpkg::Use-Pty=0 cpio

mkdir /tmp/dracut

dracut --quiet --nofscks --force --no-hostonly --no-early-microcode --no-compress --tmpdir /tmp/dracut --keep --kernel-only \
  --add-drivers 'autofs4 overlay nls_iso8859_1 isofs ntfs ahci nvme xhci_pci uas sdhci_acpi mmc_block pata_acpi virtio_scsi usbhid hid_generic hid' \
  --modules 'rootfs-block' \
  initrd.img $KERNEL

cd  /tmp/dracut/dracut.*/initramfs/

find lib/modules/ -name "*.ko"

find lib/modules/ -print0 | cpio --null --create --format=newc | gzip --best > /efi/kernel/initrd_modules.img

cd /tmp

ls -lha /efi/kernel/initrd_modules.img

mksquashfs /usr/lib/modules /efi/kernel/modules
rm -rf /tmp/initrd

