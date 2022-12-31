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
# CONFIG_EMBEDDED is not set
# architecture independent
CONFIG_BINFMT_ELF=y
CONFIG_BINFMT_SCRIPT=y
CONFIG_NO_HZ=y
CONFIG_HIGH_RES_TIMERS=y
CONFIG_KVM=y
CONFIG_KVM_INTEL=y
CONFIG_KVM_AMD=y
CONFIG_BLK_DEV=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_RD_GZIP=y
CONFIG_BLK_DEV_LOOP=y
CONFIG_EXT4_FS=m
CONFIG_EXT4_USE_FOR_EXT2=y
CONFIG_VFAT_FS=y
CONFIG_FAT_DEFAULT_UTF8=y
CONFIG_MISC_FILESYSTEMS=y
CONFIG_SQUASHFS=y
CONFIG_SQUASHFS_XATTR=y
CONFIG_SQUASHFS_ZLIB=y
CONFIG_TMPFS=y
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_NET=y
CONFIG_PACKET=y
CONFIG_INET=y
CONFIG_IPV6=y
CONFIG_NETDEVICES=y
CONFIG_NET_CORE=y
CONFIG_NETCONSOLE=y
CONFIG_ETHERNET=y
CONFIG_COMPAT_32BIT_TIME=y
CONFIG_EARLY_PRINTK=y
CONFIG_IKCONFIG=y
CONFIG_IKCONFIG_PROC=y
CONFIG_MODULES=y

# architecture specific
CONFIG_64BIT=y
CONFIG_UNWINDER_FRAME_POINTER=y
CONFIG_PCI=y
CONFIG_ATA=y
CONFIG_ATA_SFF=y
CONFIG_ATA_BMDMA=y
CONFIG_ATA_PIIX=y
CONFIG_NET_VENDOR_INTEL=y
CONFIG_E1000=y
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_RTC_CLASS=y

# udev
CONFIG_SIGNALFD=y
CONFIG_BLK_DEV_BSG=y
CONFIG_UNIX=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_INOTIFY_USER=y
CONFIG_PROC_FS=y
CONFIG_SYSFS=y

# device mapper
CONFIG_BLK_DEV_DM=y

CONFIG_SCSI=y
CONFIG_BLK_DEV_SD=y
CONFIG_USB_STORAGE=y
CONFIG_USB_XHCI_HCD=y

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
