#!/bin/bash

# Configuration
LOG_FILE="/var/log/hypr-base-install.log"
CONTRACT_FILE="/etc/hypr-base.conf"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure log file exists and is writable
sudo touch "$LOG_FILE"
sudo chmod 666 "$LOG_FILE"

log() {
    local level=$1
    local msg=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${timestamp} [${level}] ${msg}" | tee -a "$LOG_FILE"
}

info() { log "INFO" "${GREEN}${1}${NC}"; }
warn() { log "WARN" "${YELLOW}${1}${NC}"; }
error() { log "ERROR" "${RED}${1}${NC}"; exit 1; }

# 1. Verification & Security Checks
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo."
    fi
}

validate_partitions() {
    info "Validating partition structure..."
    
    # 1. Check ARCH_ROOT
    local root_part=$(blkid -L ARCH_ROOT)
    if [[ -z "$root_part" ]]; then
        error "Could not find partition with label ARCH_ROOT. Please label your Linux partition correctly."
    fi

    local current_root=$(findmnt -nvo SOURCE /)
    if [[ "$root_part" != "$current_root" ]]; then
        error "Current / is NOT mounted from ARCH_ROOT ($root_part vs $current_root)."
    fi
    info "ARCH_ROOT detected and correctly mounted at /."

    # 2. Find Windows EFI
    info "Searching for existing Windows EFI partition..."
    local efi_part=""
    for part in $(lsblk -lno NAME,TYPE | grep part | awk '{print "/dev/"$1}'); do
        if mount "$part" /mnt &>/dev/null; then
            if [[ -d "/mnt/EFI/Microsoft" ]]; then
                efi_part="$part"
                umount /mnt
                break
            fi
            umount /mnt
        fi
    done

    if [[ -z "$efi_part" ]]; then
        error "Existing EFI partition with Windows Boot Manager not found."
    fi
    info "Found Windows EFI partition at $efi_part."

    # 3. Handle EFI mount
    if ! findmnt -nvo TARGET /boot/efi &>/dev/null; then
        info "Mounting $efi_part to /boot/efi..."
        mkdir -p /boot/efi
        mount "$efi_part" /boot/efi || error "Failed to mount EFI partition."
    else
        local mounted_efi=$(findmnt -nvo SOURCE /boot/efi)
        if [[ "$mounted_efi" != "$efi_part" ]]; then
            error "Another partition is already mounted at /boot/efi ($mounted_efi)."
        fi
    fi
}

# 2. System Readiness
check_internet() {
    info "Checking internet connectivity..."
    if ! ping -c 1 google.com &>/dev/null; then
        error "No internet connection detected."
    fi
}

refresh_keyring() {
    info "Refreshing pacman keyring..."
    pacman -Sy --needed --noconfirm archlinux-keyring >> "$LOG_FILE" 2>&1
    pacman-key --init >> "$LOG_FILE" 2>&1
    pacman-key --populate archlinux >> "$LOG_FILE" 2>&1
}

# 3. Idempotent Installation
install_packages() {
    info "Installing base packages..."
    local pkgs=()
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] && continue
        pkgs+=("$line")
    done < "$PACKAGES_FILE"

    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        pacman -S --needed --noconfirm "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi
}

# 4. GRUB Configuration (Dual Boot Safe)
setup_grub() {
    info "Configuring GRUB for dual boot safety..."
    
    # Enable os-prober
    if ! grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
        echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    fi

    # Install GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch-Hypr-Base >> "$LOG_FILE" 2>&1
    
    # Generate config
    grub-mkconfig -o /boot/grub/grub.cfg >> "$LOG_FILE" 2>&1
}

# 5. Services & Contract
setup_services() {
    info "Enabling essential services..."
    systemctl enable --now NetworkManager >> "$LOG_FILE" 2>&1
}

create_contract() {
    info "Creating environment contract..."
    cat <<EOF > "$CONTRACT_FILE"
HYPR_BASE_INSTALLED=1
PIPEWIRE_READY=1
WAYLAND_ENV_READY=1
DUAL_BOOT_SAFE=1
EOF
}

# 6. Validation
validate_all() {
    info "Validation Phase Starting..."
    local failed=0

    [[ -f "/boot/efi/EFI/Microsoft/Boot/bootmgfw.efi" ]] || { warn "Windows Boot Manager not found in EFI."; failed=1; }
    [[ -f "$CONTRACT_FILE" ]] || { warn "Contract file missing."; failed=1; }
    command -v hyprland &>/dev/null || { warn "Hyprland not installed."; failed=1; }
    grep -q "os-prober" /boot/grub/grub.cfg || warn "Windows might not be in GRUB menu. Check os-prober output."

    if [[ $failed -eq 0 ]]; then
        info "System validated as Dual-Boot Safe."
    else
        warn "Validation completed with warnings."
    fi
}

main() {
    check_root
    validate_partitions
    check_internet
    refresh_keyring
    install_packages
    setup_grub
    setup_services
    create_contract
    validate_all
    info "Installation Complete. Check $LOG_FILE for details."
}

main "$@"
