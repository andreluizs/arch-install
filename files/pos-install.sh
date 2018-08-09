#!/usr/bin/env sh 

set -o errexit
set -o pipefail

MY_USER="andre"
MY_USER_NAME="André"
HOST="arch-dsk"
readonly PACOTES=(
    "bash-completion" "xdg-user-dirs" "vim" "telegram-desktop" "p7zip" 
    "zip" "unzip" "unrar" "wget" "numlockx" "polkit" "polkit-gnome" "compton" "pamac-aur" 
    "google-chrome" "alsa-utils" "alsa-oss" "alsa-lib" "pulseaudio" "spotify" 
    "playerctl" "pavucontrol" "xorg-server" "xorg-xinit" "xorg-xprop" "xorg-xbacklight" 
    "xorg-xdpyinfo" "xorg-xrandr" "xf86-video-intel" "vulkan-intel" "networkmanager"
    "network-manager-applet" "networkmanager-pptp" "remmina" "rdesktop" 
    "remmina-plugin-rdesktop" "ufw" "xf86-input-libinput" "lightdm" 
    "lightdm-gtk-greeter" "lightdm-gtk-greeter-settings" "light-locker" "i3-gaps" 
    "i3lock" "rofi" "mlocate" "dunst" "polybar" "nitrogen" "tty-clock" "lxappearance"
    "ranger" "termite" "gtk-engine-murrine" "lib32-gtk-engine-murrine" "hardcode-tray-git" 
    "ttf-font-awesome" "ttf-dejavu ttf-liberation noto-fonts" "maim" "xclip" "visual-studio-code-bin"
    "snap-pac")
    
function configurar_idioma(){
    echo -e "KEYMAP=br-abnt2\nFONT=\nFONT_MAP=" > /etc/vconsole.conf
    sed -i '/pt_BR/,+1 s/^#//' /etc/locale.gen
    locale-gen
    echo LANG=pt_BR.UTF-8 > /etc/locale.conf
    export LANG=pt_BR.UTF-8
    localectl set-x11-keymap br abnt2
    timedatectl set-timezone America/Sao_Paulo
    timedatectl set-ntp true
}

function configurar_usuario(){
    useradd -m -g users -G wheel -c "${MY_USER_NAME}" -s /bin/bash $MY_USER
    echo ${MY_USER}:${MY_USER} | chpasswd
    sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers
    hostnamectl set-hostname ${HOST}
}

function instalar_aur_helper(){
    pacman -S git --needed --noconfirm
    su -c ${MY_USER} "git clone https://aur.archlinux.org/yay.git"
    cd yay
    su -c ${MY_USER} "makepkg -si"
    rm -rf yay
}

function instalar_pacote(){
    for i in "${PACOTES[@]}"; do
        su ${MY_USER} -c "yay -S ${i} --needed --noconfirm"
    done 
}

function clonar_dotfiles(){
    su -c ${MY_USER} "cd /home/${MY_USER} && rm -rf .[^.] .??*" &> /dev/null
    su -c ${MY_USER} "cd /home/${MY_USER} && git clone --bare https://github.com/andreluizs/dotfiles.git /home/${MY_USER}/.dotfiles" 
    su -c ${MY_USER} "cd /home/${MY_USER} && /usr/bin/git --git-dir=/home/${MY_USER}/.dotfiles/ --work-tree=/home/${MY_USER} checkout"
}

function configurar_mirror_list(){
    clear
    echo "+------------------ ARCH - POS -----------------+"
    echo "+ Configurando mirrors."
    pacman -Sy reflector --needed --noconfirm &> /dev/null
    reflector --country Brazil --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist &> /dev/null
}

function configurar_snapper(){
    echo "+ Configurando snnaper"
    _chroot "snapper -c root create-config /"
    _chroot "snapper -c home create-config /home"
    _chroot "sed -i 's/TIMELINE_CREATE=\"yes\"/TIMELINE_CREATE=\"no\"/' /etc/snapper/configs/root"
    _chroot "sed -i 's/TIMELINE_CREATE=\"yes\"/TIMELINE_CREATE=\"no\"/' /etc/snapper/configs/home"
}

cd /tmp
configurar_mirror_list
instalar_aur_helper
configurar_usuario
clonar_dotfiles
configurar_idioma
instalar_pacote
configurar_snapper
