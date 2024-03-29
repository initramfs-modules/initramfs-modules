#!/bin/sh

mkdir -p /efi/kernel/ /lib /tmp/dracut

apk upgrade
apk update

# Temporal build dependencies
apk add git curl xz bzip2 alpine-sdk linux-headers binutils dracut-modules intel-ucode --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community

cd /

# udev depends on libkmod
# rebuild libkmod without openssl lib (libkmod will be dependent on musl and libzstd)
wget https://mirrors.edge.kernel.org/pub/linux/utils/kernel/kmod/kmod-31.tar.xz
xz -d *.xz && tar -xf *.tar && cd kmod-31
./configure --prefix=/usr --bindir=/bin --sysconfdir=/etc --with-rootlibdir=/lib --disable-test-modules --disable-tools --disable-manpages
make
rm -rf /lib/libkmod.so* && make install && make clean 2>&1 > /dev/null
strip /lib/libkmod.so*

cd /
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
bzip2 -d busybox-*.tar.bz2 && tar -xf busybox-*.tar && cd busybox-*
cp $REPO/container/busyboxconfig .config
make oldconfig
diff $REPO/container/busyboxconfig .config
make
strip ./busybox
mv ./busybox /bin/busybox
cd /
rm -rf busybox*

ls -la /bin/busybox
/bin/busybox

# Uninstall temporal build dependencies
apk del xz bzip2 alpine-sdk git curl >/dev/null

# Remove some files that can be be uninstalled becuase of package dependencies
rm /bin/findmnt /usr/bin/cpio
> /usr/sbin/dmsetup
> /bin/dmesg

# workaround - img-lib requires tar
> /bin/tar

cd /

# todo - mount the modules file earlier instead of duplicating them
# this probably need to be done on udev stage (pre-mount is too late)

# to debug, add the following dracut modules
# kernel-modules shutdown terminfo debug

# bare minimium modules "base rootfs-block"
#--mount "/run/media/efi/kernel/modules /usr/lib/modules squashfs ro,noexec,nosuid,nodev" \

# filesystem kernel modules
# nls_XX - to mount vfat
# isofs - to find root within iso file
# autofs4 - systemd will try to load this (maybe because of fstab)

# storage kernel modules
# ahci - for SATA devices on modern AHCI controllers
# nvme - for NVME (M.2, PCI-E) devices
# xhci_pci, uas - usb
# sdhci_acpi, mmc_block - mmc

# sd_mod for all SCSI, SATA, and PATA (IDE) devices
# ehci_pci and usb_storage for USB storage devices
# virtio_blk and virtio_pci for QEMU/KVM VMs using VirtIO for storage
# ehci_pci - USB 2.0 storage devices

# busybox, udev-rules, base, fs-lib, rootfs-block, img-lib, dm, dmsquash-live
# --add-drivers "sd_mod ahci unix vfat nls_cp437 nls_iso8859-1 8250 isofs sr_mod cdrom nvme" \

# ntfs3
cat > /tmp/ntfs3.rules << 'EOF'
SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", ENV{ID_FS_TYPE}="ntfs3"
EOF

dracut --no-early-microcode --nofscks --force --no-hostonly --no-compress --tmpdir /tmp/dracut --keep --no-kernel \
  --modules 'rootfs-block img-lib overlayfs busybox' \
  --include /_tmp/container/infra-init.sh /lib/dracut/hooks/pre-pivot/01-init.sh \
  --include /usr/lib/dracut/modules.d/90kernel-modules/parse-kernel.sh          /lib/dracut/hooks/cmdline/01-parse-kernel.sh \
  --include /usr/lib/dracut/modules.d/90dmsquash-live/parse-dmsquash-live.sh    /lib/dracut/hooks/cmdline/30-parse-dmsquash-live.sh \
  --include /usr/lib/dracut/modules.d/90dmsquash-live/dmsquash-live-root.sh     /sbin/dmsquash-live-root \
  --include /usr/lib/dracut/modules.d/90dmsquash-live/iso-scan.sh               /sbin/iso-scan \
  --include /usr/lib/dracut/modules.d/90dmsquash-live/parse-iso-scan.sh         /lib/dracut/hooks/cmdline/31-parse-iso-scan.sh \
  --include /usr/lib/dracut/modules.d/90dmsquash-live/dmsquash-live-genrules.sh /lib/dracut/hooks/pre-udev/30-dmsquash-live-genrules.sh \
  --include /usr/lib/dracut/modules.d/90dmsquash-live/apply-live-updates.sh     /lib/dracut/hooks/pre-pivot/20-apply-live-updates.sh \
  --include /tmp/ntfs3.rules /lib/udev/rules.d/ntfs3.rules \
  initrd.img $KERNEL

mv /tmp/dracut/dracut.*/initramfs /
cd /initramfs

# TODO
# need to specify root by HW ID /dev/sr0 instead of label and might need to preload isofs
#  rm -rf lib/udev/cdrom_id
#  rm -rf lib/udev/rules.d/60-cdrom_id.rules

# Clean some dracut info files
rm -rf usr/lib/dracut/build-parameter.txt
rm -rf usr/lib/dracut/dracut-*
rm -rf usr/lib/dracut/modules.txt

rm -rf lib/dracut/hooks/initqueue/timeout/99-rootfallback.sh
rm -rf lib/udev/rules.d/75-net-description.rules
rm -rf sbin/rdsosreport

# optimize - Remove empty (fake) binaries
find usr/bin usr/sbin -type f -empty -delete -print
rm -rf lib/dracut/need-initqueue

# just symlinks in alpine
rm -rf sbin/chroot
rm -rf bin/dmesg

rm -rf var/tmp
rm -rf root

# cleanup etc
mv etc/udev/rules.d/59-persistent-storage.rules lib/udev/rules.d/
rm -rf etc
# these directories need to exists during the execution of initramfs
mkdir -p etc/udev/rules.d etc/cmdline.d

rm -rf usr/lib/initrd-release
rm -rf usr/lib/os-release

rm sbin/switch_root && cp /sbin/switch_root sbin/

rm -rf lib/dracut/modules.txt lib/dracut/build-parameter.txt lib/dracut/dracut-*

apk add cpio gzip

rm -rf ./bin/busybox
rm -rf ./bin/gzip
rm -rf ./bin/tar
rm -rf ./bin/dmesg
rm -rf ./sbin/blkid

# Populate logs with the list of filenames inside initrd.img
find . -type f -exec ls -la {} \; | sort -k 5,5  -n -r

find .

find . -print0 | cpio --null --create --format=newc | gzip --best > /efi/kernel/initrd.img

#find . -print0 | cpio --null --create --format=newc > initrd_orig.img
#cat /boot/intel-ucode.img initrd_orig.img | gzip --best > /efi/kernel/initrd.img

ls -la /efi/kernel/initrd*.img

apk del util-linux-misc dracut-modules squashfs-tools git util-linux-misc cpio >/dev/null

rm -rf /tmp
