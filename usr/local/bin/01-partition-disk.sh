#!/usr/bin/env bash
set -euo pipefail

# Identify target drive (e.g., /dev/sda), confirm with `lsblk`
DRIVE=/dev/sda

# Create GPT and partitions
parted $DRIVE -- mklabel gpt
parted $DRIVE -- mkpart ESP fat32 1MiB 513MiB
parted $DRIVE -- set 1 boot on
parted $DRIVE -- mkpart primary linux-swap 513MiB 4609MiB
parted $DRIVE -- mkpart primary ext4 4609MiB 100%

# Format partitions
mkfs.vfat -F 32 ${DRIVE}1
mkswap ${DRIVE}2
mkfs.ext4 ${DRIVE}3