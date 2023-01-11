#!/bin/bash

TEST_DESCRIPTION="root on an image"

KVERSION="${KVERSION-$(uname -r)}"

CMD="rd.live.overlay.overlayfs=1 rd.live.image panic=1 oops=panic $DEBUGFAIL"

test_me () {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -initrd /efi/kernel/initrd.img -net none \
        -drive file="$TESTDIR"/livedir/squashfs.img,format=raw,index=0 \
        -drive file=fat:rw:"$TESTDIR",format=vvfat,label=live \
        -cdrom "$TESTDIR"/livedir/linux.iso \
        -append "$CMD $1"
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_run() {
    declare -a disk_args=()
    declare -i disk_index=3
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker

    OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
    rm -rf  /boot/vmlinuz*

   # ISO UEFI HARDDISK (isohybrid) scsi-hd
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -net none \
       -drive file="$TESTDIR"/livedir/linux-uefi.iso,format=raw,index=0 \
       -global driver=cfi.pflash01,property=secure,value=on \
       -drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1


#    # squashfs on scsi drive (no bootloader)
#    test_me "root=live:/dev/sda"

#    # vfat on ide drive (no bootloader)
#    test_me "root=LABEL=live rd.live.dir=livedir rd.live.squashimg=squashfs.img"

#    # isofs on cdrom drive (no bootloader)
#    test_me "root=LABEL=ISO"

#    OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
#    rm -rf  /boot/vmlinuz*

#    # ISO UEFI CDROM scsi-cd
#    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
#    "$testdir"/run-qemu "${disk_args[@]}" -net none \
#       -cdrom "$TESTDIR"/livedir/linux.iso \
#       -global driver=cfi.pflash01,property=secure,value=on \
#       -drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on
#    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

#    # ISO legacy CDROM scsi-cd
#    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
#    "$testdir"/run-qemu "${disk_args[@]}" -net none \
#       -drive file="$TESTDIR"/livedir/squashfs.img,format=raw,index=0 \
#       -drive file=fat:rw:"$TESTDIR",format=vvfat,label=live \
#       -cdrom "$TESTDIR"/livedir/linux.iso \
#       -boot order=dc
#    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

   # ISO legacy HARDDISK (isohybrid) scsi-hd
#    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
#    "$testdir"/run-qemu "${disk_args[@]}" -net none \
#       -drive file="$TESTDIR"/livedir/linux.iso,format=raw,index=0
#    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

   # ISO UEFI HARDDISK (isohybrid) scsi-hd
#    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
#    "$testdir"/run-qemu "${disk_args[@]}" -net none \
#       -drive file="$TESTDIR"/livedir/linux.iso,format=raw,index=0 \
#       -global driver=cfi.pflash01,property=secure,value=on \
#       -drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on
#    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

# todo - add initramfs into kernel actually, it is not there now   (basically do not have kernel file and initramfs file)
# first get rid of initramfs file and bake it into kernel - https://github.com/haraldh/mkrescue-uefi/blob/master/mkrescue-uefi.sh change-section-vma .initrd=0x3000000

# todo - usb, mmc
# todo - unified kernel efi
}

test_setup() {
    # use dracut to bootstrap a rootfs directory that you can chroot into --quiet
    "$basedir"/dracut.sh --quiet --no-hostonly --tmpdir "$TESTDIR" --keep --modules "test-root" -i ./test-init.sh /sbin/init \
        "$TESTDIR"/tmp-initramfs.root "$KVERSION" || return 1

    mkdir -p "$TESTDIR"/dracut.*/initramfs/proc
    mkdir "$TESTDIR"/livedir
    mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/livedir/squashfs.img -quiet -no-progress

mkdir /tmp/iso/
cp -a /efi/* /tmp/iso
cp /boot/vmlinuz* /tmp/iso/kernel/vmlinuz

mkdir -p /tmp/iso/LiveOS
cp "$TESTDIR"/livedir/squashfs.img /tmp/iso/LiveOS/squashfs.img
cd /tmp/iso

#echo "root=live:/dev/disk/by-label/ISO $CMD" > /tmp/cmdline
echo "root=/dev/disk/by-label/ISO panic=1 oops=panic rd.debug rd.udev.debug rd.live.debug rd.info console=ttyS0,115200n81 rd.retry=2" > /tmp/cmdline
cat /tmp/cmdline

# make unified kernel
objcopy --verbose  \
    --add-section .osrel="/etc/os-release" --change-section-vma .osrel=0x20000 \
    --add-section .cmdline="/tmp/cmdline" --change-section-vma .cmdline=0x30000 \
    --add-section .linux="./kernel/vmlinuz" --change-section-vma .linux=0x40000 \
    --add-section .initrd="./kernel/initrd.img" --change-section-vma .initrd=0x3000000 \
    /usr/lib/gummiboot/linuxx64.efi.stub /boot/alpine.efi

ls -la /tmp/iso/kernel/vmlinuz
ls -la /boot/alpine.efi

# move image files out of the cd root dir to not include them two times
mkdir /tmp/isotemp
mv isolinux/bios.img /tmp/isotemp/
mv isolinux/efiboot.img /tmp/isotemp/

# cp /boot/alpine.efi /tmp/iso/kernel/vmlinuz
# move the construction of efiboot.img here
# EFI boot partition - FAT16 disk image

cat > /tmp/iso/EFI/BOOT/grub.cfg <<EOF
set timeout=1
set timeout_style=hidden
menuentry linux {
  linux /kernel/vmlinuz root=live:/dev/disk/by-label/ISO $CMD
  initrd /kernel/initrd.img
}
EOF

xorriso -as mkisofs -output "$TESTDIR"/livedir/linux.iso "$TESTDIR"/dracut.*/initramfs/ -volid "ISO" -iso-level 3  \
   -eltorito-boot boot/grub/bios.img \
     -no-emul-boot \
     -boot-load-size 4 \
     -boot-info-table \
     --eltorito-catalog boot/grub/boot.cat \
     --grub2-boot-info \
     --grub2-mbr /tmp/iso/isolinux/boot_hybrid.img \
   -eltorito-alt-boot \
     -e EFI/efiboot.img \
     -no-emul-boot \
   -graft-points \
      "." \
      /boot/grub/bios.img=../isotemp/bios.img \
      /EFI/efiboot.img=../isotemp/efiboot.img

cp /boot/alpine.efi /efi/EFI/BOOT/BOOTX64.efi

ls -la /efi/EFI/BOOT/BOOTX64.efi

ISODIR=/tmp/isotemp/
rm -rf $ISODIR/efiboot.img

dd if=/dev/zero of=$ISODIR/efiboot.img bs=1M count=10
mkfs.vfat $ISODIR/efiboot.img
LC_CTYPE=C mmd -i $ISODIR/efiboot.img EFI EFI/BOOT
LC_CTYPE=C mcopy -i $ISODIR/efiboot.img /efi/EFI/BOOT/BOOTX64.efi ::EFI/BOOT/

ls -la  $ISODIR/efiboot.img
rm -rf isolinux
rm -rf kernel
rm -rf ./EFI/BOOT/grub.cfg

cp -a "$TESTDIR"/dracut.*/initramfs/* .

find .

xorriso -as mkisofs -output "$TESTDIR"/livedir/linux-uefi.iso "$TESTDIR"/dracut.*/initramfs/ -volid "ISO" -iso-level 3  \
   -eltorito-alt-boot \
     -e EFI/efiboot.img \
     -no-emul-boot \
   -graft-points \
      "." \
      /EFI/efiboot.img=../isotemp/efiboot.img

    rm -rf -- "$TESTDIR"/dracut.* "$TESTDIR"/tmp-*
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
