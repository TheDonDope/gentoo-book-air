# Gentoo Linux Installation Guide (Systemd) for Mid‑2013 MacBook Air

This guide provides a streamlined installation process for Gentoo Linux on a mid-2013 MacBook Air, using `genkernel` for optimal hardware support and systemd as the init system.
This guide assumes you have a live USB with the Gentoo installation media and a Gentoo stage3 archive on it. The installation will be done in a `chroot` environment.

> **Assumptions:**
> - You have a Gentoo stage3 archive at `/stage3/stage3-*.tar.xz` on your live USB.
> - You’ve backed up all data and are ready for a full disk wipe.

```bash
USB/
├── stage3/
└── └── stage3-*.tar.xz
```

---

## 1. Boot Live USB

1. Boot from the Gentoo live USB (hold `Option` key during startup).
2. Connect to the internet (use USB Ethernet adapter or follow [Gentoo WiFi docs](https://wiki.gentoo.org/wiki/Wifi)).
3. Open a terminal and switch to root:
```bash
sudo su -
```

---

## 2. Partition & Format Disk

```bash
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

## 4. Mount USB Drive and Extract Stage3

```bash
mkdir -p /mnt/usb
# Replace `sdb1` with your USB device
mount /dev/sdb1 /mnt/usb

# Extract stage3 archive
cd /mnt/gentoo
tar xpvf /mnt/usb/stage3/stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
```

---

## 5. Configure make.conf

Edit `/mnt/gentoo/etc/portage/make.conf`:

```bash
CFLAGS="-O2 -march=haswell -pipe"
MAKEOPTS="-j3"
ACCEPT_LICENSE="*"
```

---

## 6. Configure Repos and DNS

```bash
mkdir -p /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```

---

## 7. Mount Filesystems

```bash
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev
```

---

## 8. Chroot into New Environment

```bash
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) $PS1"
```

---

## 9. Update Portage

```bash
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

# Hostname and root password
echo "gentoo-book-air" > /etc/hostname
passwd

# Use UUIDs in /etc/fstab
ROOT_UUID=$(blkid -s UUID -o value /dev/sda3)
EFI_UUID=$(blkid -s UUID -o value /dev/sda1)
cat << EOF > /etc/fstab
UUID=$ROOT_UUID   /       ext4    defaults,noatime 0 1
/dev/sda2         none    swap    sw               0 0
UUID=$EFI_UUID    /boot/efi vfat  umask=0077      0 2
EOF
```

---

## 11. Install Kernel with Genkernel

```bash
# Install kernel sources and genkernel
emerge --ask sys-kernel/gentoo-sources sys-kernel/genkernel

# Set kernel symlink
eselect kernel list
# Replace "1" with your kernel index
eselect kernel set 1
# Verify symlink
ls -l /usr/src/linux

# Configure and compile kernel
genkernel --menuconfig all
```

During `menuconfig`:

1. WiFi (`CONFIG_BRCMFMAC`)

Navigation path:

```bash
Device Drivers
  → Network device support
    → Wireless LAN
      → Broadcom devices
        → <M> Broadcom FullMAC WLAN driver (BRCMFMAC)
```

2. Intel GPU (`CONFIG_DRM_I915`)

Navigation path:

```bash
Device Drivers
  → Graphics support
    → <M> Direct Rendering Manager (XFree86 4.1.0 and higher)
      → <M> Intel 8xx/9xx/G3x/G4x/HD Graphics
```

3. NVMe SSD (`CONFIG_NVME_CORE`)

Navigation path:

```bash
Device Drivers
  → NVME Support
    → <*> NVM Express block device
    → [*] NVMe multipath support
    → [*] NVMe hardware monitoring
```

4. Trackpad (`CONFIG_INPUT_APPLE_IBRIDGE`)

Navigation path:

```bash
Device Drivers
  → Input device support
    → Mice
      → <M> Apple USB Touchpad support (INPUT_APPLE_IBRIDGE)
      → <M> Apple USB BCM5974 Multitouch trackpad support (INPUT_APPLE_IBRIDGE)
```

5. Firmware Loading

Navigation path:

```bash
Device Drivers
  → Firmware Drivers
    → -*- Export DMI identification via sysfs to userspace
```

---

## 12. Configure GRUB with UUIDs

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

## 13. Set Systemd Profile

```bash
# Choose systemd profile (e.g., 22)
eselect profile list
eselect profile set 22

cat << EOF > /etc/portage/package.use/systemd
sys-apps/systemd bash-completion
EOF
emerge --ask sys-apps/systemd sys-kernel/linux-firmware app-shells/bash-completion

eselect bashcomp enable systemd
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

## 14. Enable Services

```bash
# Install WiFi drivers
mkdir -p /etc/portage/package.accept_keywords
echo "net-wireless/broadcom-sta ~amd64" >> /etc/portage/package.accept_keywords/broadcom-sta
emerge --ask net-wireless/broadcom-sta
# Build kernel module
emerge --config broadcom-sta

# Enable network & essentials
emerge --ask net-wireless/wpa_supplicant

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

cat << EOF > /etc/systemd/network/25-wireless.network
[Match]
Name=wlan0

[Network]
DHCP=yes

[DHCP]
UseDNS=yes
EOF

# Configure WiFi
mkdir -p /etc/wpa_supplicant
cat << EOF > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
ctrl_interface=/run/wpa_supplicant
ctrl_interface_group=wheel
update_config=1

network={
    ssid="YourNetworkSSID"
    psk="yourpassword"
}
EOF
chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

systemctl enable systemd-networkd systemd-resolved
systemctl enable wpa_supplicant@wlan0.service

# Configure SSH
cat << EOF > /etc/ssh/sshd_config
PermitRootLogin yes
EOF

# On your Client Machine: Generate (if necessary) SSH keys
ssh-keygen -t ed25519
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@<your_gentoo_ip>
# On your Gentoo Machine: Reconfigure SSH to reject passwod logins and only accept keys
cat << EOF > /etc/ssh/sshd_config
PermitRootLogin prohibit-password
EOF

# Enable SSH
systemctl enable sshd
```

---

## 15. Exit and Reboot

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