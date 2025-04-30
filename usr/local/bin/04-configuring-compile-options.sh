#!/usr/bin/env bash
set -euo pipefail

cat << EOF >> /mnt/gentoo/etc/portage/make.conf
COMMON_FLAGS="-march=haswell -O2 -pipe"
MAKEOPTS="-j3"
ACCEPT_LICENSE="*"
EOF