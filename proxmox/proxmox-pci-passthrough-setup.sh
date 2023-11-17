#!/bin/bash

# Check CPU architecture (Intel or AMD)
cpu_arch=$(lscpu | grep "Architecture" | awk '{print $2}')

# Legacy Systems; Add IOMMU Support
if [[ "$cpu_arch" == "x86_64" ]]; then
    # Intel CPU
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"/g' /etc/default/grub
else
    # AMD CPU
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on"/g' /etc/default/grub
fi

update-grub

# EFI Boot Systems; Add IOMMU Support
sed -i 's/intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off/intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off/g' /etc/kernel/cmdline

proxmox-boot-tool refresh

# Load VFIO modules at boot
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_virqfd" >> /etc/modules

# Blacklist graphic drivers (optional)
echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf

echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf

# Apply all changes
update-initramfs -u -k all

# Reboot
systemctl reboot
