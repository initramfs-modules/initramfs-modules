#!/bin/bash

set -ex

#gh workflow run test.yml -f container=debian -f test='[ "00" ]'

cp /usr/bin/dracut /usr/lib/dracut/dracut.sh

RUN_ID="$1"
TESTS=$2

#find /usr/lib/dracut/

# shellcheck disable=SC2012
#time basedir="/usr/lib/dracut/" LOGTEE_TIMEOUT_MS=590000 make \
time  LOGTEE_TIMEOUT_MS=590000 make \
  enable_documentation=no \
  KVERSION="$(
    cd /lib/modules
    ls -1 | tail -1
  )" \
  QEMU_CPU="IvyBridge-v2" \
  DRACUT_NO_XATTR=1 \
  TEST_RUN_ID="$RUN_ID" \
  ${TESTS:+TESTS="$TESTS"} \
  -k V=1 \
  check

