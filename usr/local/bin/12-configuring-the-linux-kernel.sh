#!/usr/bin/env bash
set -euo pipefail

# Install linux-firmware
emerge --ask sys-kernel/linux-firmware

# Configure systemd-boot
cat << EOF > /etc/portage/package.use/systemd
sys-apps/systemd boot
sys-kernel/installkernel systemd-boot
EOF

# Configure Initramfs with dracut
cat << EOF > /etc/portage/package.use/installkernel
sys-kernel/installkernel dracut
EOF

# Configure kernel command line
cat << EOF > /etc/kernel/cmdline
quiet splash
EOF

# Install systemd and installkernel
emerge --ask sys-apps/systemd sys-kernel/installkernel