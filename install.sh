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

# HD
HD=${HD:-'/dev/sda'}

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


#===============================================================================
#-----------------------------------PACOTES-------------------------------------
#===============================================================================
readonly PKG_EXTRA=(
    "archlinux-wallpaper"
    "bash-completion" 
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
    "pamac-aur"
    "google-chrome")
readonly PKG_AUDIO=(
    "alsa-utils" 
    "alsa-oss" 
    "alsa-lib" 
    "pulseaudio"
    "spotify" 
    "playerctl" 
    "pavucontrol")
readonly PKG_VIDEO=("mpv")
readonly DISPLAY_SERVER=(
    "xorg-server" 
    "xorg-xinit" 
    "xorg-xprop" 
    "xorg-xbacklight" 
    "xorg-xdpyinfo" 
    "xorg-xrandr")
readonly VGA_INTEL=(
    "mesa" 
    "lib32-mesa" 
    "xf86-video-intel" 
    "vulkan-intel")
readonly VGA_VBOX=(
    "mesa" 
    "lib32-mesa"
    "virtualbox-guest-modules-arch")
readonly PKG_REDE=(
    "networkmanager"
    "network-manager-applet" 
    "networkmanager-pptp" 
    "remmina" 
    "rdesktop" 
    "remmina-plugin-rdesktop")
readonly PKG_DEV=(
    "jdk8" 
    "nodejs" 
    "docker" 
    "docker-compose"
    "intellij-idea-ultimate-edition-jre" 
    "intellij-idea-ultimate-edition" 
    "visual-studio-code-bin" 
    "virtualbox" 
    "virtualbox-host-modules-arch" 
    "linux-headers")
readonly PKG_THEME=(
    "adapta-gtk-theme" 
    "flat-remix-git"  
    "pop-icon-theme-git" 
    "papirus-icon-theme-git" 
    "arc-gtk-theme-git" 
    "bibata-cursor-theme"
    "hardcode-tray-git" 
    "gtk-engine-murrine" 
    "lib32-gtk-engine-murrine"
    "plank")
readonly PKG_FONT=(
    "ttf-iosevka-term-ss09" 
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
readonly DE_XFCE=(
    "xfce4" 
    "xfce4-goodies"
    "file-roller" 
    "xfce4-whiskermenu-plugin" 
    "alacarte" 
    "thunar-volman" 
    "thunar-archive-plugin" 
    "gvfs" 
    "xfce4-dockbarx-plugin" 
    "xfce-theme-greybird" 
    "elementary-xfce-icons" 
    "xfce-polkit-git")

# Plasma
readonly DE_KDE=(
    "plasma-meta" 
    "sddm" 
    "sddm-kcm")

# Deepin
readonly DE_DEEPIN=(
    "deepin" 
    "deepin-extra")

# Cinnamon
readonly DE_CINNAMON=(
    "cinnamon" 
    "cinnamon-translations")

# MATE
readonly DE_MATE=(
    "mate" 
    "mate-extra")

    # MATE
readonly DE_GNOME=(
    "gnome" 
    "gnome-extra"
    "gnome-tweak-tool")
readonly DE_OP=(
    [1]=${DE_CINNAMON}
    [2]=${DE_DEEPIN}
    [3]=${DE_GNOME}
    [4]=${DE_KDE}
    [5]=${DE_MATE}
    [6]=${DE_XFCE})
#===============================================================================
#---------------------------WINDOW MANAGER's------------------------------------
#===============================================================================

# I3wm
readonly WM_I3=(
    "i3-gaps" 
    "i3lock" 
    "rofi" 
    "mlocate" 
    "dunst" 
    "polybar" 
    "nitrogen" 
    "tty-clock" 
    "lxappearance")

# Openbox
readonly WM_OPENBOX=(
    "openbox" 
    "obconf" 
    "openbox-themes" 
    "obmenu" 
    "lxappearance-obconf" 
    "tint2")

#===============================================================================
#---------------------------DISPLAY MANAGER's-----------------------------------
#===============================================================================
readonly DM=(
    "lightdm" 
    "lightdm-gtk-greeter" 
    "lightdm-gtk-greeter-settings" 
    "lightdm-slick-greeter" 
    "lightdm-settings" 
    "light-locker")
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
    echo -e "                  Esse instalador encontra-se em versão beta.               "
    echo -e "                 Usar esse instalador é por sua conta e risco.${SEMCOR}     "
    echo -e "----------------------------------------------------------------------------"
}

function iniciar() {
    loadkeys br-abnt2
    echo -e "Esse processo irá ${NEGRITO}${VERMELHO}apagar${SEMCOR} todo o seu disco.${SEMCOR}"
    echo -en "Tem certeza que deseja continuar? [s/${NEGRITO}N${SEMCOR}]: "
    read -n 1 OP
    OP=${OP:-"N"}
    case $OP in
        (s|S)
            ler_informacoes_usuario
            echo -e "${AMARELO}Começando a instalação automática!${SEMCOR}"
            configuracao_inicial
            criar_volume_fisico
            formatar_volume
            montar_volume
            instalar_sistema
            configurar_sistema
        ;;
        (n|N) 
            echo -e "${NEGRITO}Instalação abortada!${SEMCOR}\n"; 
            exit 0 
        ;;
        (*) 
            echo -e "${NEGRITO}\nOpção inválida${SEMCOR}";
            sleep 3
            echo -e "${NEGRITO}Instalação abortada!${SEMCOR}\n"; 
            exit 0 
        ;;
    esac
}

function limpar_disco(){
    wipefs -a -f "${HD}"
}
    
function ler_informacoes_usuario(){
    echo -e "\n"
    echo -e "${AZUL}->${SEMCOR} ${NEGRITO}Antes de começar, preciso de algumas informações:${SEMCOR}"
    echo -en "${AZUL}->${SEMCOR} Qual seu nome completo?: "
    read MY_USER_NAME
    MY_USER_NAME=${MY_USER_NAME:-'André Luiz dos Santos'}
    
    echo -en "${AZUL}->${SEMCOR} Como gostaria que fosse seu usuário?: "
    read MY_USER
    MY_USER=${MY_USER:-'andre'}
    MY_USER_PASSWD=${MY_USER:-'andre'}
    ROOT_PASSWD=${MY_USER:-'andre'}

    echo -en "${AZUL}->${SEMCOR} Que nome gostaria de dar para seu PC?: "
    read HOST
    HOST=${HOST:-"arch-note"}

    ler_desktop_environment
    ler_window_manager

    echo -e "\n${AZUL}->${SEMCOR} Lembre-se de mudar a senha dos usuários: ${NEGRITO}(root e ${MY_USER})${SEMCOR}."
    echo -e "${AZUL}->${SEMCOR} Por padrão a senha é igual ao ${NEGRITO}User${SEMCOR}."
    
    echo -e "${NEGRITO}"
    echo -e "============================ INFORMAÇÕES DO USUÁRIO ========================${SEMCOR}"
    echo -e "Nome: ${MY_USER_NAME}"            
    echo -e "User: ${MY_USER}"                       
    echo -e "Maquina: ${HOST}"
    echo -e "Desktop Environment: KDE (Plasma)"
    echo -e "Window Manager: I3-Gaps"
    echo -e "Tipo de PC: Desktop"
    echo -e "${NEGRITO}============================================================================"
    echo -en "${SEMCOR}"    
}

function ler_desktop_environment(){
    echo -e "${AZUL}->${SEMCOR} Qual Desktop Environment gostaria de instalar?"
    echo -e "   [${NEGRITO}0${SEMCOR}] - Nenhum       [3] - Gnome             [6] - XFCE"
    echo -e "   [1] - Cinnamon     [4] - KDE (Plasma)      "
    echo -e "   [2] - Deepin DE    [5] - MATE              "
    echo -en "${AZUL}->${SEMCOR}  "
    read -n 1 DE
    DE=${DE:-0}
    if [[ $DE =~ [^0-6] ]]; then
        echo -e "${NEGRITO}\nOpção inválida${SEMCOR}";
        sleep 3
        echo -e "${NEGRITO}Instalação abortada!${SEMCOR}\n"; 
        exit 0 
    fi

}

function ler_window_manager(){
    echo -e "\n${AZUL}->${SEMCOR} Qual Window Manager gostaria de instalar?"
    echo -e "   [${NEGRITO}0${SEMCOR}] - Nenhum"
    echo -e "   [1] - i3-gaps"
    echo -e "   [2] - OpenBox"
    echo -en "${AZUL}->${SEMCOR}  "
    read -n 1 WM
    WM=${WM:-0}
    if [[ $WM =~ [^0-2] ]]; then
        echo -e "${NEGRITO}\nOpção inválida${SEMCOR}";
        sleep 3
        echo -e "${NEGRITO}Instalação abortada!${SEMCOR}\n"; 
        exit 0 
    fi

}

function configuracao_inicial(){
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

    _msg info "Apagando partições antigas."
    #limpar_disco
    
    _msg info "Definindo o device: ${HD} para GPT."
    parted -s "$HD" mklabel gpt 1> /dev/null

    _msg info "Criando a partição /boot com ${MAGENTA}${BOOT_SIZE}MB${SEMCOR}."
    parted "$HD" mkpart ESP fat32 "${boot_start}MiB" "${boot_end}MiB" &> /dev/null
    parted "$HD" set 1 boot on &> /dev/null

    _msg info "Criando a partição: "${MAGENTA}${HD}2${SEMCOR}" como ${MAGENTA}lvm${SEMCOR}."
    parted "$HD" mkpart primary ext4 "${boot_end}MiB" 100% &> /dev/null
    parted -s "$HD" set 2 lvm on &> /dev/null
    
    _msg info "Criando o volume físico: "${MAGENTA}${HD}2"${SEMCOR}."
    pvcreate "${HD}2" &> /dev/null

    _msg info "Criando o grupo de volumes com o nome: ${MAGENTA}vg1${SEMCOR}."
    vgcreate vg1 "${HD}2" &> /dev/null

    _msg info "Criando o volume /root com ${MAGENTA}${ROOT_SIZE}MB${SEMCOR}."
    lvcreate -L "${ROOT_SIZE}MiB" -n root vg1 &> /dev/null

    _msg info "Criando o volume swap com ${MAGENTA}4G${SEMCOR}."
    lvcreate -L "${SWAP_SIZE}MiB" -n swap vg1 &> /dev/null

    _msg info "Criando o volume /home com o ${MAGENTA}restante do HD${SEMCOR}."
    lvcreate -l 100%FREE -n home vg1 &> /dev/null
}

function formatar_volume(){
    mkfs.vfat -F32 "${HD}1" -n BOOT 1> /dev/null
    mkswap -L SWAP /dev/mapper/vg1-swap 1> /dev/null
    mkfs.ext4 /dev/mapper/vg1-root &> /dev/null
    mkfs.ext4 /dev/mapper/vg1-home &> /dev/null
}

function montar_volume(){
    mount /dev/mapper/vg1-root /mnt 1> /dev/null
    mkdir -p /mnt/boot 1> /dev/null
    swapon /dev/mapper/vg1-swap 1> /dev/null
    mkdir -p /mnt/home 1> /dev/null
    mount "${HD}1" /mnt/boot 1> /dev/null
    mount /dev/mapper/vg1-home /mnt/home 1> /dev/null

    echo -e "${AZUL}===================================== TABELA ===============================${SEMCOR}"
    lsblk "$HD"
    echo -e "${AZUL}============================================================================${SEMCOR}"
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
    _msg info "Configurando o horário para a região ${MAGENTA}${TIMEZONE}${SEMCOR}."
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

function instalar_gerenciador_aur(){
     (_chroot "pacman -S git --needed --noconfirm" &> /dev/null
    _chuser "cd /home/${MY_USER} && git clone https://aur.archlinux.org/trizen.git && 
             cd /home/${MY_USER}/trizen && makepkg -si --noconfirm && 
             rm -rf /home/${MY_USER}/trizen" &> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o AUR Helper:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
}

function instalar_pacote(){
    local pacotes=("$@")
    for i in "${pacotes[@]}"; do
        (_chuser "trizen -S ${i} --needed --noconfirm --quiet --noinfo" &> /dev/null) &
        _spinner "${VERDE}->${SEMCOR} Instalando o pacote ${i}:" $! 
        echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
    done 
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
    _chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB" &> /dev/null
    if [ "$(systemd-detect-virt)" != "none" ]; then
        _chroot "mkdir -p /boot/EFI/BOOT"
        _chroot "mv /boot/EFI/GRUB/grubx64.efi /boot/EFI/BOOT/bootx64.efi"
    fi
    _chroot "sed -i 's/^HOOKS.*/HOOKS=\"base udev autodetect modconf block lvm2 filesystems keyboard fsck\"/' /etc/mkinitcpio.conf"
    _chroot "sed -i 's/^GRUB_PRELOAD_MODULES.*/GRUB_PRELOAD_MODULES=\"part_gpt part_msdos lvm\"/' /etc/default/grub"
    _chroot "grub-mkconfig -o /boot/grub/grub.cfg" &> /dev/null
    _chroot "mkinitcpio -p linux" &> /dev/null

}

function instalar_desktop_environment(){
    _msg info "${NEGRITO}Instalando desktop environment:${SEMCOR}"
    instalar_pacote "${DE_OP[$DE][$@]}"
}

function instalar_window_manager(){
    _msg info "${NEGRITO}Instalando window manager:${SEMCOR}"
    instalar_pacote "$@"
}

function instalar_display_manager(){
    (_chuser "trizen -S ${DM} --needed --noconfirm" &> /dev/null
    _chroot "sed -i '/^#greeter-session/c \greeter-session=slick-greeter' /etc/lightdm/lightdm.conf"
    _chroot "echo -e ${SLICK_CONF} > /etc/lightdm/slick-greeter.conf"
    _chroot "systemctl enable lightdm.service" &> /dev/null) &
    _spinner "${VERDE}->${SEMCOR} Instalando o display manager:" $! 
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

function instalar_pacotes_audio(){
    _msg info "${NEGRITO}Instalando pacotes de audio:${SEMCOR}"
    instalar_pacote "${PKG_AUDIO[@]}"
}

function instalar_pacotes_video(){
    _msg info "${NEGRITO}Instalando pacotes de vídeo:${SEMCOR}"
    instalar_pacote "${DISPLAY_SERVER[@]}"
    if [ "$(systemd-detect-virt)" = "none" ]; then
        instalar_pacote "${VGA_INTEL[@]}"
    else
        instalar_pacote "${VGA_VBOX[@]}"
    fi
    instalar_pacote "${PKG_VIDEO[@]}"
}

function instalar_pacotes_rede(){
    _msg info "${NEGRITO}Instalando pacotes de rede:${SEMCOR}"
    instalar_pacote "${PKG_REDE[@]}"
    _chroot "systemctl enable NetworkManager.service" 2> /dev/null
}

function instalar_pacotes_fonte(){
    _msg info "${NEGRITO}Instalando fontes:${SEMCOR}"
    instalar_pacote "${PKG_FONT[@]}"
}

function instalar_pacotes_temas(){
    _msg info "${NEGRITO}Instalando temas:${SEMCOR}"
    instalar_pacote "${PKG_THEME[@]}"
}

function instalar_pacotes_desenvolvimento(){
    _chroot "mount -o remount,size=4G,noatime /tmp"
    _msg info "${NEGRITO}Instalando aplicativos para desenvolvimento:${SEMCOR}"
    instalar_pacote "${PKG_DEV[@]}"
    _chroot "archlinux-java set java-8-jdk"
}

function instalar_pacotes_diversos(){
    _msg info "${NEGRITO}Instalando pacotes extras:${SEMCOR}"
    instalar_pacote "${PKG_EXTRA[@]}"
    _chuser "xdg-user-dirs-update"
}

function configurar_sistema() {
    _msg info "${NEGRITO}Entrando no novo sistema.${SEMCOR}"
    configurar_idioma
    configurar_hora
    configurar_pacman
    criar_usuario
    instalar_gerenciador_aur
    instalar_desktop_environment
    instalar_pacotes_audio
    instalar_pacotes_video
    instalar_pacotes_rede
    #instalar_window_manager "${WM_I3[@]}"
    if [ "$(systemd-detect-virt)" = "none" ]; then
        instalar_pacotes_fonte
        instalar_pacotes_temas
        instalar_pacotes_desenvolvimento
        clonar_dotfiles
    fi
    instalar_display_manager
    #instalar_pacotes_diversos
    instalar_bootloader_grub

    _msg info "${VERDE}Sistema instalado com sucesso!${SEMCOR}"
    _msg aten "${AMARELO}Retire a midia do computador e logo em seguida reinicie a máquina.${SEMCOR}"
    umount -R /mnt &> /dev/null
}

# Chamada das Funções
clear
bem_vindo
iniciar
