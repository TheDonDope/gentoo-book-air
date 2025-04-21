# Gentoo Linux Installation Guide (Systemd) for Mid‑2013 MacBook Air

This `README.md` serves as a step-by-step installation guide for Gentoo Linux on a mid-2013 MacBook Air, using systemd as the init system. The installation process is tracked using Git, allowing you to review changes and commands executed during the setup.
This guide assumes you have a live USB with the Gentoo installation media and an USB network adapter driver source available. The installation will be done in a `chroot` environment.

> **Assumptions:**
> - You have a Gentoo stage3 archive at `/stage3/stage3-*.tar.xz` on your live USB.
> - You have a portage snapshot at `/portage/portage-*.tar.xz` on your live USB.
> - You’ve backed up all data and are ready for a full disk wipe.

```bash
USB/
├── stage3/
│   └── stage3-*.tar.xz
└── portage/
    └── portage-latest.tar.xz
```

---

## 1. Boot Live USB

1. Boot your MacBook Air from the Gentoo live USB. (Hold `Option` key during boot and select the USB drive.)
2. Connect to the internet using the USB network adapter.
3. Open a terminal.
4. Switch to root user:
```bash
sudo su -
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
mkfs.vfat -F 32 ${DRIVE}1
mkswap ${DRIVE}2
mkfs.ext4 ${DRIVE}3
```

---

## 3. Mount Partitions

```bash
mount /dev/sda3 /mnt/gentoo
mkdir -p /mnt/gentoo/boot/efi
mount /dev/sda1 /mnt/gentoo/boot/efi
swapon /dev/sda2
```

---

## 4. Mount USB Drive and Extract Stage3 & Portage

```bash
# Mount USB drive
mkdir -p /mnt/usb
# Replace sdb1 with your USB drive
mount /dev/sdb1 /mnt/usb

# Extract stage3 archive
cd /mnt/gentoo
tar xpvf /mnt/usb/stage3/stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

# Extract portage snapshot
tar xpvf /mnt/usb/portage/portage-*.tar.xz -C /mnt/gentoo/usr
```

---

## 5. Apply settings for make.conf

- Open the file by running `nano /mnt/gentoo/etc/portage/make.conf` and modify the following lines:

```bash
# Update CFLAGS
CFLAGS="-O2 -march=haswell -pipe"

# Add Make options
MAKEOPTS="-j3"

# Optional: accept all licenses
ACCEPT_LICENSE="*"
```

---

## 6. Configure Gentoo ebuild repo & copy the DNS info

```bash
# Copy repo configuration
mkdir -p /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

# Copy DNS info
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```

---

## 7. Mount the filesystems

```bash
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev
```

---

## 8. Chroot into New Environment

```bash
# Enter chroot
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) $PS1"
```

---

## 9. Update Portage

```bash
# Update Portage tree
emerge-webrsync
```

## 10. Configure Base System

```bash
# Timezone & locale
echo "Europe/Berlin" > /etc/timezone
emerge --config sys-libs/timezone-data

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

# Hostname
echo "gentoo-book-air" > /etc/hostname

# Set root password
passwd

# fstab
cat << 'EOF' > /etc/fstab
/dev/sda3   /       ext4    defaults,noatime 0 1
/dev/sda2   none    swap    sw               0 0
/dev/sda1   /boot/efi vfat  umask=0077      0 2
EOF
```

---

## 11. Configure Kernel

```bash
# Install sources
emerge --ask sys-kernel/gentoo-sources
# Configure kernel
cd /usr/src/linux-6.12.21-gentoo
make mrproper
make defconfig
make menuconfig
```
Select the following options:

### CPU & Architecture

- Processor type and features → Processor family → Core 2/newer Xeon (or Haswell)
- Enable EFI stub support (CONFIG_EFI_STUB)
- EFI Variable Support via sysfs (CONFIG_EFI_VARS)

### Intel Graphics (iGPU)

- Device Drivers → Graphics support:
  - Direct Rendering Manager (XFree86 4.1.0 and higher DRI support) → Intel 8xx/9xx/G3x/G4x/HD Graphics

### Audio (HDA)

- Device Drivers → Sound card support → Advanced Linux Sound Architecture:
  - PCI sound devices → HD-Audio → built-in

### Networking (Wi-Fi, Ethernet)

- Device Drivers -> Network device support -> Wireless LAN:
  - Broadcom FullMAC WLAN driver → brcmsmac or brcmfmac
  - Or use net-firmware/broadcom-sta (non-free) and disable conflicting drivers (b43, ssb, bcma)
- Device Drivers -> Network device support -> USB Network Adapters:
  - USB NIC: make sure CDC Ethernet support and Realtek RTL8152/RTL8153 USB driver are enabled under USB Network Adapters

### Power Management

- Power management and ACPI options -> ACPI Support:
  - Everything enabled (AC, Battery, Fan, Thermal Zone, Processor)
- Intel P-state driver
- Intel Smart Sound Technology (optional)

### Storage

- Device Drivers → Serial ATA and Parallel ATA drivers:
  - AHCI SATA support → built-in
- File systems:
  - ext4 (built-in)
  - vfat, msdos → for EFI partition
  - EFI Variables File System (under Firmware Drivers) → for GRUB/systemd to work properly

### Input & USB

- Device Drivers → USB Support:
  - EHCI, XHCI (USB 3.0), OHCI → all needed
- HID support → Apple devices
- MacBook Pro / Air Keyboard support (under HID or Apple modules)
- Multitouch / Synaptics or Apple Magic Trackpad drivers

### Security (Optional)
- Enable TPM support → for full disk encryption with LUKS later

---

## 12. Compile Kernel & Modules

```bash

# Compile & install
make -j3
make modules_install
cp arch/x86/boot/bzImage /boot/kernel-$(make kernelversion)
```

---

## 13. EFI Bootloader & Systemd Setup

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
# Set systemd profile
# (22 or the number corresponding to systemd)
eselect profile set 22
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
emerge --ask sys-apps/systemd
# Update @world set
emerge --ask --verbose --update --deep --newuse @world
```

---

## 14. Enable Services & Finalize

```bash
# Enable network & essentials
emerge --ask net-wireless/wpa_supplicant net-wireless/broadcom-sta net-misc/dhcpcd
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable sshd

# systemd-networkd config
cat << 'EOF' > /etc/systemd/network/25-wireless.network
[Match]
Name=wlan0

[Network]
DHCP=yes

[DHCP]
UseDNS=yes
EOF

# WPA Supplicant config
mkdir -p /etc/wpa_supplicant
cat << 'EOF' > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
ctrl_interface=/run/wpa_supplicant
ctrl_interface_group=wheel
update_config=1

network={
    ssid="YourNetworkSSID"
    psk="yourpassword"
}
EOF
chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

systemctl enable wpa_supplicant@wlan0.service
```

---

## 15. Exit and Reboot

```bash
exit
cd /
umount -l /mnt/gentoo/{boot/efi,dev,sys,proc}
swapoff -a
reboot
```
