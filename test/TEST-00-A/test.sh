#!/bin/bash

TEST_DESCRIPTION="root on a squash image"

KVERSION="${KVERSION-$(uname -r)}"

if [ -z "$DEBUGFAIL" ]; then
    DRACUT_CMD="--quiet"
fi

test_run() {
    declare -a disk_args=()
    declare -i disk_index=1
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker

    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -initrd "$TESTDIR"/initramfs.testing \
        -drive file="$TESTDIR"/livedir/rootfs.squashfs,format=raw \
        -append "rd.live.overlay.overlayfs=1 root=live:/dev/sda panic=1 oops=panic $DEBUGFAIL"
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

    # -drive file="$TESTDIR"/livedir/rootfs.squashfs,format=raw,if=none,id=nvm -device nvme,serial=deadbeef,drive=nvm \
#    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
#    "$testdir"/run-qemu "${disk_args[@]}" -initrd "$TESTDIR"/initramfs.testing \
#        -drive file="$TESTDIR"/livedir/rootfs.squashfs,format=raw,if=none,id=usbstick -usb -device usb-ehci,id=ehci -device usb-storage,bus=ehci.0,drive=usbstick \
#        -append "rd.live.overlay.overlayfs=1 rd.live.image root=/dev/mmcblk0 panic=1 oops=panic $DEBUGFAIL"
#    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -initrd "$TESTDIR"/initramfs.testing \
        -device ide-hd,drive=bootdrive -drive file=fat:rw:"$TESTDIR",format=vvfat,if=none,id=bootdrive,label=live \
        -append "rd.live.overlay.overlayfs=1 rd.live.image rd.live.dir=livedir root=LABEL=live panic=1 oops=panic $DEBUGFAIL"
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1

    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -initrd "$TESTDIR"/initramfs.testing \
        -cdrom "$TESTDIR"/livedir/rootfs.iso \
        -append "rd.live.overlay.overlayfs=1 rd.live.image root=/dev/sr0 panic=1 oops=panic $DEBUGFAIL"
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1


    # -device sdhci-pci -device sd-card,drive=mydrive -drive id=mydrive,if=none,format=raw,file=image.bin
    #    -drive if=none,id=usbstick,format=raw,file=/path/to/image   \
    #    -usb                                                        \
    #    -device usb-ehci,id=ehci                                    \
    #    -device usb-tablet,bus=usb-bus.0                            \
    #    -device usb-storage,bus=ehci.0,drive=usbstick
}

test_setup() {
    # use dracut to bootstrap a rootfs directory that you can chroot into
    "$basedir"/dracut.sh --quiet --no-hostonly --tmpdir "$TESTDIR" --keep --modules "test-root" -i ./test-init.sh /sbin/init \
        "$TESTDIR"/tmp-initramfs.root "$KVERSION" || return 1

    mkdir -p "$TESTDIR"/dracut.*/initramfs/proc && mkdir "$TESTDIR"/livedir

    mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/livedir/rootfs.squashfs -quiet -no-progress
    mkisofs -o "$TESTDIR"/livedir/rootfs.iso "$TESTDIR"/dracut.*/initramfs/

    rm -rf -- "$TESTDIR"/dracut.* "$TESTDIR"/tmp-*

    # make initramfs.testing
    "$basedir"/dracut.sh $DRACUT_CMD --no-hostonly --tmpdir "$TESTDIR" --keep --modules "dmsquash-live dash" --add-drivers "sd_mod ahci unix vfat nls_cp437 nls_iso8859-1 8250 isofs sr_mod cdrom nvme autofs4 overlay" \
        "$TESTDIR"/tmp-initramfs.testing "$KVERSION" || return 1

   cd "$TESTDIR"/dracut.*/initramfs/

   # clean some dracut logs
   rm -rf lib/dracut/*.txt

   # better solution would be dm dracut module is not included instead of this hack
   rm -rf lib/dracut/hooks/pre-udev/30-dm-pre-udev.sh
   rm -rf lib/dracut/hooks/shutdown/25-dm-shutdown.sh
   rm -rf lib/dracut/hooks/initqueue/timeout/99-rootfallback.sh
   rm -rf lib/udev/rules.d/75-net-description.rules
   rm -rf etc/udev/rules.d/11-dm.rules

   rm -rf sbin/*fsck*

   # Populate logs with the list of filenames inside initrd.img
   #find . -type f -exec ls -la {} \; | sort -k 5,5  -n -r
   #find .

   find . -print0 | cpio --null --create --format=newc | gzip --best > "$TESTDIR"/initramfs.testing
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
