#!/usr/bin/env sh
set -o errexit
set -o pipefail
HD="/dev/sda"
BOOT_MOUNT="/mnt/esp"

function _chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

function iniciar(){
    clear
    umount -R -l /mnt || /bin/true
    vgremove -f vg1 || /bin/true
    wipefs -af ${HD} || /bin/true
    timedatectl set-ntp true
    pacman -Sy reflector tree --needed --noconfirm
    reflector --country Brazil --verbose --latest 3 --sort rate --save /etc/pacman.d/mirrorlist
}

function criar_volume_fisico(){
    parted -s ${HD} mklabel gpt 
    parted -s ${HD} mkpart ESP fat32 1MiB 513MiB
    parted -s ${HD} set 1 boot on 
    parted -s ${HD} mkpart primary ext4 513MiB 100%
    parted -s ${HD} set 2 lvm on
    pvcreate -f "${HD}2" 
    vgcreate vg1 "${HD}2" 
    lvcreate -K -L 50G -n root vg1
}

function formatar_volume(){
    mkfs.vfat -F32 "${HD}1" -n BOOT
    mkfs.ext4 -F -L ROOT /dev/mapper/vg1-root
}

function montar_volume(){
    mount /dev/mapper/vg1-root /mnt 
    mkdir -p "/mnt${BOOT_MOUNT}"
    mount "${HD}1" "/mnt${BOOT_MOUNT}"
    mkdir -p "/mnt${BOOT_MOUNT}/EFI/arch"
    mkdir -p /mnt/boot
    mount --bind "/mnt${BOOT_MOUNT}/EFI/arch" /mnt/boot
    lsblk ${HD}
}

function instalar_sistema(){
    pacstrap /mnt base base-devel intel-ucode
    genfstab -U -L /mnt >> /mnt/etc/fstab 
    _chroot "sed -i '/multilib]/,+1  s/^#//' /etc/pacman.conf"
    _chroot "echo root:root | chpasswd"
}

function instalar_systemd_boot(){
    echo "Instalando o bootloader."
    local loader="timeout 0\ndefault arch"
    local arch_entrie="title Arch Linux\\nlinux /EFI/arch/vmlinuz-linux\\n\\ninitrd  /EFI/arch/intel-ucode.img\\ninitrd /EFI/arch/initramfs-linux.img\\noptions root=/dev/mapper/vg1-root rw"
    local arch_rescue="title Arch Linux (Rescue)\\nlinux /EFI/arch/vmlinuz-linux\\n\\ninitrd  /EFI/arch/intel-ucode.img\\ninitrd /EFI/arch/initramfs-linux.img\\noptions root=/dev/mapper/vg1-root rw\\nsystemd.unit=rescue.target"
    _chroot "bootctl --path=${BOOT_MOUNT} install"
    _chroot "echo -e \"${loader}\" > ${BOOT_MOUNT}/loader/loader.conf"
    _chroot "echo -e \"${arch_entrie}\" > ${BOOT_MOUNT}/loader/entries/arch.conf"
    _chroot "echo -e \"${arch_rescue}\" > ${BOOT_MOUNT}/loader/entries/arch-rescue.conf"
    _chroot "mkinitcpio -p linux"
}

# Funções
iniciar
criar_volume_fisico
formatar_volume
montar_volume
instalar_sistema
instalar_systemd_boot
echo "Sistema Instalado com Sucesso!"
tree /mnt/mnt
cat "/mnt${BOOT_MOUNT}/loader/loader.conf"
cat "/mnt${BOOT_MOUNT}/loader/entries/arch.conf"
cat "/mnt${BOOT_MOUNT}/loader/entries/arch-rescue.conf"
