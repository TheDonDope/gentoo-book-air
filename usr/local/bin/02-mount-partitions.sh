#!/usr/bin/env bash
set -euo pipefail

mount /dev/sda3 /mnt/gentoo
mkdir -p /mnt/gentoo/boot/efi
mount /dev/sda1 /mnt/gentoo/boot/efi
swapon /dev/sda2