#!/usr/bin/env bash
set -euo pipefail

# Choose systemd profile (e.g., 22)
eselect profile list
eselect profile set 22
emerge --ask --verbose --update --deep --changed-use @world
emerge --ask --pretend --depclean
emerge --ask --depclean