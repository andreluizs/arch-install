#!/usr/bin/env sh 

set -o errexit
set -o pipefail

SSD="/dev/sda"
HD="/dev/sdb"
MY_USER="andre"
MY_USER_NAME="André"
HOST="arch-dsk"

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
    echo "+------------------ ARCH - DSK -----------------+"
    umount -R /mnt &> /dev/null || /bin/true
    swapoff "${SSD}4" &> /dev/null || /bin/true
    timedatectl set-ntp true
    timedatectl set-timezone America/Sao_Paulo
    echo "+ Configurando mirrors."
    pacman -Sy tree reflector --needed --noconfirm &> /dev/null
    reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
}

function formatar_disco(){
    echo "+ Formatando as partições."
    wipefs -af "${SSD}5" &> /dev/null
    wipefs -af "${HD}2" &> /dev/null
    mkfs.btrfs -f -L ROOT "${SSD}5" &> /dev/null
    mkfs.btrfs -f -L HOME "${HD}2" &> /dev/null
    mkswap -L SWAP "${SSD}4" &> /dev/null
}

function montar_disco(){
    echo "+ Montando as partições."
    mount "${SSD}5" /mnt
    mkdir -p /mnt/mnt/esp
    mkdir -p /mnt/boot
    mount "${SSD}1" /mnt/mnt/esp
    mkdir -p /mnt/mnt/esp/EFI/arch
    mount --bind /mnt/mnt/esp/EFI/arch /mnt/boot
    mkdir -p /mnt/home
    mount "${HD}2" /mnt/home
    swapon "${SSD}4"
    echo "+------------------- TABELA --------------------+"
    lsblk ${SSD} -o name,size,mountpoint
    lsblk ${HD} -o name,size,mountpoint --noheadings
    echo "+-----------------------------------------------+"
}

function instalar_sistema(){
   
    (pacstrap /mnt base base-devel btrfs-progs snapper intel-ucode tree networkmanager bash-completion &> /dev/null) &
    _spinner "+ Instalando o sistema:" $! 
    echo -ne "[100%]\\n"

    echo "+ Gerando fstab."
    genfstab -t PARTUUID -p /mnt >> /mnt/etc/fstab 
    
    _chroot "sed -i 's|/mnt/mnt|/mnt|g' /etc/fstab"
    _chroot "sed -i '/multilib]/,+1  s/^#//' /etc/pacman.conf"
}

function instalar_systemd_boot(){
    echo "+ Instalando o bootloader."
    local loader="timeout 0\ndefault arch"
    local arch_entrie="title Arch Linux\\nlinux /EFI/arch/vmlinuz-linux\\n\\ninitrd  /EFI/arch/intel-ucode.img\\ninitrd /EFI/arch/initramfs-linux.img\\noptions root=${SSD}5 rw"
    local arch_rescue="title Arch Linux (Rescue)\\nlinux /EFI/arch/vmlinuz-linux\\n\\ninitrd  /EFI/arch/intel-ucode.img\\ninitrd /EFI/arch/initramfs-linux.img\\noptions root=${SSD}5 rw systemd.unit=rescue.target"
    local boot_hook="[Trigger]\\nType = Package\\nOperation = Upgrade\\nTarget = systemd\\n\\n[Action]\\nDescription = Updating systemd-boot\\nWhen = PostTransaction\\nExec = /usr/bin/bootctl --path=/mnt/esp update"
    
    _chroot "bootctl --path=/mnt/esp install" &> /dev/null
    _chroot "echo -e \"${loader}\" > /mnt/esp/loader/loader.conf"
    _chroot "echo -e \"${arch_entrie}\" > /mnt/esp/loader/entries/arch.conf"
    _chroot "echo -e \"${arch_rescue}\" > /mnt/esp/loader/entries/arch-rescue.conf"
    _chroot "mkdir -p /etc/pacman.d/hooks"
    _chroot "echo -e \"${boot_hook}\" > /etc/pacman.d/hooks/systemd-boot.hook"
    _chroot "sed -i 's/^HOOKS.*/HOOKS=\"base udev autodetect modconf block btrfs filesystems keyboard\"/' /etc/mkinitcpio.conf"
    _chroot "mkinitcpio -p linux"  &> /dev/null
}

function configurar_sistema(){
    echo "+ Configurando mirrors."
    _chroot "pacman -Sy reflector --needed --noconfirm" &> /dev/null
    _chroot "reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist"
    
    echo "+ Configurando o idioma."
    _chroot "echo -e \"KEYMAP=br-abnt2\\nFONT=\\nFONT_MAP=\" > /etc/vconsole.conf"
    _chroot "sed -i '/pt_BR/,+1 s/^#//' /etc/locale.gen"
    _chroot "locale-gen" 1> /dev/null
    _chroot "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
    _chroot "export LANG=pt_BR.UTF-8"
    _chroot "ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime"

    echo "+ Criando o usuário."
    _chroot "useradd -m -g users -G wheel -c \"${MY_USER_NAME}\" -s /bin/bash $MY_USER"
    _chroot "echo ${MY_USER}:${MY_USER} | chpasswd"
    _chroot "echo root:${MY_USER} | chpasswd"
    _chroot "sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers"
    _chroot "echo \"$HOST\" > /etc/hostname"

    echo "+ Instalando o yay."
    _chroot "pacman -S git --needed --noconfirm" &> /dev/null
    _chuser "mkdir -p /home/${MY_USER}/tmp"
    _chuser "cd /home/${MY_USER}/tmp && git clone https://aur.archlinux.org/yay.git" &> /dev/null
    _chuser "cd /home/${MY_USER}/tmp/yay && makepkg -si --noconfirm" &> /dev/null
    _chuser "rm -rf /home/${MY_USER}/tmp/yay"
    
}

iniciar
formatar_disco
montar_disco
instalar_sistema
instalar_systemd_boot
configurar_sistema
echo "Sistema instalado com sucesso!"
echo
tree /mnt/mnt/esp
echo
tree /mnt/boot
echo
cat /mnt/etc/fstab
umount -R /mnt &> /dev/null || /bin/true
swapoff "${SSD}4" &> /dev/null || /bin/true