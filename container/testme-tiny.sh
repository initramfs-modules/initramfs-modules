# builds for abpout 2:30 hours on GA

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
