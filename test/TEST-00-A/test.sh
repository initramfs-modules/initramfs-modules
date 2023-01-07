#!/bin/bash

TEST_DESCRIPTION="root on an image"

# test for different if= .. possible values= ide, scsi, sd, mtd, floppy, pflash, virtio

KVERSION="${KVERSION-$(uname -r)}"

ls -la /efi/kernel/initrd.img

test_me () {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -initrd /efi/kernel/initrd.img \
        -drive file="$TESTDIR"/livedir/rootfs.squashfs,format=raw,index=0 \
        -drive file=fat:rw:"$TESTDIR",format=vvfat,label=live \
        -cdrom "$TESTDIR"/livedir/linux.iso \
        -append "rd.live.overlay.overlayfs=1 rd.live.image $1 panic=1 oops=panic $DEBUGFAIL"
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_run() {
    declare -a disk_args=()
    declare -i disk_index=3
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker

    # squashfs scsi
    test_me "root=live:/dev/sda"

    # vfat ide
    test_me "root=LABEL=ISO"

    # isofs cdrom
    test_me "root=LABEL=live rd.live.dir=livedir rd.live.squashimg=rootfs.squashfs"

    rm -rf  /boot/vmlinuz*
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    # run-qemu does not support running without -kernel, todo to fix this
    "$testdir"/run-qemu "${disk_args[@]}" \
        -cdrom "$TESTDIR"/livedir/linux2.iso \
        -append "rd.live.overlay.overlayfs=1 rd.live.image root=/dev/sr0 panic=1 oops=panic $DEBUGFAIL"
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

# todo  -hda rootdisk.img
# todo - give index for vfat drive

    # -drive file="$TESTDIR"/livedir/rootfs.squashfs,format=raw,if=none,id=nvm -device nvme,serial=deadbeef,drive=nvm \
#    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
#    "$testdir"/run-qemu "${disk_args[@]}" -initrd "$TESTDIR"/initramfs.testing \
#        -drive file="$TESTDIR"/livedir/rootfs.squashfs,format=raw,if=none,id=usbstick -usb -device usb-ehci,id=ehci -device usb-storage,bus=ehci.0,drive=usbstick \
#        -append "rd.live.overlay.overlayfs=1 rd.live.image root=/dev/mmcblk0 panic=1 oops=panic $DEBUGFAIL"
#    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

}

test_setup() {
    # use dracut to bootstrap a rootfs directory that you can chroot into --quiet
    "$basedir"/dracut.sh --no-hostonly --tmpdir "$TESTDIR" --keep --modules "test-root" -i ./test-init.sh /sbin/init \
        "$TESTDIR"/tmp-initramfs.root "$KVERSION" || return 1

    mkdir -p "$TESTDIR"/dracut.*/initramfs/proc
    mkdir "$TESTDIR"/livedir
    cd "$TESTDIR"/livedir

    mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/livedir/rootfs.squashfs -quiet -no-progress
    xorriso -as mkisofs -output "$TESTDIR"/livedir/linux.iso "$TESTDIR"/dracut.*/initramfs/ -volid "ISO" -iso-level 3

mkdir /tmp/iso/
cp -a  /efi/* /tmp/iso

mkdir -p /tmp/iso/LiveOS
cp "$TESTDIR"/livedir/rootfs.squashfs /tmp/iso/LiveOS/squashfs.img
cd /tmp/iso

# Only include files once in the iso
mkdir /tmp/isotemp
mv isolinux/bios.img /tmp/isotemp/
mv isolinux/efiboot.img /tmp/isotemp/

find /tmp/iso
find /tmp/isotemp/

# sudo cp .dotfiles/boot/grub.cfg /tmp/iso/EFI/BOOT/

xorriso -as mkisofs -output "$TESTDIR"/livedir/linux2.iso "$TESTDIR"/dracut.*/initramfs/ -volid "ISO" -iso-level 3 \
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

    rm -rf -- "$TESTDIR"/dracut.* "$TESTDIR"/tmp-*
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
