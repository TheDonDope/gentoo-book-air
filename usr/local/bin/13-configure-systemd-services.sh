#!/usr/bin/env bash
set -euo pipefail

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