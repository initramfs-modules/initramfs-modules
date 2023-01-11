#!/bin/bash

# shellcheck disable=SC2034
TEST_DESCRIPTION="UEFI boot"

KVERSION="${KVERSION-$(uname -r)}"

test_run() {
    declare -a disk_args=()
    declare -i disk_index=3
    qemu_add_drive_args disk_index disk_args "$TESTDIR"/marker.img marker

    OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
    rm -rf  /boot/vmlinuz*

    # ISO UEFI HARDDISK (isohybrid) scsi-hd
    dd if=/dev/zero of="$TESTDIR"/marker.img bs=1MiB count=1
    "$testdir"/run-qemu "${disk_args[@]}" -net none \
       -drive file=fat:rw:"$TESTDIR"/ESP,format=vvfat,label=EFI \
       -global driver=cfi.pflash01,property=secure,value=on \
       -drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on
    grep -U --binary-files=binary -F -m 1 -q dracut-root-block-success -- "$TESTDIR"/marker.img || return 1
}

test_setup() {
    # Create what will eventually be our root filesystem
    mkdir -p "$TESTDIR"
    "$basedir"/dracut.sh --no-hostonly --no-early-microcode --nofscks --nomdadmconf \
        --tmpdir "$TESTDIR" --keep --modules "test-root" -i ./test-init.sh /sbin/init \
        "$TESTDIR"/tmp-initramfs.root "$KVERSION" || return 1

    mkdir -p "$TESTDIR"/dracut.*/initramfs/proc "$TESTDIR"/ESP/LiveOS "$TESTDIR"/ESP/EFI/BOOT
    mksquashfs "$TESTDIR"/dracut.*/initramfs/ "$TESTDIR"/ESP/LiveOS/squashfs.img -quiet -no-progress

    echo "root=live:/dev/disk/by-label/EFI rd.live.overlay.overlayfs=1 panic=1 oops=panic $DEBUGFAIL" > /tmp/cmdline

    dracut -l -i "$TESTDIR"/overlay / \
        --modules "dmsquash-live test watchdog" \
        --drivers "sd_mod" \
        --no-hostonly \
        --uefi \
        --uefi-stub /usr/lib/gummiboot/linuxx64.efi.stub \
        --kernel-cmdline "root=live:/dev/disk/by-label/EFI rd.live.overlay.overlayfs=1 panic=1 oops=panic $DEBUGFAIL" \
        "$KVERSION"

#         \
#        --force "$TESTDIR"/ESP/EFI/BOOT/BOOTX64.efi "$KVERSION" || return 1

ls -la "$TESTDIR"/ESP/EFI/BOOT/BOOTX64.efi

find "$TESTDIR"/ESP

#    cp /boot/vmlinuz* /tmp/vmlinuz

    # make unified kernel
#    objcopy --verbose  \
#        --add-section .osrel="/etc/os-release" --change-section-vma .osrel=0x20000 \
#        --add-section .cmdline="/tmp/cmdline" --change-section-vma .cmdline=0x30000 \
#        --add-section .linux="/tmp/vmlinuz" --change-section-vma .linux=0x40000 \
#        --add-section .initrd="$TESTDIR"/initramfs.testing --change-section-vma .initrd=0x3000000 \
#        /usr/lib/gummiboot/linuxx64.efi.stub "$TESTDIR"/ESP/EFI/BOOT/BOOTX64.efi

#    rm -rf -- "$TESTDIR"/overlay
}

test_cleanup() {
    return 0
}

# shellcheck disable=SC1090
. "$testdir"/test-functions
