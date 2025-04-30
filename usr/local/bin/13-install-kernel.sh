#!/usr/bin/env bash
set -euo pipefail

# Install Gentoo distribution kernel
emerge --ask sys-kernel/gentoo-kernel

# Clean up
emerge --depclean

# Set `dist-kernel` USE-flag
nano /etc/portage/make.conf

# Add `USE="dist-kernel"` line

# Manually rebuild the initramfs
emerge --ask @module-rebuild
emerge --config sys-kernel/gentoo-kernel