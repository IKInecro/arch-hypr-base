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

# 1. Root Check
check_root() {
    info "Checking for root privileges..."
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo."
    fi
}

# 2. Internet Check
check_internet() {
    info "Checking internet connectivity..."
    if ! ping -c 1 google.com &>/dev/null; then
        error "No internet connection detected. Please check your network."
    fi
}

# 3. Refresh Pacman Keyring
refresh_keyring() {
    info "Refreshing pacman keyring..."
    pacman -Sy --needed --noconfirm archlinux-keyring >> "$LOG_FILE" 2>&1
    pacman-key --init >> "$LOG_FILE" 2>&1
    pacman-key --populate archlinux >> "$LOG_FILE" 2>&1
}

# 4. Install Missing Packages
install_packages() {
    info "Installing required packages..."
    if [[ ! -f "$PACKAGES_FILE" ]]; then
        error "Packages file not found at $PACKAGES_FILE"
    fi

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
        info "Installing: ${to_install[*]}"
        pacman -S --needed --noconfirm "${to_install[@]}" >> "$LOG_FILE" 2>&1
    else
        info "All packages are already installed."
    fi
}

# 5. Enable Services
setup_services() {
    info "Setting up system services..."
    local services=("NetworkManager")
    for svc in "${services[@]}"; do
        systemctl enable --now "$svc" >> "$LOG_FILE" 2>&1
    done
}

# 6. Create Environment Contract
create_contract() {
    info "Creating environment contract at $CONTRACT_FILE..."
    cat <<EOF > "$CONTRACT_FILE"
HYPR_BASE_INSTALLED=1
PIPEWIRE_READY=1
WAYLAND_ENV_READY=1
EOF
    chmod 644 "$CONTRACT_FILE"
}

# 7. Auto Fix Permissions
fix_permissions() {
    info "Fixing common permission issues..."
    # Ensure user is in necessary groups if they were just created (not applicable for root script usually, but good practice)
    # Most users should be in 'video' and 'audio'
    local real_user=${SUDO_USER:-$USER}
    if [[ "$real_user" != "root" ]]; then
        usermod -aG video,audio,input "$real_user" >> "$LOG_FILE" 2>&1
    fi
}

# 8. Validation Phase
validate_install() {
    info "Starting validation phase..."
    local failed=0

    # Check Hyprland
    if ! command -v hyprland &>/dev/null; then
        warn "Hyprland binary not found in PATH."
        failed=1
    fi

    # Check PipeWire
    if ! pacman -Qi pipewire &>/dev/null; then
        warn "PipeWire package is not installed."
        failed=1
    fi

    # Check Contract
    if [[ ! -f "$CONTRACT_FILE" ]]; then
        warn "Contract file missing."
        failed=1
    fi

    # Check Env Vars (Basic check if they would exist)
    if [[ ! -f "$SCRIPT_DIR/environment/wayland.conf" ]]; then
        warn "Environment configuration file missing."
        failed=1
    fi

    if [[ $failed -eq 0 ]]; then
        info "Installation validated successfully."
    else
        warn "Validation completed with warnings. Check the log for details."
    fi
}

# Main Execution
main() {
    info "Starting Hyprland Base Installation..."
    
    check_root
    check_internet
    refresh_keyring
    install_packages
    setup_services
    fix_permissions
    create_contract
    validate_install

    info "Installation finished. Log saved to $LOG_FILE"
}

main "$@"
