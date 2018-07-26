#!/usr/bin/env sh
set -o errexit
set -o pipefail
HD="/dev/sda"
BOOT_ISO="/mnt/mnt/esp"
BOOT_CHROOT="/mnt/esp"

function _spinner(){
    local pid=$2
    local i=1
    local param=$1
    local sp='/-\|'
    echo -ne "$param "
    while [ -d /proc/"${pid}" ]; do
        printf "[%c]   " "${sp:i++%${#sp}:1}"
        sleep 0.75
        printf "\\b\\b\\b\\b\\b\\b"
    done
}

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
    lvcreate -L 50G -n root vg1
}

function formatar_volume(){
    mkfs.vfat -F32 "${HD}1" -n BOOT
    mkfs -F -t ext4 -L ROOT /dev/mapper/vg1-root 
}

function montar_volume(){
    mount /dev/mapper/vg1-root /mnt 
    mkdir -p ${BOOT_ISO} 
    mount "${HD}1" ${BOOT_ISO}
    lsblk ${HD}
}

function instalar_sistema(){
    pacstrap /mnt base base-devel
    genfstab -U -L /mnt >> /mnt/etc/fstab 
    _chroot "sed -i '/multilib]/,+1  s/^#//' /etc/pacman.conf"
}

function instalar_systemd_boot(){
    echo "Instalando o bootloader."
    local loader="timeout 2\\\ndefault arch"
    local arch_entrie="title Arch Linux\\\nlinux /vmlinuz-linux\\\ninitrd /initramfs-linux.img\\\noptions root=/dev/mapper/vg1-root rw"
    _chroot "bootctl --path=${BOOT_CHROOT} install"
    _chroot "echo \"${loader}\" > ${BOOT_CHROOT}/loader/loader.conf"
    _chroot "echo \"${arch_entrie}\" > ${BOOT_CHROOT}/loader/entries/arch.conf"
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
cat /mnt/mnt/esp/loader/loader.conf
cat /mnt/mnt/esp/loader/entries/arch.conf
