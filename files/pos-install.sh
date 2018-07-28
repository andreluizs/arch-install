#!/usr/bin/env sh
set -o errexit
set -o pipefail

MY_USER="andre"
MY_USER_NAME="André"
HOST="arch-dsk"
cd /tmp
readonly PACOTES=(
    "bash-completion" "xdg-user-dirs" "vim" "telegram-desktop" "p7zip" 
    "zip" "unzip" "unrar" "wget" "numlockx" "polkit" "compton" "pamac-aur" 
    "google-chrome" "alsa-utils" "alsa-oss" "alsa-lib" "pulseaudio" "spotify" 
    "playerctl" "pavucontrol" "xorg-server" "xorg-xinit" "xorg-xprop" "xorg-xbacklight" 
    "xorg-xdpyinfo" "xorg-xrandr" "xf86-video-intel" "vulkan-intel" "networkmanager"
    "network-manager-applet" "networkmanager-pptp" "remmina" "rdesktop" 
    "remmina-plugin-rdesktop" "ufw" "xf86-input-libinput" "tlp" "tlpui-git" "lightdm" 
    "lightdm-gtk-greeter" "lightdm-gtk-greeter-settings" "light-locker" "i3-gaps" 
    "i3lock" "rofi" "mlocate" "dunst" "polybar" "nitrogen" "tty-clock" "lxappearance"
    "ranger" "gtk-engine-murrine" "lib32-gtk-engine-murrine" "hardcode-tray-git" 
    "ttf-font-awesome" "ttf-ms-win10" "visual-studio-code-bin")
    
function configurar_idioma(){
    echo -e "KEYMAP=br-abnt2\nFONT=\nFONT_MAP=" > /etc/vconsole.conf
    sed -i '/pt_BR/,+1 s/^#//' /etc/locale.gen
    locale-gen
    echo LANG=pt_BR.UTF-8 > /etc/locale.conf
    export LANG=pt_BR.UTF-8
}

function configurar_usuario(){
    useradd -m -g users -G wheel -c "${MY_USER_NAME}" -s /bin/bash $MY_USER
    echo ${MY_USER}:${MY_USER} | chpasswd
    sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers
    hostnamectl set-hostname ${HOST}
}

function instalar_aur_helper(){
    pacman -S git --needed --noconfirm
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    rm -rf yay
}

function instalar_pacote(){
    for i in "${PACOTES[@]}"; do
        su ${MY_USER} -c "yay -S ${i} --needed --noconfirm"
    done 
}

# configurar_usuario
configurar_idioma
instalar_aur_helper
instalar_pacote
