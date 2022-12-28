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
        -device ide-hd,drive=usbstick -drive file=fat:rw:"$TESTDIR",format=vvfat,if=none,id=usbstick,label=live \
        -append "rd.live.image rd.live.dir=livedir root=LABEL=live rd.retry=2 console=ttyS0,115200n81 selinux=0 rd.info panic=1 oops=panic softlockup_panic=1 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing

    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_setup() {
    # booting into this directory
    "$basedir"/dracut.sh -l --keep --tmpdir "$TESTDIR" \
        -m "test-root" \
        -i ./test-init.sh /sbin/init \
        -i "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh" \
        -i "${basedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh" \
        --no-hostonly \
        -f "$TESTDIR"/initramfs.root "$KVERSION" || return 1

    mkdir "$TESTDIR"/livedir
    mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/livedir/rootfs.img
    rm -rf -- "$TESTDIR"/dracut.*

    "$basedir"/dracut.sh -l -i "$TESTDIR"/overlay / \
        --modules "test qemu dmsquash-live busybox" \
        --drivers "sd_mod vfat nls_cp437 nls_ascii " \
        --no-hostonly \
        --force "$TESTDIR"/initramfs.testing "$KVERSION" || return 1

    rm -rf -- "$TESTDIR"/overlay
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
