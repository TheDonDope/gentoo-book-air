#!/usr/bin/env bash
set -euo pipefail

mkdir --parents /mnt/usb
# Replace `sdb1` with your USB device
mount /dev/sdb1 /mnt/usb

# Extract stage3 archive
tar xpvf /mnt/usb/stage3/stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# tar options:
# `x`` extract, instructs tar to extract the contents of the archive.
# `p`` preserve permissions.
# `v`` verbose output.
# `f`` file, provides tar with the name of the input archive.
# `--xattrs-include='*.*'`` Preserves extended attributes in all namespaces stored in the archive.
# `--numeric-owner`` Ensure that the user and group IDs of files being extracted from the tarball remain the same as Gentoo's release engineering team intended (even if adventurous users are not using official Gentoo live environments for the installation process).
# `-C /mnt/gentoo`` Extract files to the root partition regardless of the current directory.