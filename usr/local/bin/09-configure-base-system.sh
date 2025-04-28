#!/usr/bin/env bash
set -euo pipefail

# Timezone & locale
echo "Europe/Berlin" > /etc/timezone
emerge --config sys-libs/timezone-data
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

# Hostname
echo "gentoo-book-air" > /etc/hostname

# Use UUIDs in /etc/fstab
ROOT_UUID=$(blkid -s UUID -o value /dev/sda3)
EFI_UUID=$(blkid -s UUID -o value /dev/sda1)
cat << EOF > /etc/fstab
UUID=$ROOT_UUID   /       ext4    defaults,noatime 0 1
/dev/sda2         none    swap    sw               0 0
UUID=$EFI_UUID    /boot/efi vfat  umask=0077      0 2
EOF

# Set root password
passwd