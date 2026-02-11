# Arch Hyprland Base Installer (Live ISO Edition)

This system is designed to perform a full Arch Linux installation with a Hyprland base environment, specifically targeted for systems with an existing Windows installation and a pre-prepared `ARCH_ROOT` partition.

## Prerequisites

1.  **Arch Linux Live ISO**: Boot into the latest Arch Linux Live media.
2.  **Partitions**:
    *   Target Linux partition must be labeled: `ARCH_ROOT`
    *   Windows EFI partition must already exist (containing `EFI/Microsoft`).
3.  **Internet**: Active internet connection is required.

## Installation Flow

1.  **Validation**: Detects `ARCH_ROOT` and Windows EFI.
2.  **Mounting**: Mounts partitions to `/mnt` and `/mnt/boot/efi`. No formatting is performed.
3.  **Base Install**: Runs `pacstrap` to install base system and essential packages.
4.  **Chroot Config**:
    *   Configure Timezone (Asia/Jakarta), Locale (en_US.UTF-8), and Hostname (arch-hypr).
    *   Create user `JAWA` (password: `123`).
    *   Configure sudo and enable system services.
5.  **Dual Boot**: Installs GRUB and enables `os-prober` to detect Windows.
6.  **Contract**: Creates `/etc/hypr-base.conf` to signal installation completion.

## Usage

```bash
chmod +x install.sh
sudo ./install.sh
```

## Logs

Detailed logs are stored at `/mnt/var/log/hypr-base-install.log`.

## Environment Contract

The file `/etc/hypr-base.conf` will contain:
```ini
HYPR_BASE_INSTALLED=1
PIPEWIRE_READY=1
WAYLAND_READY=1
INSTALL_STAGE=ISO_COMPLETE
```
