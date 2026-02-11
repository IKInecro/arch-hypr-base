# Arch Hyprland Base (Dual-Boot Safe)

This repository provides a stable, reproducible infrastructure layer for Hyprland on Arch Linux, designed with strict safety rules for dual-booting with Windows.

## Dual Boot Safety Design

This installer is designed for systems where Windows is already present. It follows these strict rules:
1. **Reuse EFI**: It detects and reuses the existing Windows EFI partition. It **never** formats it.
2. **No Partitioning**: It expects an existing partition labeled `ARCH_ROOT` to be used as the root filesystem.
3. **GRUB Integration**: It uses `os-prober` to detect Windows and adds it to the GRUB boot menu automatically, while preserving the Windows Boot Manager.
4. **Idempotency**: Every step is safe to rerun.

## Installation Requirements

- **ARCH_ROOT**: Your Linux root partition must have the label `ARCH_ROOT`.
- **Windows EFI**: A partition containing `/EFI/Microsoft` must exist on the disk.
- **Internet**: Required for package installation and keyring updates.

## Usage

```bash
git clone https://github.com/IKInecro/arch-hypr-base.git
cd arch-hypr-base
sudo ./install.sh
```

## Repository Structure

- `install.sh`: The core dual-boot safe installation logic.
- `packages.txt`: Infrastructure package manifest including bootloader tools.
- `config/`: System configuration templates.
- `environment/`: Wayland session variables.
- `systemd-user/`: User-level service orchestration for PipeWire and Portals.
- `scripts/`: Validation tools for post-install checks.

## Integration with Celestia

Higher-level layers can verify environment readiness and dual-boot safety by reading `/etc/hypr-base.conf`:

```bash
source /etc/hypr-base.conf
if [[ $DUAL_BOOT_SAFE -eq 1 ]]; then
    # Proceed with UI customization
fi
```

## Logging

Full details of the installation process are logged to `/var/log/hypr-base-install.log`.
