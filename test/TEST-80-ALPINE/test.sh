#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="live root on a squash filesystem"

KVERSION="${KVERSION-$(uname -r)}"

# Uncomment this to debug failures
#DEBUGFAIL="rd.debug loglevel=7 rd.break=cmdline"

test_run() {
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.img root

    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -boot order=d \
        -append "root=/dev/sdb rootfstype=ext4 console=ttyS0,115200n81 selinux=0 rd.info panic=1 oops=panic softlockup_panic=1 rd.debug rd.shell=0 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing

    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_setup() {
    mkdir -p -- "$TESTDIR"/overlay/source "$TESTDIR"/overlay/tmp
    # Create what will eventually be our root filesystem onto an overlay

    dracut -l --keep --tmpdir "$TESTDIR"/overlay/tmp \
        --modules "mdev-alpine test-root" \
        --no-hostonly --no-hostonly-cmdline --no-early-microcode --nofscks --nomdadmconf --nohardlink --nostrip \
        --include ./test-init.sh /sbin/init \
        --include "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh" \
        --include "${basedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh" \
        --force "$TESTDIR"/initramfs.root "$KVERSION" || return 1

    mv "$TESTDIR"/overlay/tmp/dracut.*/initramfs/* "$TESTDIR"/overlay/source/ && rm -rf "$TESTDIR"/overlay/tmp

    # second, install the files needed to make the root filesystem
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    dracut -l -i "$TESTDIR"/overlay / \
        --modules "mdev-alpine rootfs-block test-makeroot" \
        --install "mkfs.ext4" \
        --drivers "ext4 sd_mod" \
        --no-hostonly --no-hostonly-cmdline --no-early-microcode --nofscks --nomdadmconf --nohardlink --nostrip \
        --include ./create-root.sh /lib/dracut/hooks/initqueue/01-create-root.sh \
        --force "$TESTDIR"/initramfs.makeroot "$KVERSION" || return 1
    rm -rf -- "$TESTDIR"/overlay

    # Create the blank file to use as a root filesystem
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    dd if=/dev/zero of="$TESTDIR"/root.img bs=1MiB count=160
    declare -a disk_args=()
    # shellcheck disable=SC2034
    declare -i disk_index=0
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/root.img root

    # Invoke KVM and/or QEMU to actually create the target filesystem.
    "$testdir"/run-qemu \
        "${disk_args[@]}" \
        -append "root=/dev/sdb rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0 rd.debug" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1

    if ! grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img; then
        echo "Could not create root filesystem"
        return 1
    fi

    dracut -l -i "$TESTDIR"/overlay / \
        --modules "busybox mdev-alpine rootfs-block test debug watchdog" \
        --omit "rngd" \
        --drivers "ext4 sd_mod" \
        --install "mkfs.ext4" \
        --no-hostonly --no-hostonly-cmdline \
        --force "$TESTDIR"/initramfs.testing "$KVERSION" || return 1

    ls -sh "$TESTDIR"/initramfs.testing
    rm -rf -- "$TESTDIR"/overlay
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
