set -x

export KERNEL='5.15.76'

export DEBIAN_FRONTEND=noninteractive

apt-get update -y -qq -o Dpkg::Use-Pty=0

apt-get install -y -qq --no-install-recommends -o Dpkg::Use-Pty=0 autoconf build-essential libssl-dev gawk openssl libssl-dev libelf-dev libudev-dev libpci-dev flex bison cpio zstd wget bc kmod git squashf

cd /tmp/

rm -rf linux-*
wget --no-check-certificate https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL.tar.xz
tar -xf linux-$KERNEL.tar.xz

cd linux-$KERNEL

cat > x86_64.miniconf << EOF
# make ARCH=x86 allnoconfig KCONFIG_ALLCONFIG=x86_64.miniconf
# make ARCH=x86 -j $(nproc)
# boot arch/x86/boot/bzImage


# CONFIG_EMBEDDED is not set
# architecture independent
CONFIG_BINFMT_ELF=y
CONFIG_BINFMT_SCRIPT=y
CONFIG_NO_HZ=y
CONFIG_HIGH_RES_TIMERS=y
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
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_TMPFS=y
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_NET=y
CONFIG_PACKET=y
CONFIG_UNIX=y
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
CONFIG_BLK_DEV_SD=y
CONFIG_ATA=y
CONFIG_ATA_SFF=y
CONFIG_ATA_BMDMA=y
CONFIG_ATA_PIIX=y
CONFIG_NET_VENDOR_INTEL=y
CONFIG_E1000=y
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_RTC_CLASS=y

EOF


make ARCH=x86 allnoconfig KCONFIG_ALLCONFIG=x86_64.miniconf

cat .config
make -j$(nproc) bzImage
ls -lha arch/x86/boot/bzImage
make install

find /boot

make -j$(nproc) modules
make INSTALL_MOD_STRIP=1 modules_install

find /lib/

make headers_install

make clean

exit


make tinyconfig

cat .config

make -j16 bzImage
mkdir -p /efi/kernel
cp -r arch/x86/boot/bzImage /efi/kernel/vmlinuz

file /efi/kernel/vmlinuz

make -j16 modules
make INSTALL_MOD_STRIP=1 modules_install
make headers_install

make clean
