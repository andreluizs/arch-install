#!/usr/bin/env bash
#===============================================================================
#   DESCRIPTION: Script para realizar a instalação do Arch Linux.
#   AUTHOR: André Luiz dos Santos (andreluizs@live.com),
#   CREATED: 03/2018
#   LAST UPDATE: 06/2018
#   REVISION: 1.0.0b
#===============================================================================
set -o errexit
set -o pipefail
#===============================================================================
#---------------------------------VARIAVEIS-------------------------------------
#===============================================================================

# Cores
readonly VERMELHO='\e[31m\e[1m'
readonly VERDE='\e[32m\e[1m'
readonly AMARELO='\e[33m\e[1m'
readonly AZUL='\e[34m\e[1m'
readonly MAGENTA='\e[35m\e[1m'
readonly NEGRITO='\e[1m'
readonly SEMCOR='\e[0m'

# Usuário
MY_USER=${MY_USER:-'andre'}
MY_USER_NAME=${MY_USER_NAME:-'André Luiz dos Santos'}
MY_USER_PASSWD=${MY_USER_PASSWD:-'andre'}
ROOT_PASSWD=${ROOT_PASSWD:-'root'}

# HD
HD=${HD:-'/dev/sda'}

# Nome da maquina
HOST=${HOST:-"arch-note"}

# Tamanho das partições em MB
BOOT_SIZE=${BOOT_SIZE:-512}
SWAP_SIZE=${SWAP_SIZE:-4096}
ROOT_SIZE=${ROOT_SIZE:-102400}

# Configurações da Região
readonly KEYBOARD_LAYOUT="br abnt2"
readonly LANGUAGE="pt_BR"
readonly TIMEZONE="America/Sao_Paulo"
readonly NTP="NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org2.arch.pool.ntp.org 3.arch.pool.ntp.org
FallbackNTP=FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org"

# Video
readonly DISPLAY_SERVER="xorg-server xorg-xinit xorg-xprop xorg-xbacklight xorg-xdpyinfo xorg-xrandr"
readonly VGA_INTEL="mesa xf86-video-intel lib32-mesa vulkan-intel"
readonly VGA_VBOX="virtualbox-guest-utils virtualbox-guest-modules-arch"

#===============================================================================
#-----------------------------------PACOTES-------------------------------------
#===============================================================================
readonly PKG_EXTRA=("bash-completion" 
                    "zsh" 
                    "xdg-user-dirs" 
                    "vim"
                    "telegram-desktop" 
                    "p7zip" 
                    "zip" 
                    "unzip" 
                    "unrar" 
                    "wget" 
                    "numlockx"
                    "polkit"
                    "compton" 
                    "pamac-aur")

readonly PKG_AUDIO=("spotify" 
                    "playerctl" 
                    "pavucontrol")

readonly PKG_VIDEO=("mpv")

readonly PKG_REDE=("google-chrome" 
                   "network-manager-applet" 
                   "networkmanager-pptp" 
                   "remmina" 
                   "rdesktop" 
                   "remmina-plugin-rdesktop")

readonly PKG_DEV=("jdk8" 
                  "intellij-idea-ultimate-edition-jre" 
                  "intellij-idea-ultimate-edition"
                  "visual-studio-code-bin"
                  "virtualbox" 
                  "virtualbox-host-modules-arch" 
                  "linux-headers")

readonly PKG_THEME=("adapta-gtk-theme" 
                    "flat-remix-git"  
                    "pop-icon-theme-git" 
                    "papirus-icon-theme-git" 
                    "arc-gtk-theme-git" 
                    "bibata-cursor-theme"
                    "hardcode-tray-git" 
                    "gtk-engine-murrine" 
                    "lib32-gtk-engine-murrine"
                    "plank")

readonly PKG_FONT=("ttf-iosevka-term-ss09" 
                   "ttf-ubuntu-font-family" 
                   "ttf-font-awesome" 
                   "ttf-monoid" 
                   "ttf-fantasque-sans-mono" 
                   "ttf-ms-fonts")

readonly PKG_NOTE=("xf86-input-libinput")

#===============================================================================
#---------------------------DESKTOP ENVIRONMENT's-------------------------------
#===============================================================================

# XFCE
readonly DE_XFCE="xfce4 xfce4-goodies"
readonly DE_XFCE_EXTRA="file-roller xfce4-whiskermenu-plugin alacarte thunar-volman thunar-archive-plugin gvfs xfce4-dockbarx-plugin xfce-theme-greybird elementary-xfce-icons xfce-polkit-git"

# Plasma
readonly DE_KDE="plasma-meta sddm sddm-kcm"

# Deepin
readonly DE_DEEPIN="deepin deepin-extra"

# Cinnamon
readonly DE_CINNAMON="cinnamon cinnamon-translations"

#===============================================================================
#---------------------------WINDOW MANAGER's------------------------------------
#===============================================================================

# I3wm
readonly WM_I3="i3-gaps i3lock rofi mlocate dunst polybar nitrogen tty-clock lxappearance"

# Openbox
readonly WM_OPENBOX="openbox obconf openbox-themes obmenu lxappearance-obconf tint2"

#===============================================================================
#---------------------------DISPLAY MANAGER's-----------------------------------
#===============================================================================
readonly DM="lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings lightdm-slick-greeter lightdm-settings light-locker"
readonly SLICK_CONF="[Greeter]\\\nshow-a11y=false\\\nshow-keyboard=false\\\ndraw-grid=false\\\nbackground=/usr/share/backgrounds/xfce/xfce-blue.jpg\\\nactivate-numlock=true"


#===============================================================================
#-----------------------------------FUNÇÕES-------------------------------------
#===============================================================================

function _msg() {
    case $1 in
    info)       echo -e "${VERDE}->${SEMCOR} $2" ;;
    aten)       echo -e "${AMARELO}->${SEMCOR} $2" ;;
    erro)       echo -e "${VERMELHO}->${SEMCOR} $2" ;;
    quest)      echo -ne "${AZUL}->${SEMCOR} $2" ;;
    esac
}

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
        printf "${VERMELHO}[${SEMCOR}${AMARELO}%c${SEMCOR}${VERMELHO}]${SEMCOR}   " "${sp:i++%${#sp}:1}"
        sleep 0.75
        printf "\\b\\b\\b\\b\\b\\b"
    done
}

function bem_vindo() {
    echo -en "${NEGRITO}"
    echo -e "============================================================================"
    echo -e "              BEM VINDO AO INSTALADOR AUTOMÁTICO DO ARCH - UEFI             "
    echo -e "----------------------------------------------------------------------------"
    echo -e "                  André Luiz dos Santos (andreluizs@live.com)               "
    echo -e "                         Versão: 1.0.0b - Data: 03/2018                     "
    echo -e "----------------------------------------------------------------------------${SEMCOR}${MAGENTA}"
    echo -e "                  Esse instalador encontra-se em versão beta.              "
    echo -en "                 Usar esse instalador é por sua conta e risco.${SEMCOR}    "
}

function iniciar() {
    
    echo -e "${NEGRITO}"
    echo -e "================================= DEFAULT ==================================${SEMCOR}"
    echo -e "Nome: ${MAGENTA}${MY_USER_NAME}${SEMCOR}            User: ${MAGENTA}${MY_USER}${SEMCOR}        Maquina: ${MAGENTA}${HOST}${SEMCOR}       "
    echo -e "Device: ${MAGENTA}${HD}${SEMCOR}   /boot: ${MAGENTA}${BOOT_SIZE}MB${SEMCOR}    /root: ${MAGENTA}${ROOT_SIZE}MB${SEMCOR}    /home: ${MAGENTA}restante do HD${SEMCOR}"
    echo -e "============================================================================"
    echo -en "${SEMCOR}"

    echo -e "${AMARELO}Começando a instalação automatica!${SEMCOR}"
    
    # Hora
    _msg info 'Sincronizando a hora.'
    timedatectl set-ntp true
    
    # Mirror
    _msg info 'Procurando o servidor mais rápido.'
    pacman -Sy reflector --needed --noconfirm &> /dev/null
    reflector --country Brazil --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist &> /dev/null
}

function criar_volume_fisico(){
    local boot_start=1
    local boot_end=$((BOOT_SIZE + boot_start))

    _msg info "Definindo o device: ${HD} para GPT."
    parted -s "$HD" mklabel gpt 1> /dev/null

    _msg info "Criando a partição /boot com ${MAGENTA}${BOOT_SIZE}MB${SEMCOR}."
    parted "$HD" mkpart ESP fat32 "${boot_start}MiB" "${boot_end}MiB"
    parted "$HD" set 1 boot on &> /dev/null

    _msg info "Criando a partição: "${MAGENTA}${HD}2${SEMCOR}." como ${MAGENTA}lvm.${SEMCOR}."
    parted "$HD" mkpart primary ext4 "${boot_end}MiB" 100% 2> /dev/null
    parted -s "$HD" set 2 lvm on 1> /dev/null
    
    _msg info "Criando o volume físico: "${MAGENTA}${HD}2"${SEMCOR}."
    pvcreate "${HD}2" 1> /dev/null

    _msg info "Criando o grupo de volumes com o nome: ${MAGENTA}vg1${SEMCOR}."
    vgcreate vg1 "${HD}2" 1> /dev/null

    _msg info "Criando o volume /root com ${MAGENTA}50G${SEMCOR}."
    lvcreate -L 50G -n root vg1 1> /dev/null

    #_msg info "Criando o volume swap com ${MAGENTA}4G${SEMCOR}."
    #lvcreate -L 4G -n swap vg1

    _msg info "Criando o volume /home com o ${MAGENTA}restante do HD${SEMCOR}."
    lvcreate -l 100%FREE -n home vg1 &> /dev/null
}

function formatar_volume(){
    mkfs.vfat -F32 "${HD}1" -n BOOT 1> /dev/null
    mkfs.ext4 /dev/mapper/vg1-root 1> /dev/null
    mkfs.ext4 /dev/mapper/vg1-home 1> /dev/null
}

function montar_volume(){
    mount /dev/mapper/vg1-root /mnt 1> /dev/null
    mkdir -p /mnt/boot 1> /dev/null
    mkdir -p /mnt/home 1> /dev/null
    mount "${HD}1" /mnt/boot 1> /dev/null
    mount /dev/mapper/vg1-home /mnt/home 1> /dev/null

    echo -e "${AZUL}====================== TABELA ===================${SEMCOR}"
    lsblk "$HD"
    echo -e "${AZUL}=================================================${SEMCOR}"
}

function instalar_sistema() {

    (pacstrap /mnt base base-devel &> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o sistema base:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"

    _msg info "Gerando o fstab."
    genfstab -p -L /mnt >> /mnt/etc/fstab

}

function configurar_idioma(){
    _msg info 'Configurando o teclado e o idioma para pt_BR.'
    _chroot "echo -e \"KEYMAP=br-abnt2\\nFONT=\\nFONT_MAP=\" > /etc/vconsole.conf"
    _chroot "sed -i '/pt_BR/,+1 s/^#//' /etc/locale.gen"
    _chroot "locale-gen" 1> /dev/null
    _chroot "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
    _chroot "export LANG=pt_BR.UTF-8"
}

function configurar_hora(){
    _msg info "Configurando o horário para a região ${TIMEZONE}."
    _chroot "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
    _chroot "hwclock --systohc --localtime"
    _chroot "echo -e \"$NTP\" >> /etc/systemd/timesyncd.conf"
}

function criar_swapfile(){
    _msg info "Criando o swapfile com ${MAGENTA}${SWAP_SIZE}MB${SEMCOR}."
    _chroot "fallocate -l \"${SWAP_SIZE}M\" /swapfile" 1> /dev/null
    _chroot "chmod 600 /swapfile" 1> /dev/null
    _chroot "mkswap /swapfile" 1> /dev/null
    _chroot "swapon /swapfile" 1> /dev/null
    _chroot "echo -e /swapfile none swap defaults 0 0 >> /etc/fstab"
}

function configurar_pacman(){
    _msg info 'Habilitando o repositório multilib.'
    _chroot "sed -i '/multilib]/,+1  s/^#//' /etc/pacman.conf"
    
    _msg info 'Adicionando o servidor mais rápido.'
    _chroot "pacman -Sy reflector --needed --noconfirm" &> /dev/null
    _chroot "reflector --country Brazil --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist" &> /dev/null

    _msg info 'Atualizando o sistema.'
    _chroot "pacman -Syu --noconfirm" &> /dev/null

    _msg info 'Populando as chaves dos respositórios.'
    _chroot "pacman-key --init && pacman-key --populate archlinux" &> /dev/null
}

function criar_usuario(){
    _msg info "Criando o usuário ${MAGENTA}$MY_USER_NAME${SEMCOR}."
    _chroot "useradd -m -g users -G wheel -c \"$MY_USER_NAME\" -s /bin/bash $MY_USER"

    _msg info "Adicionando o usuario: ${MAGENTA}$MY_USER${SEMCOR} ao grupo sudoers."
    _chroot "sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers"

    _msg info "Definindo a senha do usuário ${MAGENTA}$MY_USER_NAME${SEMCOR}."
    _chroot "echo ${MY_USER}:${MY_USER_PASSWD} | chpasswd"

    _msg info "Definindo a senha do usuário ${MAGENTA}Root${SEMCOR}."
    _chroot "echo root:${ROOT_PASSWD} | chpasswd"

    _msg info "Configurando o nome da maquina para: ${MAGENTA}$HOST${SEMCOR}."
    _chroot "echo \"$HOST\" > /etc/hostname"
}

function instalar_rede(){
    (_chroot "pacman -S networkmanager --needed --noconfirm" 1> /dev/null
    _chroot "systemctl enable NetworkManager.service" 2> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o networkmanager:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_bootloader_refind(){
    local arch_entrie="\\\"Arch Linux\\\" \\\"rw root=${HD}2 quiet splash\\\""
    (_chroot "pacman -S refind-efi --needed --noconfirm" 1> /dev/null
    _chroot "refind-install --usedefault \"${HD}1\"" &> /dev/null
    _chroot "echo ${arch_entrie} > /boot/refind_linux.conf" &> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o rEFInd bootloader:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_bootloader_grub(){
    _msg info "Instalando o Grub bootloader"
    _chroot "pacman -S grub efibootmgr os-prober --needed --noconfirm" 1> /dev/null
    #_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB"
    _chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
     if [ "$(systemd-detect-virt)" != "none" ]; then
        _chroot "mkdir -p /boot/EFI/BOOT"
        _chroot "mv /boot/EFI/GRUB/grubx64.efi /boot/EFI/BOOT/bootx64.efi"
     fi
     # add o lvm2 ao hooks
     #_chroot "sed '/block/a lvm2' /etc/mkinitcpio.conf"

     # add o lvm no grub modules
     _chroot "grub-mkconfig -o /boot/grub/grub.cfg"
     _chroot "mkinitcpio -p linux"

}

function instalar_display_server(){
    (_chroot "pacman -S ${DISPLAY_SERVER} --needed --noconfirm" &> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o display server:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_video(){
     (
        if [ "$(systemd-detect-virt)" = "none" ]; then
            _chroot "pacman -S ${VGA_INTEL} --needed --noconfirm" &> /dev/null
        else
            _chroot "pacman -S ${VGA_VBOX} --needed --noconfirm" 1> /dev/null
        fi
    ) &
    _spinner "${VERDE}->${SEMCOR} Instalando o drive de video:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_gerenciador_aur(){
     (_chroot "pacman -S git --needed --noconfirm" &> /dev/null
    _chuser "cd /home/${MY_USER} && git clone https://aur.archlinux.org/trizen.git && 
             cd /home/${MY_USER}/trizen && makepkg -si --noconfirm && 
             rm -rf /home/${MY_USER}/trizen" &> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o Trizen:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_desktop_environment(){
     (_chuser "trizen -S ${DE_CINNAMON} --needed --noconfirm" &> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o desktop environment:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_window_manager(){
   (_chuser "trizen -S ${WM_I3} --needed --noconfirm" &> /dev/null) &
   _spinner "${VERDE}->${SEMCOR} Instalando o window manager:" $! 
   echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_display_manager(){
    (_chuser "trizen -S ${DM} --needed --noconfirm" &> /dev/null
    _chroot "sed -i '/^#greeter-session/c \greeter-session=slick-greeter' /etc/lightdm/lightdm.conf"
    _chroot "echo -e ${SLICK_CONF} > /etc/lightdm/slick-greeter.conf"
    _chroot "systemctl enable lightdm.service" &> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o display manager:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_som(){
    (_chroot "pacman -S alsa-utils alsa-oss alsa-lib pulseaudio --needed --noconfirm" &> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o pacote de audio:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function clonar_dotfiles(){
    (
        _chuser "cd /home/${MY_USER} && rm -rf .[^.] .??*" &> /dev/null
        _chuser "cd /home/${MY_USER} && git clone --bare https://github.com/andreluizs/dotfiles.git /home/${MY_USER}/.dotfiles" &> /dev/null
        _chuser "cd /home/${MY_USER} && /usr/bin/git --git-dir=/home/${MY_USER}/.dotfiles/ --work-tree=/home/${MY_USER} checkout" &> /dev/null
    ) &
    _spinner "${VERDE}->${SEMCOR} Clonando os dotfiles:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_pacotes_extras(){
     _msg info "${NEGRITO}Instalando pacotes extras:${SEMCOR}"
    for i in "${PKG_EXTRA[@]}"; do
        (_chuser "trizen -S ${i} --needed --noconfirm --quiet --noinfo" &> /dev/null) &
        _spinner "${VERDE}->${SEMCOR} Instalando o pacote ${i}:" $! 
        echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
    done 
    _chuser "xdg-user-dirs-update"
}

function instalar_pacotes_desenvolvedor(){
    _chroot "mount -o remount,size=4G,noatime /tmp"
    _msg info "${NEGRITO}Instalando aplicativos para desenvolvimento:${SEMCOR}"
    for i in "${PKG_DEV[@]}"; do
         (_chuser "trizen -S ${i} --needed --noconfirm --quiet --noinfo" &> /dev/null) &
        _spinner "${VERDE}->${SEMCOR} Instalando o pacote ${i}:" $! 
        echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
    done 
    _chroot "archlinux-java set java-8-jdk"
}

function configurar_sistema() {

    _msg info "${NEGRITO}Entrando no novo sistema.${SEMCOR}"
    configurar_idioma
    configurar_hora
    #criar_swapfile
    configurar_pacman
    criar_usuario
    instalar_rede
    #instalar_bootloader_refind
    instalar_bootloader_grub
    instalar_display_server
    instalar_video
    instalar_gerenciador_aur
    instalar_desktop_environment
    #instalar_window_manager
    instalar_display_manager
    
    if [ "$(systemd-detect-virt)" = "none" ]; then
        instalar_pacotes_extras
        instalar_pacotes_desenvolvedor
        clonar_dotfiles
    fi

    _msg info 'Sistema instalado com sucesso!'
    _msg erro 'Retire a midia do computador e logo em seguida reinicie a máquina.'
    umount -R /mnt &> /dev/null
}

# Chamada das Funções
clear
bem_vindo
iniciar
criar_volume_fisico
formatar_volume
montar_volume
instalar_sistema
configurar_sistema