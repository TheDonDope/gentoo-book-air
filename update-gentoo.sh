#!/usr/bin/env bash
set -euo pipefail

# 1. Sync the Portage tree
echo "[1/4] Syncing Portage tree..."
emerge --sync

# 2. Update world (including deep deps & USE changes)
echo "[2/4] Updating world set..."
emerge --ask --verbose --update --deep --newuse @world

# 3. Remove unused dependencies
echo "[3/4] Cleaning obsolete packages..."
emerge --ask --depclean

# 4. Review config file updates
echo "[4/4] Reviewing /etc config updates..."
etccheck() { if command -v etc-update &>/dev/null; then etc-update --automode -5; else dispatch-conf --quiet; fi }
etccheck

echo "Gentoo maintenance complete. Consider rebooting if critical libraries or system daemons were updated."
