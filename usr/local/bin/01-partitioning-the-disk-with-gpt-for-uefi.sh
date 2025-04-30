#!/usr/bin/env bash
set -euo pipefail

# Identify target drive (e.g., /dev/sda), confirm with `lsblk`
DRIVE=/dev/sda

# Format disk and create partitions
fdisk ${DRIVE}

# Press `p` to print the current partition table

# Creating the EFI System Partition (ESP)

# Press `g` to create a new empty GPT partition table
# Press `n` to create a new partition
# Press `1` for the first partition
# Press `Enter` to accept the default first sector
# Press `+1G` for the size of the EFI partition
# Press `Y` to confirm removing the existing partition
# Press `t` to mark the partition as an EFI system partition
# Press `1` to select the EFI partition type

# Creating the swap partition

# Press `n` to create a new partition
# Press `2` for the second partition
# Press `Enter` to accept the default first sector
# Press `+4G` for the size of the swap partition (Size of your RAM)
# Press `t` to change the partition type
# Press `2` to select the swap partition
# Press `19` to set the partition type to Linux swap partition

# Creating the root partition
# Press `n` to create a new partition
# Press `3` for the third partition
# Press `Enter` to accept the default first sector
# Press `Enter` to accept the default last sector (use the rest of the disk)
# Press `t` to change the partition type
# Press `3` to select the root partition
# Press `23` to set the partition type to Linux filesystem (Linux Root (x86-64)

# Press `p` to print the partition table again to verify
# Press `w` to write the changes and exit fdisk

# Format partitions
mkfs.vfat -F 32 ${DRIVE}1
mkswap ${DRIVE}2
mkfs.ext4 ${DRIVE}3

# Activate swap
swapon ${DRIVE}2