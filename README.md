# Gentoo Linux Installation Guide (Systemd) for Mid‑2013 MacBook Air

This `README.md` serves both as a step-by-step installation guide **and** your Git history log. After each major phase, you’ll commit your changes with a short summary and a detailed long message listing the exact commands you ran.

> **Assumptions:**
> - You have a Gentoo stage3 archive at `/stage3/stage3-*.tar.xz` on your live USB.
> - You have the UGREEN USB network adapter driver sources under `/drivers/usbnet`.
> - You’ve backed up all data and are ready for a full disk wipe.

---

## 1. Initialize Git Repository

```bash
cd /
# Create .gitignore before first commit
cat << 'EOF' > .gitignore
# Virtual/pseudo filesystems
/proc
/sys
/dev
/run

# Transient storage
/tmp
/var/tmp
/mnt

# Logs, caches, repos
/var/log
/var/cache
/var/db/repos
/usr/portage

# Optional swapfile
/swapfile
EOF

# Initialize Git
git init

# First commit: empty root with .gitignore
git add .gitignore
git commit -m "Initialize repository and .gitignore"
```

---

## 2. Partition & Format Disk

```bash
# Identify target drive (e.g., /dev/sda)
DRIVE=/dev/sda

# Create GPT and partitions
parted $DRIVE -- mklabel gpt
parted $DRIVE -- mkpart ESP fat32 1MiB 513MiB
parted $DRIVE -- set 1 boot on
parted $DRIVE -- mkpart primary linux-swap 513MiB 4609MiB
parted $DRIVE -- mkpart primary ext4 4609MiB 100%

# Format partitions
mkfs.vfat -F32 ${DRIVE}1
mkswap ${DRIVE}2
mkfs.ext4 ${DRIVE}3
```

```bash
git add -A
git commit \
  -m "Partition and format SSD" \
  -m $'Commands run:\n  parted /dev/sda -- mklabel gpt\n  parted /dev/sda -- mkpart ESP fat32 1MiB 513MiB\n  parted /dev/sda -- set 1 boot on\n  parted /dev/sda -- mkpart primary linux-swap 513MiB 4609MiB\n  parted /dev/sda -- mkpart primary ext4 4609MiB 100%\n  mkfs.vfat -F32 /dev/sda1\n  mkswap /dev/sda2\n  mkfs.ext4 /dev/sda3'
```

---

## 3. Mount & Extract Stage3

```bash
mount /dev/sda3 /mnt/gentoo
mkdir -p /mnt/gentoo/boot/efi
mount /dev/sda1 /mnt/gentoo/boot/efi
swapon /dev/sda2

# Extract stage3 archive
cd /mnt/gentoo
tar xpvf /stage3/stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
```

```bash
git add -A
git commit \
  -m "Extract stage3 to /mnt/gentoo and mount filesystems" \
  -m $'Commands run:\n  mount /dev/sda3 /mnt/gentoo\n  mkdir -p /mnt/gentoo/boot/efi\n  mount /dev/sda1 /mnt/gentoo/boot/efi\n  swapon /dev/sda2\n  tar xpvf /stage3/stage3-*.tar.xz --xattrs-include="*.*" --numeric-owner'
```

---

## 4. Chroot into New Environment

```bash
# Prepare chroot
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev

# Enter chroot
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) $PS1"
```

```bash
git add -A
git commit \
  -m "Enter chroot and mount virtual filesystems" \
  -m $'Commands run:\n  cp --dereference /etc/resolv.conf /mnt/gentoo/etc/\n  mount --types proc /proc /mnt/gentoo/proc\n  mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys\n  mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev\n  chroot /mnt/gentoo /bin/bash\n  source /etc/profile\n  export PS1="(chroot) $PS1"'
```

---

## 5. Configure Base System

```bash
# Timezone & locale
echo "Europe/Berlin" > /etc/timezone
emerge --config sys-libs/timezone-data

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
esseselect locale set en_US.utf8
env-update && source /etc/profile

# Portage settings: /etc/portage/make.conf
cat << 'EOF' > /etc/portage/make.conf
CFLAGS="-O2 -march=haswell -pipe"
MAKEOPTS="-j3"
USE="systemd elogind wifi bluetooth alsa"
EOF

# Hostname
echo "macair" > /etc/hostname

# fstab
cat << 'EOF' > /etc/fstab
/dev/sda3   /       ext4    defaults,noatime 0 1
/dev/sda2   none    swap    sw               0 0
/dev/sda1   /boot/efi vfat  umask=0077      0 2
EOF
```  
```bash
git add -A
git commit \
  -m "Configure timezone, locale, make.conf, hostname, fstab" \
  -m $'Commands run:\n  echo "Europe/Berlin" > /etc/timezone\n  emerge --config sys-libs/timezone-data\n  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen\n  locale-gen\n  eselect locale set en_US.utf8\n  env-update && source /etc/profile\n  cat << EOF > /etc/portage/make.conf ... EOF\n  echo "macair" > /etc/hostname\n  cat << EOF > /etc/fstab ... EOF'
```

---

## 6. Kernel & Modules

```bash
# Install sources
emerge --ask sys-kernel/gentoo-sources
\# Configure kernel
cd /usr/src/linux
make menuconfig
# ...enable EFI, Intel i915, HDA, USB, FAT, etc.

# Compile & install
make -j3
make modules_install
cp arch/x86/boot/bzImage /boot/kernel-$(make kernelversion)
```  
```bash
git add -A
git commit \
  -m "Install and compile kernel" \
  -m $'Commands run:\n  emerge --ask sys-kernel/gentoo-sources\n  cd /usr/src/linux\n  make menuconfig\n  make -j3\n  make modules_install\n  cp arch/x86/boot/bzImage /boot/kernel-$(make kernelversion)'
```

---

## 7. Build & Install UGREEN USB Network Driver

```bash
# Ensure build tools and headers
emerge --ask sys-devel/gcc sys-devel/make sys-devel/binutils sys-kernel/linux-headers

# The driver sources live at /drivers/usbnet
cd /drivers/usbnet
make
make install
modprobe <driver_name>
\# Auto-load at boot
echo "<driver_name>" > /etc/modules-load.d/ugreen.conf
```  
```bash
git add -A
git commit \
  -m "Build and install UGREEN USB Ethernet driver" \
  -m $'Commands run:\n  emerge --ask sys-devel/gcc sys-devel/make sys-devel/binutils sys-kernel/linux-headers\n  cd /drivers/usbnet\n  make\n  make install\n  modprobe <driver_name>\n  echo "<driver_name>" > /etc/modules-load.d/ugreen.conf'
```

---

## 8. EFI Bootloader & Systemd Setup

```bash
# Install GRUB
emerge --ask sys-boot/grub:2

# Configure GRUB
cat << 'EOF' > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_CMDLINE_LINUX="root=/dev/sda3 quiet"
EOF

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo
grub-mkconfig -o /boot/grub/grub.cfg

# Switch to systemd profile
eselect profile list
eselect profile set <number>  # choose systemd
env-update && source /etc/profile
emerge --ask sys-apps/systemd
```  
```bash
git add -A
git commit \
  -m "Install GRUB EFI and switch to systemd" \
  -m $'Commands run:\n  emerge --ask sys-boot/grub:2\n  cat << EOF > /etc/default/grub ... EOF\n  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo\n  grub-mkconfig -o /boot/grub/grub.cfg\n  eselect profile set <number>\n  env-update && source /etc/profile\n  emerge --ask sys-apps/systemd'
```

---

## 9. Enable Services & Finalize

```bash
# Enable network & essentials
emerge --ask net-wireless/wpa_supplicant net-firmware/broadcom-sta net-misc/dhcpcd
rc-update add dhcpcd default  # if still using dhcpcd

systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable sshd
```

```bash
git add -A
git commit \
  -m "Enable network & essential services" \
  -m $'Commands run:
  emerge --ask net-wireless/wpa_supplicant net-firmware/broadcom-sta net-misc/dhcpcd
  rc-update add dhcpcd default
  systemctl enable systemd-networkd
  systemctl enable systemd-resolved
  systemctl enable sshd'
```

---

## 10. Exit and Reboot

```bash
exit
cd /
umount -l /mnt/gentoo/{boot/efi,dev,sys,proc}
swapoff -a
reboot
```

```bash
git add -A
git commit \
  -m "Finalize install and reboot" \
  -m $'Commands run:
  exit chroot
  umount -l /mnt/gentoo/{boot/efi,dev,sys,proc}
  swapoff -a
  reboot'
```

---

**Congratulations!** You now have a fully tracked, Git-logged Gentoo installation. Use `git log --stat` to review your history or `git commit --amend` to fix any mistakes. Enjoy your custom Gentoo system!


