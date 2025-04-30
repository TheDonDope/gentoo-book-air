# Gentoo Linux Installation Guide (Systemd) for Mid‑2013 MacBook Air

This guide provides a streamlined installation process for Gentoo Linux on a mid-2013 MacBook Air, using `genkernel` for optimal hardware support and systemd as the init system.
This guide assumes you have a live USB with the Gentoo installation media and a Gentoo stage3 archive on it. The installation will be done in a `chroot` environment.

> **Assumptions:**
> - You have a Gentoo stage3 archive at `/stage3/stage3-*.tar.xz` on your live USB.
> - You’ve backed up all data and are ready for a full disk wipe.

```bash
USB/
└── stage3/
    └── stage3-*.tar.xz
```

---

## 0. Boot Live USB

1. Boot from the Gentoo live USB (hold `Option` key during startup).
2. Connect to the internet (use USB Ethernet adapter or follow [Gentoo WiFi docs](https://wiki.gentoo.org/wiki/Wifi)).
3. Open a terminal and switch to root:
```bash
sudo su -
```

---

## 1. Partitioning the disk with GPT for UEFI

- References:
  - [Gentoo Handbook:AMD64 > Installation > Disks](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Partitioning_the_disk_with_GPT_for_UEFI)
  - [./usr/local/bin/01-partitioning-the-disk-with-gpt-for-uefi.sh](./usr/local/bin/01-partitioning-the-disk-with-gpt-for-uefi.sh)

```bash
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
```

---

## 2. Mounting the root partition

- References:
  - [Gentoo Handbook:AMD64 > Installation > Disks](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Mounting_the_root_partition)
  - [./usr/local/bin/02-mounting-the-root-partition.sh](./usr/local/bin/02-mounting-the-root-partition.sh)

```bash
mount /dev/sda3 /mnt/gentoo
mkdir --parents /mnt/gentoo/efi
```

---

## 3. Installing a stage file

- References:
  - [Gentoo Handbook:AMD64 > Installation > Stage](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Installing_a_stage_file)
  - [./usr/local/bin/03-installing-a-stage-file.sh](./usr/local/bin/03-installing-a-stage-file.sh)

```bash
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
```

---

## 4. Configuring compile options

- References:
  - [Gentoo Handbook:AMD64 > Installation > Stage](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Configuring_compile_options)
  - [./usr/local/bin/04-configuring-compile-options.sh](./usr/local/bin/04-configuring-compile-options.sh)

Run `nano /mnt/gentoo/etc/portage/make.conf`:

```bash
COMMON_FLAGS="-march=haswell -O2 -pipe"
MAKEOPTS="-j3"
ACCEPT_LICENSE="*"
```

---

## 5. Copy DNS info

- References:
  - [Gentoo Handbook:AMD64 > Installation > Base](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Copy_DNS_info)
  - [./usr/local/bin/05-copy-dns-info.sh](./usr/local/bin/05-copy-dns-info.sh)

```bash
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```

---

## 6. Mounting the necessary filesystems

- References:
  - [Gentoo Handbook:AMD64 > Installation > Base](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Mounting_the_necessary_filesystems)
  - [./usr/local/bin/06-mounting-the-necessary-filesystems.sh](./usr/local/bin/06-mounting-the-necessary-filesystems.sh)

```bash
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
```

---

## 7. Entering the new environment

- References:
  - [Gentoo Handbook:AMD64 > Installation > Base](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Entering_the_new_environment)
  - [./usr/local/bin/07-entering-the-new-environment.sh](./usr/local/bin/07-entering-the-new-environment.sh)

```bash
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) $PS1"
```

---

## 8. Preparing for a bootloader

- References:
  - [Gentoo Handbook:AMD64 > Installation > Base](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#UEFI_systems)
  - [./usr/local/bin/08-preparing-for-a-bootloader.sh](./usr/local/bin/08-preparing-for-a-bootloader.sh)

```bash
mount /dev/sda1 /efi
```

## 9. Configuring Portage

- References:
  - [Gentoo Handbook:AMD64 > Installation > Base](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Installing_a_Gentoo_ebuild_repository_snapshot_from_the_web)
  - [./usr/local/bin/09-configuring-portage.sh](./usr/local/bin/09-configuring-portage.sh)

```bash
emerge-webrsync
```

## 10. Choosing the right profile

- References:
  - [Gentoo Handbook:AMD64 > Installation > Base](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Choosing_the_right_profile)
  - [./usr/local/bin/10-choosing-the-right-profile.sh](./usr/local/bin/10-choosing-the-right-profile.sh)

```bash
eselect profile list
eselect profile set 22
emerge --ask --verbose --update --deep --changed-use @world
emerge --ask --pretend --depclean
emerge --ask --depclean
```

## 11. Configuring timezone and locales

- References:
  - [Gentoo Handbook:AMD64 > Installation > Base](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Timezone)
  - [Gentoo Handbook:AMD64 > Installation > Base](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Configure_locales)
  - [./usr/local/bin/11-configuring-timezone-and-locales.sh](./usr/local/bin/11-configuring-timezone-and-locales.sh)

```bash
# Timezone & locale
ln -sf ../usr/share/zoneinfo/Europe/Berlin /etc/localtime
cat << EOF > /etc/locale.gen
en_US ISO-8859-1
en_US.UTF-8 UTF-8
de_DE ISO-8859-1
de_DE.UTF-8 UTF-8
EOF
locale-gen
eselect locale list
# Select en_US.UTF-8
eselect locale set 9
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
```

## 12. Configuring the Linux kernel

- References:
  - [Gentoo Handbook:AMD64 > Installation > Kernel](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Suggested:_Linux_Firmware)
  - [Gentoo Handbook:AMD64 > Installation > Kernel](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#systemd-boot)
  - [Gentoo Handbook:AMD64 > Installation > Kernel](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Initramfs)
  - [./usr/local/bin/12-configuring-the-linux-kernel.sh](./usr/local/bin/12-configuring-the-linux-kernel.sh)

```bash
# Install linux-firmware
emerge --ask sys-kernel/linux-firmware

# Configure systemd-boot
cat << EOF > /etc/portage/package.use/systemd
sys-apps/systemd boot
sys-kernel/installkernel systemd-boot
EOF

# Configure Initramfs with dracut
cat << EOF > /etc/portage/package.use/installkernel
sys-kernel/installkernel dracut
EOF

# Configure kernel command line
cat << EOF > /etc/kernel/cmdline
quiet splash
EOF

# Install systemd and installkernel
emerge --ask sys-apps/systemd sys-kernel/installkernel
```

---

## 13. Install Kernel

- References:
  - [Gentoo Handbook:AMD64 > Installation > Kernel](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Installing_a_distribution_kernel)
  - [./usr/local/bin/13-install-kernel.sh](./usr/local/bin/13-install-kernel.sh)

```bash
# Install Gentoo distribution kernel
emerge --ask sys-kernel/gentoo-kernel

# Clean up
emerge --depclean

# Set `dist-kernel` USE-flag
nano /etc/portage/make.conf

# Add `USE="dist-kernel"` line

# Manually rebuild the initramfs
emerge --ask @module-rebuild
emerge --config sys-kernel/gentoo-kernel
```

---

## 14. Configure GRUB

See: [./usr/local/bin/14-configure-grub.sh](./usr/local/bin/14-configure-grub.sh)

```bash
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
```

---

## 15. Set Systemd Profile

See: [./usr/local/bin/15-set-systemd-profile.sh](./usr/local/bin/15-set-systemd-profile.sh)

```bash
# Choose systemd profile (e.g., 22)
eselect profile list
eselect profile set 22

cat << EOF > /etc/portage/package.use/systemd
sys-apps/systemd bash-completion
EOF
emerge --ask sys-apps/systemd sys-kernel/linux-firmware app-shells/bash-completion

eselect bashcomp enable systemctl
eselect bashcomp enable networkctl
eselect bashcomp enable journalctl

cat << EOF > /etc/profile.d/completion.sh
# enable bash completion if available
if [ -f /etc/bash_completion ]; then
  source /etc/bash_completion
fi

# Gentoo Portage completions
if [ -f /usr/share/portage/bashrc ]; then
  source /usr/share/portage/bashrc
fi
EOF

emerge --ask --verbose --update --deep --newuse @world
```

---

## 16. Configure Systemd Services

See: [./usr/local/bin/16-configure-systemd-services.sh](./usr/local/bin/16-configure-systemd-services.sh)

```bash
# Install WiFi drivers
#mkdir -p /etc/portage/package.accept_keywords
#echo "net-wireless/broadcom-sta ~amd64" >> /etc/portage/package.accept_keywords/broadcom-sta
#emerge --ask net-wireless/broadcom-sta
# Build kernel module
#emerge --config broadcom-sta

# Enable network & essentials
#emerge --ask net-wireless/wpa_supplicant

# Configure network
cat << EOF > /etc/systemd/network/20-wired-static.network
[Match]
# Replace with your ethernet interface name
# Use `ip link` to find the name (e.g., enp0s20u2)
Name=enp0s20u2

[Network]
# Change to your static IP
Address=192.168.2.44/24
# Replace with your router's IP
Gateway=192.168.2.1
# Replace with your DNS server (this example uses Cloudflare)
DNS=1.1.1.1
DHCP=no
IPv6AcceptRA=no
LinkLocalAddressing=no
EOF

#cat << EOF > /etc/systemd/network/25-wireless.network
#[Match]
#Name=wlan0

#[Network]
#DHCP=yes

#[DHCP]
#UseDNS=yes
#EOF

# Configure WiFi
#mkdir -p /etc/wpa_supplicant
#cat << EOF > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
#ctrl_interface=/run/wpa_supplicant
#ctrl_interface_group=wheel
#update_config=1

#network={
#    ssid="YourNetworkSSID"
#    psk="yourpassword"
#}
#EOF
#chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

systemctl enable systemd-networkd systemd-resolved
#systemctl enable wpa_supplicant@wlan0.service

# Configure SSH
cat << EOF > /etc/ssh/sshd_config
PermitRootLogin yes
EOF

# Enable SSH
systemctl enable sshd
```

- On your Client Machine: Generate (if necessary) SSH keys
```bash
ssh-keygen -t ed25519
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@<your_gentoo_ip>
```
- On your Gentoo Machine: Reconfigure SSH to reject passwod logins and only accept keys
```bash
cat << EOF > /etc/ssh/sshd_config
PermitRootLogin prohibit-password
EOF

systemctl restart sshd
```

---

## 17. Finalize and Reboot

See: [./usr/local/bin/17-finalize-and-reboot.sh](./usr/local/bin/17-finalize-and-reboot.sh)

```bash
exit
cd /
umount -R /mnt/gentoo
swapoff -a
reboot
```

## Post-Installation Notes

1. **WiFi Firmware**: If WiFi doesn’t work, load the Broadcom module:
```bash
echo "brcmfmac" > /etc/modules-load.d/brcmfmac.conf
```
2. **Fallback Bootloader**: If GRUB isn’t detected, install `rEFInd`:
```bash
emerge --ask sys-boot/refind
refind-install
```
3. **Trim Support for SSD**:
- Add `discard` to `/etc/fstab` for the root partition, or enable the timer:
```bash
systemctl enable fstrim.timer
```

---

**Done!** Your MacBook Air should now boot into Gentoo with full hardware support.

---

## Day-to-Day Commands Cheatsheet

### **Portage (Package Management)**
| Command | Description |
|---------|-------------|
| `emerge --sync` | Update the Portage tree (sync package repositories). |
| `emerge -auD @world` | Update all installed packages (`-a`: ask, `-u`: update, `-D`: deep, `--newuse`). |
| `emerge -av <package>` | Install a package (e.g., `emerge -av firefox`). |
| `emerge -avC <package>` | Uninstall a package and its dependencies. |
| `emerge --depclean` | Remove orphaned dependencies. |
| `emerge --info` | Show current USE flags, CFLAGS, and system configuration. |
| `eix <keyword>` | Search for packages (install `eix` first: `emerge -av eix`). |
| `qlist -IRv` | List all installed packages. |
| `equery files <package>` | List files installed by a package (requires `gentoolkit`: `emerge -av gentoolkit`). |
| `emerge --pretend --update --deep --newuse @world` | Simulate a system update without making changes. |

---

### **USE Flags and Configuration**
| Command | Description |
|---------|-------------|
| `nano /etc/portage/make.conf` | Edit global USE flags and compiler settings. |
| `nano /etc/portage/package.use/<file>` | Add per-package USE flags. |
| `emerge -av --autounmask-write <package>` | Resolve USE flag conflicts (run `etc-update` afterward). |
| `etc-update` | Apply changes to configuration files after updates. |
| `dispatch-conf` | Review and merge `.conf` file changes interactively. |

---

### **Systemd (Service Management)**
| Command | Description |
|---------|-------------|
| `systemctl start <service>` | Start a service (e.g., `systemctl start sshd`). |
| `systemctl stop <service>` | Stop a service. |
| `systemctl restart <service>` | Restart a service. |
| `systemctl enable <service>` | Enable a service at boot. |
| `systemctl disable <service>` | Disable a service at boot. |
| `systemctl status <service>` | Check if a service is running. |
| `journalctl -u <service>` | View logs for a service (e.g., `journalctl -u systemd-networkd`). |
| `journalctl -f` | Follow live logs. |
| `systemctl list-unit-files` | List all services and their enablement status. |
| `systemctl reboot` | Reboot the system. |
| `systemctl poweroff` | Shut down the system. |

---

### **Kernel and Hardware**
| Command | Description |
|---------|-------------|
| `genkernel --menuconfig all` | Rebuild the kernel and initramfs. |
| `dracut --regenerate-all --force` | Rebuild initramfs (if not using `genkernel`). |
| `uname -r` | Check the current kernel version. |
| `lspci` | List PCI devices. |
| `lsusb` | List USB devices. |
| `dmesg` | View kernel ring buffer (hardware/driver logs). |

---

### **Miscellaneous**
| Command | Description |
|---------|-------------|
| `eselect news read` | Read Gentoo news updates. |
| `eselect locale list` | List available locales. |
| `rc-update show` | List OpenRC services (if not using systemd). |
| `find /etc -name '._cfg*'` | Find unmerged configuration files after updates. |
| `smartctl -a /dev/sda` | Check SSD/HDD health (requires `smartmontools`). |

---

### **Troubleshooting**
| Command | Description |
|---------|-------------|
| `systemctl rescue` | Boot into rescue mode (single-user). |
| `systemctl isolate multi-user.target` | Switch to CLI-only mode. |
| `emerge -av --keep-going @world` | Continue updates even if some packages fail. |
| `emerge -e @world` | Deep-rebuild the entire system (use with caution!). |