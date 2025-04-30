#!/usr/bin/env bash
set -euo pipefail

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