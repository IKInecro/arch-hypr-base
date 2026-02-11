#!/bin/bash

CONTRACT_FILE="/etc/hypr-base.conf"

echo "Checking Hyprland Base Installation..."

if [[ -f "$CONTRACT_FILE" ]]; then
    echo "[PASS] Contract file found."
    source "$CONTRACT_FILE"
    [[ "$HYPR_BASE_INSTALLED" == "1" ]] && echo "[PASS] HYPR_BASE_INSTALLED=1" || echo "[FAIL] HYPR_BASE_INSTALLED invalid"
else
    echo "[FAIL] Contract file $CONTRACT_FILE not found."
fi

command -v hyprland &>/dev/null && echo "[PASS] Hyprland found." || echo "[FAIL] Hyprland NOT found."

systemctl is-active NetworkManager &>/dev/null && echo "[PASS] NetworkManager is active." || echo "[FAIL] NetworkManager is NOT active."

echo "Validation complete."
