#!/bin/bash

set -ex

cd test

RUN_ID="$1"
TESTS=$2

# shellcheck disable=SC2012
time basedir="/usr/lib/dracut/" LOGTEE_TIMEOUT_MS=590000 make \
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

