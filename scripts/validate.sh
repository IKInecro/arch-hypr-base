#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting Final Installation Validation...${NC}"

# 1. Check Root
if [[ $(lsblk -dno LABEL $(findmnt -nvo SOURCE /)) == "ARCH_ROOT" ]] || [ -d "/mnt/etc" ]; then
    echo "[PASS] Root partition identified."
else
    echo -e "${RED}[FAIL] Root partition not properly mounted or labeled.${NC}"
fi

# 2. Check Windows Existence
if [[ -d "/boot/efi/EFI/Microsoft" ]] || [[ -d "/mnt/boot/efi/EFI/Microsoft" ]]; then
    echo "[PASS] Windows Boot Manager detected."
else
    echo -e "${RED}[FAIL] Windows Boot Manager NOT found. Dual boot might fail.${NC}"
fi

# 3. Check GRUB config
GRUB_CFG="/boot/grub/grub.cfg"
[ -f "/mnt/boot/grub/grub.cfg" ] && GRUB_CFG="/mnt/boot/grub/grub.cfg"

if grep -qi "Windows" "$GRUB_CFG" 2>/dev/null; then
    echo "[PASS] Windows entry found in GRUB config."
else
    echo -e "${RED}[FAIL] Windows NOT found in GRUB config. os-prober might have failed.${NC}"
fi

# 4. Check Environment Contract
CONTRACT="/etc/hypr-base.conf"
[ -f "/mnt/etc/hypr-base.conf" ] && CONTRACT="/mnt/etc/hypr-base.conf"

if [[ -f "$CONTRACT" ]]; then
    echo "[PASS] Environment contract found at $CONTRACT."
    source "$CONTRACT"
    [[ "$HYPR_BASE_INSTALLED" == "1" ]] && echo "[CONFIRM] HYPR_BASE_INSTALLED=1"
    [[ "$INSTALL_STAGE" == "ISO_COMPLETE" ]] && echo "[CONFIRM] INSTALL_STAGE=ISO_COMPLETE"
else
    echo -e "${RED}[FAIL] Environment contract missing.${NC}"
fi

# 5. Check Essential Packages
if command -v hyprland &>/dev/null || [ -f "/mnt/usr/bin/hyprland" ]; then
    echo "[PASS] Hyprland core installed."
else
    echo -e "${RED}[FAIL] Hyprland core not found.${NC}"
fi

echo -e "${GREEN}Validation Complete.${NC}"
