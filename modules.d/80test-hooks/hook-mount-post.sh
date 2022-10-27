# Expected to run after all dracut module mount hooks

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if ismounted "/sysroot"; then
  die "exit"
fi
