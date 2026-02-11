#!/bin/bash

# Exit on error
set -e

msg() { echo -e "\e[1;32m[*] ${1}\e[0m"; }

# 4. CHROOT CONFIGURATION
msg "Configuring system settings (Timezone, Locale, Hostname)..."
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "arch-hypr" > /etc/hostname

# User Creation
USERNAME="JAWA"
PASSWORD="123"

msg "Configuring user $USERNAME..."
if ! id "$USERNAME" &>/dev/null; then
    useradd -m -G wheel -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
else
    msg "User $USERNAME already exists, skipping creation."
fi

# Sudo configuration
msg "Enabling sudo for wheel group..."
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# 5. ENABLING SERVICES
msg "Enabling system services..."
systemctl enable NetworkManager
systemctl enable sddm || msg "SDDM service not found, skipping."

# 6. DUAL BOOT GRUB INSTALL
msg "Configuring GRUB for dual boot..."
# Check if EFI is correctly mounted
if [ ! -d "/boot/efi/EFI" ]; then
    msg "EFI partition might not be mounted at /boot/efi. Attempting to fix..."
    # In some cases arch-chroot might need manual mount if it wasn't handled
    # But our install.sh mounts it to /mnt/boot/efi before chrooting.
fi

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH_HYPR --recheck

msg "Enabling os-prober in GRUB..."
if grep -q "GRUB_DISABLE_OS_PROBER" /etc/default/grub; then
    sed -i 's/.*GRUB_DISABLE_OS_PROBER.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
else
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
fi

msg "Generating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg

# Validate Windows entry
if grep -qi "Windows Boot Manager" /boot/grub/grub.cfg; then
    msg "Windows Boot Manager detected successfully."
else
    msg "WARNING: Windows Boot Manager NOT detected in grub.cfg. Ensure your EFI contains Microsoft/ folder."
fi

# 7. ENVIRONMENT CONTRACT
msg "Creating environment contract..."
cat <<EOF > /etc/hypr-base.conf
HYPR_BASE_INSTALLED=1
PIPEWIRE_READY=1
WAYLAND_READY=1
INSTALL_STAGE=ISO_COMPLETE
EOF

msg "Chroot configuration complete."
