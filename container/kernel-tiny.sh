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

# make tinyconfig

cat > x86_64.miniconf << EOF
# architecture independent
CONFIG_BINFMT_ELF=y
CONFIG_BINFMT_SCRIPT=y
CONFIG_NO_HZ=y
CONFIG_HIGH_RES_TIMERS=y
CONFIG_BLK_DEV=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_RD_GZIP=y
CONFIG_MISC_FILESYSTEMS=y
CONFIG_TMPFS=y
#CONFIG_TMPFS_POSIX_ACL=y
CONFIG_COMPAT_32BIT_TIME=y

# architecture specific
CONFIG_64BIT=y
CONFIG_UNWINDER_FRAME_POINTER=y
CONFIG_PCI=y
CONFIG_RTC_CLASS=y

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

CONFIG_MODULES=y

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
CONFIG_SERIAL_8250=m
CONFIG_SERIAL_8250_CONSOLE=y

# device mapper
CONFIG_BLK_DEV_DM=m

# configs
CONFIG_IKCONFIG=m
CONFIG_IKCONFIG_PROC=y

# convinience
#CONFIG_EARLY_PRINTK=y

# fat
CONFIG_MSDOS_PARTITION=y
CONFIG_FAT_FS=m
CONFIG_MSDOS_FS=m
CONFIG_VFAT_FS=m
CONFIG_FAT_DEFAULT_CODEPAGE=437
CONFIG_FAT_DEFAULT_IOCHARSET="iso8859-1"
CONFIG_NCPFS_SMALLDOS=y
CONFIG_NLS_CODEPAGE_437=m
CONFIG_NLS_ISO8859_1=m

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
