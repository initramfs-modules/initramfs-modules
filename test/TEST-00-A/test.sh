#!/bin/bash

TEST_DESCRIPTION="root on an image"

# test for different if= .. possible values= ide, scsi, sd, mtd, floppy, pflash, virtio

KVERSION="${KVERSION-$(uname -r)}"

if [ -z "$DEBUGFAIL" ]; then
    DRACUT_CMD="--quiet"
fi

test_run() {
    declare -a disk_args=()
    declare -i disk_index=3
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker

read -r -d '' VM_CONFIG << EOM
${disk_args[@]} -initrd /efi/kernel/initrd.img -drive file=$TESTDIR/livedir/rootfs.squashfs,format=raw,index=0 -drive file=fat:rw:$TESTDIR,format=vvfat,label=live -cdrom $TESTDIR/livedir/rootfs.iso
EOM

    # squashfs scsi
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "$VM_CONFIG" -append "rd.live.overlay.overlayfs=1 root=live:/dev/sda panic=1 oops=panic $DEBUGFAIL"
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

    # squashfs scsi
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -initrd /efi/kernel/initrd.img \
        -drive file="$TESTDIR"/livedir/rootfs.squashfs,format=raw,index=0 \
        -drive file=fat:rw:"$TESTDIR",format=vvfat,label=live \
        -cdrom "$TESTDIR"/livedir/rootfs.iso \
        -append "rd.live.overlay.overlayfs=1 root=live:/dev/sda panic=1 oops=panic $DEBUGFAIL"
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

    # vfat ide
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -initrd /efi/kernel/initrd.img \
        -drive file="$TESTDIR"/livedir/rootfs.squashfs,format=raw,index=0 \
        -drive file=fat:rw:"$TESTDIR",format=vvfat,label=live \
        -cdrom "$TESTDIR"/livedir/rootfs.iso \
        -append "rd.live.overlay.overlayfs=1 rd.live.image root=LABEL=ISO panic=1 oops=panic $DEBUGFAIL"
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

    # isofs cdrom
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -initrd /efi/kernel/initrd.img \
        -drive file="$TESTDIR"/livedir/rootfs.squashfs,format=raw,index=0 \
        -drive file=fat:rw:"$TESTDIR",format=vvfat,label=vfat \
        -cdrom "$TESTDIR"/livedir/rootfs.iso \
        -append "rd.live.overlay.overlayfs=1 rd.live.image rd.live.dir=livedir rd.live.squashimg=rootfs.squashfs root=LABEL=vfat panic=1 oops=panic $DEBUGFAIL"
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
    # use dracut to bootstrap a rootfs directory that you can chroot into
    "$basedir"/dracut.sh --quiet --no-hostonly --tmpdir "$TESTDIR" --keep --modules "test-root" -i ./test-init.sh /sbin/init \
        "$TESTDIR"/tmp-initramfs.root "$KVERSION" || return 1

    mkdir -p "$TESTDIR"/dracut.*/initramfs/proc
    mkdir "$TESTDIR"/livedir

    mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/livedir/rootfs.squashfs -quiet -no-progress
    xorriso -as mkisofs -output "$TESTDIR"/livedir/rootfs.iso "$TESTDIR"/dracut.*/initramfs/ -volid "ISO"

    rm -rf -- "$TESTDIR"/dracut.* "$TESTDIR"/tmp-*
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
