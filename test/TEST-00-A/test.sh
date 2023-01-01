#!/bin/bash

TEST_DESCRIPTION="root on a squash image"

KVERSION="${KVERSION-$(uname -r)}"

# Uncomment these to debug failures
#DEBUGFAIL="rd.debug rd.live.debug loglevel=7"

test_run() {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker

#-device ide-hd,drive=bootdrive -drive file=fat:rw:"$TESTDIR",format=vvfat,if=none,id=bootdrive,label=live \
# -append "rd.live.image rd.live.dir=livedir root=/dev/sdb1 rd.retry=2 rd.info console=ttyS0,115200n81 selinux=0 panic=1 oops=panic softlockup_panic=1 $DEBUGFAIL" \

# -drive file="$TESTDIR"/livedir/rootfs.img,index=0,media=disk,format=raw \

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -boot order=d \
        -device ide-hd,drive=bootdrive -drive file="$TESTDIR"/livedir/rootfs.img,index=1,media=disk,format=raw,id=bootdrive,if=none \
        -append "rd.live.image rd.live.overlay.overlayfs=1 root=/dev/sdb rd.retry=2 rd.info console=ttyS0,115200n81 selinux=0 panic=1 oops=panic softlockup_panic=1 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing

    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_setup() {
    # use dracut to bootstrap a rootfs directory that you can chroot into
    "$basedir"/dracut.sh --no-hostonly --tmpdir "$TESTDIR" --keep --modules "test-root" -i ./test-init.sh /sbin/init \
        "$TESTDIR"/tmp-initramfs.root "$KVERSION" || return 1

    # make rootfs.img
    mkdir -p "$TESTDIR"/dracut.*/initramfs/dev
    ls -lRa "$TESTDIR"/dracut.*/initramfs/
    mkdir "$TESTDIR"/livedir && mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/livedir/rootfs.img && rm -rf -- "$TESTDIR"/dracut.* "$TESTDIR"/tmp-*

    # make initramfs.testing qemu dmsquash-live
    "$basedir"/dracut.sh --no-hostonly --tmpdir "$TESTDIR" --keep --modules "dmsquash-live dash" --drivers "sd_mod vfat nls_cp437 nls_ascii nls_utf8" \
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
   find . -type f -exec ls -la {} \; | sort -k 5,5  -n -r
   find .

   find . -print0 | cpio --null --create --format=newc | gzip --best > "$TESTDIR"/initramfs.testing
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
