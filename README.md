# Arch Hyprland Base

This repository provides a stable, reproducible, and idempotent infrastructure layer for Hyprland on Arch Linux.

## Purpose

The goal of this project is to prepare the system for a Wayland-based environment without applying any specific UI customizations or themes. It serves as a solid foundation ("Contract") for higher-level layers like Celestia.

## Features

- **Idempotent**: Safe to run multiple times without breaking the system.
- **Service Ordering**: Configures Systemd user services for PipeWire and Wayland portals to avoid race conditions.
- **Environment Contract**: Creates `/etc/hypr-base.conf` to signal system readiness.
- **Automated Fixes**: Automatically refreshes keyrings and fixes common permission issues.

## Usage

### Prerequisites

- A fresh or existing Arch Linux installation.
- Internet connectivity.

### Installation

```bash
git clone https://github.com/IKInecro/arch-hypr-base.git
cd arch-hypr-base
sudo ./install.sh
```

## Repository Structure

- `install.sh`: Main installation logic.
- `packages.txt`: List of essential packages.
- `config/`: Pre-configured infrastructure settings.
- `environment/`: Wayland and session environment variables.
- `systemd-user/`: Optimized Systemd user service units.
- `scripts/`: Helper scripts for maintenance and validation.

## Integration with Celestia

Layers like Celestia can verify the readiness of the system by checking for the existence and values of the contract file:

```bash
if [[ -f /etc/hypr-base.conf ]]; then
    source /etc/hypr-base.conf
    if [[ \$HYPR_BASE_INSTALLED -eq 1 ]]; then
        echo "Base environment is ready for UI customization."
    fi
fi
```

## Logging

Full installation logs are available at `/var/log/hypr-base-install.log`.
