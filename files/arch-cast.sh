#!/usr/bin/env sh 

set -o errexit
set -o pipefail

MY_USER="andre"
MY_USER_NAME="André Luiz dos Santos"
SSD="/dev/sda"
HOST="aranot072"

function _chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

function _chuser() {
    _chroot "su ${MY_USER} -c \"$1\""
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
    echo "+------------------ ARCH - CAST ----------------+"
    umount -R /mnt &> /dev/null || /bin/true
    wipefs -af "${SSD}4" &> /dev/null
    mkfs.ext4 -F -L ROOT "${SSD}4" &> /dev/null
}

function montar_disco(){
    echo "+ Montando as partições."
    mount "${SSD}4" /mnt
    mkdir -p /mnt/boot
    mount "${SSD}1" /mnt/boot
    echo "+------------------- TABELA --------------------+"
    lsblk ${SSD} -o name,size,mountpoint
    echo "+-----------------------------------------------+"
}

function instalar_sistema(){
    (pacstrap /mnt base base-devel intel-ucode networkmanager bash-completion &> /dev/null) &
    _spinner "+ Instalando o sistema:" $! 
    echo -ne "[100%]\\n"

    echo "+ Gerando fstab."
    genfstab -t PARTUUID -p /mnt >> /mnt/etc/fstab 
    
    _chroot "sed -i '/multilib]/,+1  s/^#//' /etc/pacman.conf"
}

function instalar_systemd_boot(){
    echo "+ Instalando o bootloader."
    local loader="timeout 3\ndefault arch"
    local arch_entrie="title Arch Linux\\nlinux /vmlinuz-linux\\n\\ninitrd  /intel-ucode.img\\ninitrd /initramfs-linux.img\\noptions root=${SSD}4 rw"
    local arch_rescue="title Arch Linux (Rescue)\\nlinux /vmlinuz-linux\\n\\ninitrd  /intel-ucode.img\\ninitrd /initramfs-linux.img\\noptions root=${SSD}4 rw systemd.unit=rescue.target"
    local boot_hook="[Trigger]\\nType = Package\\nOperation = Upgrade\\nTarget = systemd\\n\\n[Action]\\nDescription = Updating systemd-boot\\nWhen = PostTransaction\\nExec = /usr/bin/bootctl --path=/boot update"

    _chroot "bootctl --path=/boot install"
    _chroot "echo -e \"${loader}\" > /boot/loader/loader.conf"
    _chroot "echo -e \"${arch_entrie}\" > /boot/loader/entries/arch.conf"
    _chroot "echo -e \"${arch_rescue}\" > /boot/loader/entries/arch-rescue.conf"
    _chroot "mkdir -p /etc/pacman.d/hooks"
    _chroot "echo -e \"${boot_hook}\" > /etc/pacman.d/hooks/systemd-boot.hook"
    _chroot "sed -i 's/^HOOKS.*/HOOKS=\"base udev autodetect modconf block filesystems keyboard\"/' /etc/mkinitcpio.conf"
    _chroot "mkinitcpio -p linux" 
}

function configurar_sistema(){
    echo "+ Configurando o idioma."
    _chroot "echo -e \"KEYMAP=br-abnt2\\nFONT=\\nFONT_MAP=\" > /etc/vconsole.conf"
    _chroot "sed -i '/pt_BR/,+1 s/^#//' /etc/locale.gen"
    _chroot "locale-gen" 1> /dev/null
    _chroot "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
    _chroot "export LANG=pt_BR.UTF-8"

    echo "+ Criando o usuário."
    _chroot "useradd -m -g users -G wheel -c \"${MY_USER_NAME}\" -s /bin/bash $MY_USER"
    _chroot "echo ${MY_USER}:${MY_USER} | chpasswd"
    _chroot "echo root:${MY_USER} | chpasswd"
    _chroot "sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers"
    _chroot "echo \"$HOST\" > /etc/hostname"
}

iniciar
montar_disco
instalar_sistema
instalar_systemd_boot
configurar_sistema
echo "Sistema instalado com sucesso!"
umount -R /mnt &> /dev/null || /bin/true