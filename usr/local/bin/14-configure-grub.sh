#!/usr/bin/env bash
set -euo pipefail

emerge --ask sys-boot/grub:2

# Get root partition UUID
ROOT_UUID=$(blkid -s UUID -o value /dev/sda3)

# Configure GRUB
cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Gentoo"
GRUB_CMDLINE_LINUX="root=UUID=$ROOT_UUID initrd=/boot/initramfs-$(uname -r)"
GRUB_DISABLE_RECOVERY=true
EOF

# Install GRUB to EFI
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo
grub-mkconfig -o /boot/grub/grub.cfg