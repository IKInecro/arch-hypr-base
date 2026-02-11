#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting Dual-Boot Base Validation...${NC}"

# 1. Check ARCH_ROOT
ROOT_LABEL=$(lsblk -dno LABEL $(findmnt -nvo SOURCE /))
if [[ "$ROOT_LABEL" == "ARCH_ROOT" ]]; then
    echo "[PASS] Root partition label is ARCH_ROOT."
else
    echo -e "${RED}[FAIL] Root partition label is '$ROOT_LABEL', expected 'ARCH_ROOT'.${NC}"
fi

# 2. Check Windows Existence
if [[ -d "/boot/efi/EFI/Microsoft" ]]; then
    echo "[PASS] Windows Boot Manager detected in EFI."
else
    echo -e "${RED}[FAIL] Windows Boot Manager NOT found in /boot/efi/EFI/Microsoft.${NC}"
fi

# 3. Check GRUB os-prober
if grep -q "Windows Boot Manager" /boot/grub/grub.cfg 2>/dev/null; then
    echo "[PASS] Windows entry found in GRUB config."
else
    echo -e "${RED}[FAIL] Windows NOT found in GRUB config. Run 'grub-mkconfig' with os-prober enabled.${NC}"
fi

# 4. Check Contract
if [[ -f "/etc/hypr-base.conf" ]]; then
    source /etc/hypr-base.conf
    [[ "$DUAL_BOOT_SAFE" == "1" ]] && echo "[PASS] Dual-boot safety contract signed."
fi

# 5. Check PipeWire (User level check might be limited here)
pacman -Qi pipewire &>/dev/null && echo "[PASS] PipeWire package installed."

echo -e "${GREEN}Validation Complete.${NC}"
