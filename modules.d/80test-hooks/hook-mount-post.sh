#!/bin/sh

# Expected to run after all dracut module mount hooks

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

mount -v

#if ! ismounted "/sysroot"; then
  die "exit"
#fi
