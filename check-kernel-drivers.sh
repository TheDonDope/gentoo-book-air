#!/bin/bash

CONFIG_FILE=${1:-/usr/src/linux/.config}
LSPCI_TMP=$(mktemp)

echo "[+] Checking kernel config against lspci..."

# Capture lspci driver lines
lspci -k | awk '/Kernel modules:/ { print $3 }' | sort -u > "$LSPCI_TMP"

while read -r module; do
    # Skip empty lines
    [ -z "$module" ] && continue

    # Try to find a matching config option
    result=$(grep -i "CONFIG_.*${module^^}" "$CONFIG_FILE")

    if [[ -z "$result" ]]; then
        echo "❌ $module is not set in your .config"
    elif echo "$result" | grep -q "not set"; then
        echo "❌ $module is disabled: $result"
    else
        echo "✅ $module is enabled: $result"
    fi
done < "$LSPCI_TMP"

rm "$LSPCI_TMP"

