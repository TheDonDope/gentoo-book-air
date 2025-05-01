# Gentoo Linux Installation Guide for Mid 2013 MacBook Air

This guide provides a streamlined installation process for Gentoo Linux on a mid-2013 MacBook Air, using the [Gentoo Handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64). It is tailored for users who are familiar with the command line and Linux installations.
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

- [Gentoo Linux Installation Guide for Mid 2013 MacBook Air](#gentoo-linux-installation-guide-for-mid-2013-macbookair)
  - [Boot Live USB](#boot-live-usb)
  - [Preparing the disks](#preparing-the-disks)
    - [Partitioning the disk with GPT for UEFI](#partitioning-the-disk-with-gpt-for-uefi)
    - [Creating file systems](#creating-file-systems)
    - [Mounting the root partition](#mounting-the-root-partition)
  - [Installing the Gentoo installation files](#installing-the-gentoo-installation-files)
    - [Mounting the USB drive](#mounting-the-usb-drive)
    - [Installing a stage file](#installing-a-stage-file)
    - [Configuring compile options](#configuring-compile-options)
  - [Installing the Gentoo base system](#installing-the-gentoo-base-system)
    - [Chrooting](#chrooting)
      - [Copy DNS info](#copy-dns-info)
      - [Mounting the necessary filesystems](#mounting-the-necessary-filesystems)
      - [Entering the new environment](#entering-the-new-environment)
      - [Preparing for a bootloader](#preparing-for-a-bootloader)
    - [Configuring Portage](#configuring-portage)
      - [Installing a Gentoo ebuild repository snapshot from the web](#installing-a-gentoo-ebuild-repository-snapshot-from-the-web)
      - [Choosing the right profile](#choosing-the-right-profile)
      - [Optional: Configuring the USE variable](#optional-configuring-the-use-variable)
    - [Timezone](#timezone)
    - [Configure locales](#configure-locales)
      - [Locale generation](#locale-generation)
      - [Locale selection](#locale-selection)
  - [Configuring the Linux kernel](#configuring-the-linux-kernel)
    - [Optional: Installing firmware and/or microcode](#optional-installing-firmware-andor-microcode)
      - [Firmware](#firmware)
    - [sys-kernel/installkernel](#sys-kernelinstallkernel)
      - [Bootloader](#bootloader)
        - [systemd-boot](#systemd-boot)
    - [Kernel configuration and compilation](#kernel-configuration-and-compilation)
      - [Distribution kernels](#distribution-kernels)
        - [Run systemd initial setup](#run-systemd-initial-setup)
        - [Installing a distribution kernel](#installing-a-distribution-kernel)
        - [Upgrading and cleaning up](#upgrading-and-cleaning-up)
  - [Configuring the system](#configuring-the-system)
    - [Filesystem information](#filesystem-information)
      - [Partition labels and UUIDs](#partition-labels-and-uuids)
      - [Creating the fstab file](#creating-the-fstab-file)
        - [UEFI systems](#uefi-systems)
    - [Networking Information](#networking-information)
      - [Hostname](#hostname)
      - [Network](#network)
      - [The hosts file](#the-hosts-file)
    - [System information](#system-information)
      - [Root password](#root-password)
  - [Installing system tools](#installing-system-tools)
    - [Optional: Remote shell access](#optional-remote-shell-access)
      - [systemd](#systemd)
    - [Optional: Shell completion](#optional-shell-completion)
    - [Suggested: Time synchronization](#suggested-time-synchronization)
      - [systemd](#systemd-1)
  - [Configuring the bootloader](#configuring-the-bootloader)
    - [Alternative 1: systemd-boot](#alternative-1-systemd-boot)
      - [Emerge](#emerge)
      - [Installation](#installation)
    - [Rebooting the system](#rebooting-the-system)
  - [Finalizing](#finalizing)
    - [User administration](#user-administration)
      - [Adding a user for daily use](#adding-a-user-for-daily-use)
      - [Install sudo and allow wheel group as sudoer](#install-sudo-and-allow-wheel-group-as-sudoer)
    - [Further system tools](#further-system-tools)
      - [Install fastfetch](#install-fastfetch)
      - [Install git](#install-git)
      - [Install neovim](#install-neovim)
    - [Further developer tools](#further-developer-tools)
      - [Install golang](#install-golang)

---

## Boot Live USB

1. Boot from the Gentoo live USB (hold `Option` key during startup).
2. Connect to the internet (use USB Ethernet adapter or follow [Gentoo WiFi docs](https://wiki.gentoo.org/wiki/Wifi)).
3. Open a terminal and switch to root:
```bash
sudo su -
```

---

## Preparing the disks

- Reference: [Gentoo Handbook:AMD64 > Installation > Disks](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks)

### Partitioning the disk with GPT for UEFI

- Reference: [Gentoo Handbook:AMD64 > Installation > Disks # Partitioning the disk with GPT for UEFI](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Partitioning_the_disk_with_GPT_for_UEFI)

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
# Press `+8G` for the size of the swap partition (RAM size * 2)
# Press `Y` to confirm removing the existing partition
# Press `t` to change the partition type
# Press `2` to select the swap partition
# Press `19` to set the partition type to Linux swap partition

# Creating the root partition

# Press `n` to create a new partition
# Press `3` for the third partition
# Press `Enter` to accept the default first sector
# Press `Enter` to accept the default last sector (use the rest of the disk)
# Press `Y` to confirm removing the existing partition
# Press `t` to change the partition type
# Press `3` to select the root partition
# Press `23` to set the partition type to Linux filesystem (Linux Root (x86-64)

# Press `p` to print the partition table again to verify
# Press `w` to write the changes and exit fdisk
```

### Creating file systems

- Reference: [Gentoo Handbook:AMD64 > Installation > Disks # Creating file systems](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Creating_file_systems)

```bash
DRIVE=/dev/sda

# Format partitions
mkfs.vfat -F 32 ${DRIVE}1
mkswap ${DRIVE}2
mkfs.ext4 ${DRIVE}3

# Activate swap
swapon ${DRIVE}2
```

### Mounting the root partition

- Reference: [Gentoo Handbook:AMD64 > Installation > Disks # Mounting the root partition](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Mounting_the_root_partition)

```bash
mount /dev/sda3 /mnt/gentoo
mkdir --parents /mnt/gentoo/efi
```

---

## Installing the Gentoo installation files

- Reference: [Gentoo Handbook:AMD64 > Installation > Stage](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage)

### Mounting the USB drive

```bash
mkdir --parents /mnt/usb
# Replace `sdb1` with your USB device
mount /dev/sdb1 /mnt/usb
```

### Installing a stage file

- Reference: [Gentoo Handbook:AMD64 > Installation > Stage # Installing a stage file](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Installing_a_stage_file)

```bash
# Extract stage3 archive
tar xpvf /mnt/usb/stage3/stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# tar options:
# `x` extract, instructs tar to extract the contents of the archive.
# `p` preserve permissions.
# `v` verbose output.
# `f` file, provides tar with the name of the input archive.
# `--xattrs-include='*.*'` Preserves extended attributes in all namespaces stored in the archive.
# `--numeric-owner` Ensure that the user and group IDs of files being extracted from the tarball remain the same as Gentoo's release engineering team intended (even if adventurous users are not using official Gentoo live environments for the installation process).
# `-C /mnt/gentoo` Extract files to the root partition regardless of the current directory.
```

### Configuring compile options

- Reference: [Gentoo Handbook:AMD64 > Installation > Stage # Configuring compile options](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Configuring_compile_options)

Run `nano /mnt/gentoo/etc/portage/make.conf` and set the following options:

```bash
COMMON_FLAGS="-march=native -O2 -pipe"
MAKEOPTS="-j4"
ACCEPT_LICENSE="*"
```

---

## Installing the Gentoo base system

- Reference: [Gentoo Handbook:AMD64 > Installation > Base](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base)

### Chrooting

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Chrooting](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Chrooting)

#### Copy DNS info

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Copy DNS info](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Copy_DNS_info)

```bash
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```

#### Mounting the necessary filesystems

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Mounting the necessary filesystems](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Mounting_the_necessary_filesystems)

```bash
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
```

#### Entering the new environment

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Entering the new environment](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Entering_the_new_environment)

```bash
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) $PS1"
```

#### Preparing for a bootloader

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Preparing for a bootloader](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Preparing_for_a_bootloader)

> **⚠️ Note:**
> We mount `/dev/sda1` to `/efi` (not `/boot/efi`) because `installkernel` with the `systemd-boot` USE flag expects to copy the kernel and initramfs directly to `/efi/EFI/Linux/`.
> This ensures compatibility with systemd-boot's unified kernel layout. Do not mount `/dev/sda1` to `/boot/efi` in this setup.

```bash
mount /dev/sda1 /efi
```

### Configuring Portage

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Configuring Portage](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Configuring_Portage)

#### Installing a Gentoo ebuild repository snapshot from the web

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Installing a Gentoo ebuild repository snapshot from the web](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Installing_a_Gentoo_ebuild_repository_snapshot_from_the_web)

```bash
emerge-webrsync
```

#### Choosing the right profile

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Choosing the right profile](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Choosing_the_right_profile)

```bash
eselect profile list
eselect profile set default/linux/amd64/23.0/systemd
```

#### Optional: Configuring the USE variable

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Optional: Configuring the USE variable](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Optional:_Configuring_the_USE_variable)

Check your current active USE settings:

```bash
emerge --info | grep ^USE
```

Update your USE flags by running `nano /etc/portage/make.conf`:

```bash
# This is a highly opinionated example which you could and should tailor to your own needs
USE="
  bluetooth
  dist-kernel
  hyprland
  networkmanager
  pipewire
  systemd
  systemd-boot
  usb
  waybar
  wayland
  wifi
  wpa_supplicant
  X
  -alsa
  -gtk
  -kde
  -plasma
  -pulseaudio
"
```

Update your World set after setting your USE flags by running:

```bash
# Either: A)
# Rebuilds packages if any USE flag has changed, enabled or disabled, even if it
# doesn’t affect the build (e.g., new USE flags added by ebuild updates).
# Longform: emerge --ask --verbose --update --deep --newuse @world
emerge -avuDN @world

# Or: B)
# Rebuilds packages only if the effective USE flags changed, meaning the actual
# combination of enabled flags differs from the current install.
# Longform: emerge --ask --verbose --update --deep --changed-use @world
emerge -avuDC @world

# Clean up afterwards
emerge --ask --depclean
```

### Timezone

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Timezone](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Timezone)

```bash
ln -sf ../usr/share/zoneinfo/Europe/Berlin /etc/localtime
```

### Configure locales

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Configure locales](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Configure_locales)

#### Locale generation

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Locale generation](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Locale_generation)

Run `nano /etc/locale.gen` and set the following options:

```bash
en_US ISO-8859-1
en_US.UTF-8 UTF-8
de_DE ISO-8859-1
de_DE@euro ISO-8859-15
```

Save the file and run the locale generation:

```bash
locale-gen
```

#### Locale selection

- Reference: [Gentoo Handbook:AMD64 > Installation > Base # Locale selection](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Locale_selection)

```bash
eselect locale list
eselect locale set en_US.UTF-8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
```

---

## Configuring the Linux kernel

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel)

### Optional: Installing firmware and/or microcode

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel # Optional: Installing firmware and/or microcode](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Optional:_Installing_firmware_and.2For_microcode)

#### Firmware

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel # Firmware](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Firmware)

```bash
emerge --ask sys-kernel/linux-firmware sys-firmware/sof-firmware
```

### sys-kernel/installkernel

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel # sys-kernel/installkernel](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#sys-kernel.2Finstallkernel)

#### Bootloader

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel # Bootloader](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Bootloader)

##### systemd-boot

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel # systemd-boot](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#systemd-boot)

```bash
# Configure systemd-boot & bash-completion
cat << EOF > /etc/portage/package.use/systemd
sys-apps/systemd boot bash-completion
sys-kernel/installkernel systemd-boot
EOF

# Configure Initramfs with dracut
cat << EOF > /etc/portage/package.use/installkernel
sys-kernel/installkernel dracut
EOF

# Configure kernel command line
cat << EOF > /etc/kernel/cmdline
splash
EOF

# Install systemd and installkernel
emerge --ask sys-apps/systemd sys-kernel/installkernel
```

### Kernel configuration and compilation

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel # Kernel configuration and compilation](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Kernel_configuration_and_compilation)

#### Distribution kernels

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel # Distribution kernels](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Distribution_kernels)

##### Run systemd initial setup

- Reference: [Gentoo Handbook:AMD64 > Installation > System # systemd ](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#systemd_2)

Before emerging the kernel it is advised to run the initial systemd setup:

```bash
systemd-machine-id-setup
systemd-firstboot --prompt
# Enter `us` as system keymap name
systemctl preset-all --preset-mode=enable-only
```

##### Installing a distribution kernel

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel # Installing a distribution kernel](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Installing_a_distribution_kernel)

```bash
emerge --ask sys-kernel/gentoo-kernel
```

##### Upgrading and cleaning up

- Reference: [Gentoo Handbook:AMD64 > Installation > Kernel # Upgrading and cleaning up](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Upgrading_and_cleaning_up)

```bash
emerge --depclean
```

---

## Configuring the system

- Reference: [Gentoo Handbook:AMD64 > Installation > System # Configuring the system](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System)

### Filesystem information

- Reference: [Gentoo Handbook:AMD64 > Installation > System # Filesystem information](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Filesystem_information)

#### Partition labels and UUIDs

- Reference: [Gentoo Handbook:AMD64 > Installation > System # Partition labels and UUIDs](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Partition_labels_and_UUIDs)

Read the UUIDs of the partitions by running:

```bash
blkid
```

#### Creating the fstab file

- Reference: [Gentoo Handbook:AMD64 > Installation > System # Creating the fstab file](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Creating_the_fstab_file)

##### UEFI systems

- Reference: [Gentoo Handbook:AMD64 > Installation > System # UEFI systems](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#UEFI_systems)

Create the `/etc/fstab` file using UUIDs by running:

```bash
EFI_UUID=$(blkid -s UUID -o value /dev/sda1)
ROOT_UUID=$(blkid -s UUID -o value /dev/sda3)
cat << EOF > /etc/fstab
UUID=$EFI_UUID    /efi    vfat    umask=0077        0 2
/dev/sda2         none    swap    sw                0 0
UUID=$ROOT_UUID   /       ext4    defaults,noatime  0 1
EOF
```

### Networking Information

- Reference: [Gentoo Handbook:AMD64 > Installation > System # Networking Information](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Networking_information)

#### Hostname

- Reference: [Gentoo Handbook:AMD64 > Installation > System # Hostname](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Hostname)


```bash
echo gentoo-btw > /etc/hostname
```

#### Network

- Reference: [Gentoo Handbook:AMD64 > Installation > System # Network](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Network)

Instead of using DHCP, we are going to configure a static ip for our wired ethernet connection.

```bash
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

systemctl enable systemd-networkd systemd-resolved
```

#### The hosts file

- Reference: [Gentoo Handbook:AMD64 > Installation > System # The hosts file](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#The_hosts_file)

Run `nano /etc/hosts` and add your hostname

```bash
127.0.0.1   gentoo-btw localhost
::1         gentoo-btw localhost
```

### System information

- Reference: [Gentoo Handbook:AMD64 > Installation > System # System information](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#System_information)

#### Root password

- Reference: [Gentoo Handbook:AMD64 > Installation > System # Root password](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Root_password)

```bash
passwd
```

---

## Installing system tools

- Reference: [Gentoo Handbook:AMD64 > Installation > Tools](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools)

### Optional: Remote shell access

- Reference: [Gentoo Handbook:AMD64 > Installation > Tools # Optional: Remote shell access](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools#Optional:_Remote_shell_access)

#### systemd

- Reference: [Gentoo Handbook:AMD64 > Installation > Tools # systemd](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools#systemd_3)

> ⚠️ **Security Notice**
> The following setting temporarily allows root login via SSH using a password:

```bash
# Configure SSH
cat << EOF > /etc/ssh/sshd_config
PermitRootLogin yes
EOF

# Enable SSH
systemctl enable sshd
systemctl enable getty@tty1.service
```

- On your Client Machine: Generate (if necessary) SSH keys and copy over public key
```bash
ssh-keygen -t ed25519
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@<your_gentoo_ip>
```
- On your Gentoo Machine: Reconfigure SSH to reject password logins and only accept keys
```bash
cat << EOF > /etc/ssh/sshd_config
PermitRootLogin prohibit-password
EOF

systemctl restart sshd
```

### Optional: Shell completion

- Reference: [Gentoo Handbook:AMD64 > Installation > Tools # Optional: Shell completion](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools#Optional:_Shell_completion)

```bash
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
```

Install the bash completion tools:

```bash
emerge --ask app-shells/bash-completion
```

### Suggested: Time synchronization

- Reference: [Gentoo Handbook:AMD64 > Installation > Tools # Time synchronization](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools#Suggested:_Time_synchronization)

#### systemd

- Reference: [Gentoo Handbook:AMD64 > Installation > Tools # systemd](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools#systemd_4)

Use the default installed SNTP client `systemd-timesyncd`:

```bash
systemctl enable systemd-timesyncd.service
```

---

## Configuring the bootloader

- Reference: [Gentoo Handbook:AMD64 > Installation > Bootloader](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader)

### Alternative 1: systemd-boot

- Reference: [Gentoo Handbook:AMD64 > Installation > Bootloader # Alternative 1: systemd-boot](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader#Alternative_1:_systemd-boot)

#### Emerge

- Reference: [Gentoo Handbook:AMD64 > Installation > Bootloader # Emerge](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader#Emerge_2)

```bash
cat << EOF > /etc/portage/package.use/systemd-boot
sys-apps/systemd boot
sys-apps/systemd-utils boot
EOF
```

#### Installation

- Reference: [Gentoo Handbook:AMD64 > Installation > Bootloader # Installation](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader#Installation)

- Install the systemd-boot loader to the EFI System partition:
```bash
bootctl install
```

- Verify that bootable entries exist:
```bash
bootctl list
```

### Rebooting the system

- Reference: [Gentoo Handbook:AMD64 > Installation > Bootloader # Rebooting the system](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader#Rebooting_the_system)

```bash
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot
```

---

## Finalizing

- Reference: [Gentoo Handbook:AMD64 > Installation > Finalizing](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing)

### User administration

- Reference: [Gentoo Handbook:AMD64 > Installation > Finalizing # User administration](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing#User_administration)

#### Adding a user for daily use

- Reference: [Gentoo Handbook:AMD64 > Installation > Finalizing # Adding a user for daily use](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing#Adding_a_user_for_daily_use)

```bash
# Login as `root` first (only `root` can create users)
useradd -m -G users,wheel,audio,usb,video -s /bin/bash dope
passwd dope
```

#### Install sudo and allow wheel group as sudoer

```bash
emerge --ask app-admin/sudo

visudo

# Uncomment the wheel line
%wheel ALL=(ALL:ALL) ALL
```

### Further system tools

#### Install fastfetch

- Reference: [Gentoo Wiki > Fastfetch](https://wiki.gentoo.org/wiki/Fastfetch)

```bash
emerge --ask app-misc/fastfetch
```

#### Install git

- Reference: [Gentoo Wiki > Git](https://wiki.gentoo.org/wiki/Git)

```bash
emerge --ask dev-vcs/git
```

#### Install neovim

- Reference: [Gentoo Wiki > Neovim](https://wiki.gentoo.org/wiki/Neovim)

```bash
emerge --ask app-editors/neovim
```

### Further developer tools

#### Install golang

- Reference: [Gentoo Wiki > Go](https://wiki.gentoo.org/wiki/Go)

```bash
emerge --ask dev-lang/go
```

---
