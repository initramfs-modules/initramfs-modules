#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="live root on a squash filesystem"

KVERSION="${KVERSION-$(uname -r)}"

# Uncomment these to debug failures
#DEBUGFAIL="rd.debug rd.live.debug loglevel=7"

test_run() {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -boot order=d \
        -device ide-hd,drive=bootdrive -drive file=fat:rw:"$TESTDIR",format=vvfat,if=none,id=bootdrive,label=live \
        -append "rd.live.image rd.live.dir=livedir root=LABEL=live rd.retry=2 rd.info console=ttyS0,115200n81 selinux=0 panic=1 oops=panic softlockup_panic=1 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing

    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_setup() {
    # use dracut to bootstrap a rootfs directory that you can chroot into
    "$basedir"/dracut.sh --keep --no-hostonly --tmpdir "$TESTDIR" --modules "test-root" -i ./test-init.sh /sbin/init \
        "$TESTDIR"/initramfs.root "$KVERSION" || return 1

    # make rootfs.img
    mkdir "$TESTDIR"/livedir && mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/livedir/rootfs.img && rm -rf -- "$TESTDIR"/dracut.*

    # make initramfs.testing
    "$basedir"/dracut.sh --no-hostonly --modules "test qemu dmsquash-live dash" --drivers "sd_mod vfat nls_cp437 nls_ascii nls_utf8" \
        "$TESTDIR"/initramfs.testing "$KVERSION" || return 1
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
