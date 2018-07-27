#!/usr/bin/env sh
set -o errexit
set -o pipefail
HD="/dev/sda"
BOOT_MOUNT="/esp"

function _chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

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

function iniciar(){
    clear
    local mirrorlist="Server = http://br.mirror.archlinux-br.org/\$repo/os/\$arch\nServer = http://mirror.ufscar.br/archlinux/\$repo/os/\$arch"
    echo "+------------------ ARCH - USB -----------------+"
    echo "+ Formatando o disco."
    umount "${HD}1" &> /dev/null || /bin/true
    umount "${HD}2" &> /dev/null || /bin/true
    umount -R /mnt &> /dev/null || /bin/true
    wipefs -af ${HD} &> /dev/null || /bin/true
    echo -e ${mirrorlist} > /etc/pacman.d/mirrorlist
    pacman -Sy tree --needed --noconfirm &> /dev/null
}

function particionar_disco(){
    echo "+ Criando as partições."
    parted -s ${HD} mklabel gpt 1> /dev/null
    parted -s ${HD} mkpart ESP fat32 1MiB 513MiB 1> /dev/null
    parted -s ${HD} set 1 boot on 1> /dev/null
    parted -s ${HD} mkpart primary ext4 513MiB 100% 1> /dev/null
}

function formatar_disco(){
    echo "+ Formatando as partições."
    mkfs.vfat -F32 "${HD}1" -n BOOT 1> /dev/null
    mkfs.f2fs -f -l ROOT "${HD}2" &> /dev/null
}

function montar_disco(){
    echo "+ Montando as partições."
    mount "${HD}2" /mnt
    mkdir -p "/mnt${BOOT_MOUNT}"
    mkdir -p /mnt/boot
    mount "${HD}1" "/mnt${BOOT_MOUNT}"
    mkdir -p "/mnt${BOOT_MOUNT}/EFI/arch"
    mount --bind "/mnt${BOOT_MOUNT}/EFI/arch" /mnt/boot
    echo "+------------------- TABELA --------------------+"
    lsblk ${HD} -o name,size,mountpoint
    echo "+-----------------------------------------------+"
}

function instalar_sistema(){
    (pacstrap /mnt base base-devel intel-ucode tree networkmanager &> /dev/null) &
    _spinner "+ Instalando o sistema:" $! 
    echo -ne "[100%]\\n"
    genfstab -U /mnt >> /mnt/etc/fstab 
    _chroot "sed -i '/multilib]/,+1  s/^#//' /etc/pacman.conf"
    _chroot "echo root:root | chpasswd"
}

function instalar_systemd_boot(){
    echo "+ Instalando o bootloader."
    local uuid=$(blkid -o value -s UUID "${HD}2")
    local loader="timeout 0\ndefault arch"
    local arch_entrie="title Arch Linux\\nlinux /EFI/arch/vmlinuz-linux\\n\\ninitrd  /EFI/arch/intel-ucode.img\\ninitrd /EFI/arch/initramfs-linux.img\\noptions root=UUID=${uuid} rw"
    local arch_rescue="title Arch Linux (Rescue)\\nlinux /EFI/arch/vmlinuz-linux\\n\\ninitrd  /EFI/arch/intel-ucode.img\\ninitrd /EFI/arch/initramfs-linux.img\\noptions root=UUID=${uuid} rw systemd.unit=rescue.target"
    local boot_hook="[Trigger]\\nType = Package\\nOperation = Upgrade\\nTarget = systemd\\n\\n[Action]\\nDescription = Updating systemd-boot\\nWhen = PostTransaction\\nExec = /usr/bin/bootctl --path=${BOOT_MOUNT} update"
    
    _chroot "bootctl --path=${BOOT_MOUNT} install" &> /dev/null
    _chroot "echo -e \"${loader}\" > ${BOOT_MOUNT}/loader/loader.conf"
    _chroot "echo -e \"${arch_entrie}\" > ${BOOT_MOUNT}/loader/entries/arch.conf"
    _chroot "echo -e \"${arch_rescue}\" > ${BOOT_MOUNT}/loader/entries/arch-rescue.conf"
    _chroot "mkdir -p /etc/pacman.d/hooks"
    _chroot "echo -e \"${boot_hook}\" > /etc/pacman.d/hooks/systemd-boot.hook"
    _chroot "sed -i 's/^HOOKS.*/HOOKS=\"base udev block autodetect modconf filesystems keyboard\"/' /etc/mkinitcpio.conf"
    _chroot "mkinitcpio -p linux" &> /dev/null
}

# Funções
iniciar
particionar_disco
formatar_disco
montar_disco
instalar_sistema
instalar_systemd_boot
tree /mnt/esp
echo
echo "+-------------------- loader.conf ---------------------+"
cat "/mnt${BOOT_MOUNT}/loader/loader.conf"
echo "+-------------------- arch.conf -----------------------+"
cat "/mnt${BOOT_MOUNT}/loader/entries/arch.conf"
echo "+----------------- arch-rescue.conf -------------------+"
cat "/mnt${BOOT_MOUNT}/loader/entries/arch-rescue.conf"
echo "+---------------- systemd-boot.hook -------------------+"
cat /mnt/etc/pacman.d/hooks/systemd-boot.hook
echo "+ Sistema Instalado com Sucesso!"
echo 