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
        -append "root=/dev/sdb console=ttyS0,115200n81 selinux=0 rd.info panic=1 oops=panic softlockup_panic=1 $DEBUGFAIL" \
        -initrd "$TESTDIR"/initramfs.testing

    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_setup() {
    mkdir -p -- "$TESTDIR"/overlay/source
    # Create what will eventually be our root filesystem onto an overlay
    (
        # shellcheck disable=SC2030
        # shellcheck disable=SC2031
        export initdir="$TESTDIR"/overlay/source
        # shellcheck disable=SC1090
        . "$basedir"/dracut-init.sh
        (
            cd "$initdir" || exit
            mkdir -p -- dev sys proc etc var/run tmp
            mkdir -p root usr/bin usr/lib usr/lib64 usr/sbin
        )
        inst_simple /etc/os-release
        [[ -f /etc/machine-id ]] && read -r MACHINE_ID < /etc/machine-id

        inst ./test-init.sh /sbin/init
        inst_simple "${basedir}/modules.d/99base/dracut-lib.sh" "/lib/dracut-lib.sh"
        inst_simple "${basedir}/modules.d/99base/dracut-dev-lib.sh" "/lib/dracut-dev-lib.sh"
        inst_binary "${basedir}/dracut-util" "/usr/bin/dracut-util"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getarg"
        ln -s dracut-util "${initdir}/usr/bin/dracut-getargs"

    inst_multiple mdev nlplug-findfs cut blkid

    inst /etc/passwd
    inst /etc/group
    inst /etc/mdev.conf

    inst_dir /etc/modprobe.d
    inst_multiple "/etc/modprobe.d/*"

    inst_dir /lib/mdev
    inst_multiple "/lib/mdev/*"

        inst_multiple mkdir ln dd stty mount poweroff modprobe sed

        cp -a -- /etc/ld.so.conf* "$initdir"/etc
        ldconfig -r "$initdir"
    )

    # second, install the files needed to make the root filesystem
    # create an initramfs that will create the target root filesystem.
    # We do it this way so that we do not risk trashing the host mdraid
    # devices, volume groups, encrypted partitions, etc.
    dracut -l -i "$TESTDIR"/overlay / \
        --modules "dash mdev-alpine rootfs-block test-makeroot" \
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
        -append "root=/dev/sdb rw rootfstype=ext4 quiet console=ttyS0,115200n81 selinux=0" \
        -initrd "$TESTDIR"/initramfs.makeroot || return 1

    if ! grep -U --binary-files=binary -F -m 1 -q dracut-root-block-created "$TESTDIR"/marker.img; then
        echo "Could not create root filesystem"
        return 1
    fi

    dracut -l -i "$TESTDIR"/overlay / \
        --modules "dash mdev-alpine rootfs-block test" \
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
