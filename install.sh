#!/bin/bash

# Configuration
LOG_FILE="/mnt/var/log/hypr-base-install.log"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

msg() { echo -e "${GREEN}[*] ${1}${NC}"; }
err() { echo -e "${RED}[!] ${1}${NC}"; exit 1; }

# 1. VALIDATION
msg "Starting validation..."

# Detect ARCH_ROOT
ROOT_PART=$(blkid -L ARCH_ROOT)
if [ -z "$ROOT_PART" ]; then
    err "ARCH_ROOT partition not found. Please label your target partition as ARCH_ROOT."
fi
msg "Detected ARCH_ROOT: $ROOT_PART"

# Detect Windows EFI
EFI_PART=""
for part in $(lsblk -lno NAME,TYPE | grep part | awk '{print "/dev/"$1}'); do
    if mount "$part" /mnt_efi_check 2>/dev/null || mount "$part" /mnt 2>/dev/null; then
        MOUNT_POINT=$(findmnt -nvo TARGET "$part")
        if [ -d "$MOUNT_POINT/EFI/Microsoft" ]; then
            EFI_PART="$part"
            umount "$MOUNT_POINT"
            break
        fi
        umount "$MOUNT_POINT"
    fi
done

# Cleanup if mnt_efi_check was used
[ -d /mnt_efi_check ] && rmdir /mnt_efi_check

if [ -z "$EFI_PART" ]; then
    err "Windows EFI partition not found or does not contain 'Microsoft' folder."
fi
msg "Detected Windows EFI: $EFI_PART"

# 2. MOUNTING
msg "Mounting partitions..."
mount "$ROOT_PART" /mnt || err "Failed to mount ARCH_ROOT"
mkdir -p /mnt/boot/efi
mount "$EFI_PART" /mnt/boot/efi || err "Failed to mount EFI partition"

# Setup logging
mkdir -p /mnt/var/log
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

msg "Partitions mounted. Logging to $LOG_FILE"

# 3. BASE ARCH INSTALL
msg "Installing base system and packages..."
# Combine packages from packages.txt
PACKAGES=$(grep -v '^#' "$PACKAGES_FILE" | xargs)

pacstrap -K /mnt $PACKAGES || err "pacstrap failed"

msg "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Copy chroot script
mkdir -p /mnt/opt/arch-hypr
cp -r "$SCRIPT_DIR"/* /mnt/opt/arch-hypr/
chmod +x /mnt/opt/arch-hypr/scripts/chroot-setup.sh

# 4-7. CHROOT CONFIGURATION
msg "Entering chroot configuration..."
arch-chroot /mnt /opt/arch-hypr/scripts/chroot-setup.sh || err "Chroot configuration failed"

# 8. LOGGING & CLEANUP
msg "Finalizing installation..."
# The chroot script should have handled the contract and services

# 9. FINAL MESSAGE
msg "Installation complete. Reboot and login as JAWA."
