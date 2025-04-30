#!/usr/bin/env bash
set -euo pipefail

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