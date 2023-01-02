set -x

export KERNEL='5.15.76'

export DEBIAN_FRONTEND=noninteractive

apt-get update -y -qq -o Dpkg::Use-Pty=0

apt-get install -y -qq --no-install-recommends -o Dpkg::Use-Pty=0 autoconf build-essential libssl-dev gawk openssl libssl-dev libelf-dev libudev-dev libpci-dev flex bison cpio zstd wget bc kmod git squashfs-tools cpio dracut-core ca-certificates apt-utils ca-certificates git fakeroot gzip dracut-core wget linux-base sudo libelf1 python3 dkms build-essential rsync
cd /tmp/

rm -rf linux-*
wget --no-check-certificate https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL.tar.xz
tar -xf linux-$KERNEL.tar.xz

cd linux-$KERNEL

# minimal config to use udev and dracut
# prefer modules over builtin
cat > x86_64.miniconf << EOF
CONFIG_BINFMT_ELF=y
CONFIG_BINFMT_SCRIPT=y
CONFIG_NO_HZ=y
CONFIG_HIGH_RES_TIMERS=y
CONFIG_BLK_DEV=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_RD_GZIP=y
CONFIG_MISC_FILESYSTEMS=y
CONFIG_TMPFS=y
CONFIG_COMPAT_32BIT_TIME=y
CONFIG_PCI=y
CONFIG_RTC_CLASS=y

# x86 specific
CONFIG_64BIT=y

# udev
CONFIG_SIGNALFD=y
CONFIG_BLK_DEV_BSG=y
CONFIG_NET=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_INOTIFY_USER=y
CONFIG_PROC_FS=y
CONFIG_SYSFS=y

# reboot
CONFIG_ACPI=y

# microcode
CONFIG_MICROCODE=y
CONFIG_MICROCODE_AMD=y
CONFIG_MICROCODE_INTEL=y

# module
CONFIG_MODULES=y

# --------------

# unix - for udev
CONFIG_UNIX=m

# ahci, libahci
CONFIG_SATA_AHCI=m

# libata
CONFIG_ATA=m
CONFIG_ATA_SFF=m

# scsi_mod
CONFIG_SCSI=m

# sd_mod
CONFIG_BLK_DEV_SD=m

# loop
CONFIG_BLK_DEV_LOOP=m

# squashfs
CONFIG_SQUASHFS=m
CONFIG_SQUASHFS_ZLIB=y

# overlay
CONFIG_OVERLAY_FS=m

# ext4
CONFIG_EXT4_FS=m
CONFIG_EXT4_USE_FOR_EXT2=y

# 8250
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y

# nls_cp437
CONFIG_NLS_CODEPAGE_437=m

# nls_iso8859-1
CONFIG_NLS_ISO8859_1=m

# fat
CONFIG_FAT_FS=m
CONFIG_MSDOS_PARTITION=y
CONFIG_FAT_DEFAULT_CODEPAGE=437
CONFIG_FAT_DEFAULT_IOCHARSET="iso8859-1"
CONFIG_NCPFS_SMALLDOS=y

# msdos
CONFIG_MSDOS_FS=m

# vfat
CONFIG_VFAT_FS=m

# cdrom
CONFIG_BLK_DEV_SR=m

# autofs4
CONFIG_AUTOFS4_FS=m

# isofs
CONFIG_ISO9660_FS=m

# ntfs3
CONFIG_NTFS3_FS=m

# exfat
CONFIG_EXFAT_FS=m
CONFIG_EXFAT_DEFAULT_IOCHARSET="iso8859-1"

# nvme_core
CONFIG_NVME_CORE=m

# nvme
CONFIG_BLK_DEV_NVME=m

# mmc_core
CONFIG_MMC=m

# mmc_block
CONFIG_MMC_BLOCK=m

# virtio_blk
CONFIG_VIRTIO_BLK=m

# uas
CONFIG_USB_UAS=m

# fuse
CONFIG_FUSE_FS=m

# btrfs
CONFIG_BTRFS_FS=m

# device mapper
CONFIG_BLK_DEV_DM=m

EOF

make ARCH=x86 allnoconfig KCONFIG_ALLCONFIG=x86_64.miniconf

cat .config
make -j$(nproc) bzImage
make -j$(nproc) modules

#make clean
rm -rf /boot/* /lib/modules/*

make install
make INSTALL_MOD_STRIP=1 modules_install

#make headers_install
#apt-mark hold  linux-headers*
#apt-get purge -y -o Dpkg::Use-Pty=0 autoconf build-essential libssl-dev gawk openssl libssl-dev libelf-dev libudev-dev libpci-dev flex bison cpio zstd wget bc kmod git squashfs-tools cpio dracut-core ca-certificates apt-utils ca-certificates git fakeroot wget libelf1 python3 dkms build-essential rsync
#apt-get autoremove -y -o Dpkg::Use-Pty=0
#apt-get clean

find /boot/ /lib/modules/
# /usr/include/
