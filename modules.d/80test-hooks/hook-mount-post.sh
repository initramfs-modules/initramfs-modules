# Expected to run after all dracut module mount hooks

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

die "gombi"

if ismounted "/sysroot"; then
  die "exit"
fi

# Make sure that /dev/root already exists and mounted
[ -h /dev/root ] || die "exit"

#echo "dracut-root-block-success" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
