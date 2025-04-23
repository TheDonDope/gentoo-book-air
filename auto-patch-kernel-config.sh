#!/bin/bash

OUTPUT_FILE="$1"
CONFIG_FILE="$2"

if [[ ! -f "$OUTPUT_FILE" || ! -f "$CONFIG_FILE" ]]; then
  echo "Usage: $0 check-kernel-drivers-output.txt /path/to/.config"
  exit 1
fi

cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
echo "[+] Backup created: $CONFIG_FILE.bak"

while IFS= read -r line; do
  # Match lines that contain missing or disabled drivers
  if [[ "$line" =~ ^✘ ]]; then
    # Try to extract the CONFIG name
    if [[ "$line" =~ ([A-Z0-9_]+)[[:space:]]+is ]]; then
      CONFIG_NAME="${BASH_REMATCH[1]}"
      echo "[+] Enabling $CONFIG_NAME"

      if grep -q "^$CONFIG_NAME=" "$CONFIG_FILE"; then
        sed -i "s/^$CONFIG_NAME=.*/$CONFIG_NAME=y/" "$CONFIG_FILE"
      elif grep -q "^# $CONFIG_NAME is not set" "$CONFIG_FILE"; then
        sed -i "s/^# $CONFIG_NAME is not set/$CONFIG_NAME=y/" "$CONFIG_FILE"
      else
        echo "$CONFIG_NAME=y" >> "$CONFIG_FILE"
      fi
    fi
  fi
done < "$OUTPUT_FILE"

echo "✅ Done patching. You can now run 'make olddefconfig' or 'make menuconfig' to verify."

