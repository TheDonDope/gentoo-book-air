#!/usr/bin/env bash
set -euo pipefail

cat << EOF >> /mnt/gentoo/etc/portage/make.conf
CFLAGS="-O2 -march=haswell -pipe"
MAKEOPTS="-j3"
ACCEPT_LICENSE="*"
EOF