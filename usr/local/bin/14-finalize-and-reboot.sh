#!/usr/bin/env bash
set -euo pipefail

exit
cd /
umount -R /mnt/gentoo
swapoff -a
reboot