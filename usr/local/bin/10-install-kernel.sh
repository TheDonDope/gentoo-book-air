#!/usr/bin/env bash
set -euo pipefail

# Install kernel sources and genkernel
emerge --ask sys-kernel/gentoo-sources sys-kernel/genkernel

# Set kernel symlink
eselect kernel list
# Replace "1" with your kernel index
eselect kernel set 1
# Verify symlink
ls -l /usr/src/linux

# Configure and compile kernel
genkernel --menuconfig all