#!/bin/sh

# Expected to run after all dracut module mount hooks

# Only expected to be called if /sysroot is not yet mounted

for root in $(getargs rootfallback=); do
    root=$(label_uuid_to_dev "$root")

    if mount "$root" /sysroot; then
        exit 0
    fi
done

exit 1
