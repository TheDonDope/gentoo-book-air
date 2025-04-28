#!/usr/bin/env bash
set -euo pipefail

KERNEL_DIR=/usr/src/linux
NEW_SRC=/usr/src/linux-$(date +%Y%m%d)

# 1. Prepare new kernel sources
echo "[1/4] Installing kernel sources..."
emerge --ask sys-kernel/gentoo-sources

# 2. Copy defconfig from current kernel
echo "[2/4] Copying config..."
cp $KERNEL_DIR/.config $NEW_SRC/.config

# 3. Build new kernel
echo "[3/4] Building kernel..."
cd $NEW_SRC
make olddefconfig
make -j$(nproc)
make modules_install

# 4. Install kernel and update GRUB
echo "[4/4] Installing kernel and updating GRUB..."
KVER=$(make kernelversion)
cp arch/x86/boot/bzImage /boot/kernel-$${KVER}
ln -sf /boot/kernel-$${KVER} /boot/vmlinuz

grub-mkconfig -o /boot/grub/grub.cfg

echo "Kernel upgrade to $${KVER} complete. Please reboot."